import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// One forbidden `import`/`export` directive found in a Dart source file.
class ImportViolation {
  final String file;
  final int line;

  /// The URI exactly as written in the source.
  final String uri;

  /// The normalized URI that matched (equals [uri] when not normalized).
  final String resolved;

  /// Why this was reported when it is not an ordinary pattern match
  /// (e.g. `'escapes lib/'`); null otherwise.
  final String? reason;

  const ImportViolation({
    required this.file,
    required this.line,
    required this.uri,
    required this.resolved,
    this.reason,
  });

  @override
  String toString() => '$file:$line references $uri'
      '${resolved != uri ? ' ($resolved)' : ''}'
      '${reason != null ? ' [$reason]' : ''}';
}

/// Scans every `.dart` file under [root] for import/export URIs (including
/// conditional-import alternatives) matching any of [forbidden] (a `String`
/// matches as a prefix; a `RegExp` matches via `hasMatch`).
///
/// Relative URIs are resolved against the importing file. When [packageName]
/// and [libRoot] are given, a relative URI inside [libRoot] is normalized to
/// `package:<packageName>/<path>` before matching; one that resolves outside
/// [libRoot] is always reported.
///
/// A missing [root] throws [ArgumentError] unless [allowMissing] is true.
List<ImportViolation> findForbiddenImports(
  Directory root,
  List<Pattern> forbidden, {
  String? packageName,
  Directory? libRoot,
  bool allowMissing = false,
}) {
  if ((packageName == null) != (libRoot == null)) {
    throw ArgumentError('packageName and libRoot must be given together');
  }
  if (!root.existsSync()) {
    if (allowMissing) return const [];
    throw ArgumentError.value(root.path, 'root', 'does not exist');
  }
  final libPath = libRoot == null ? null : _normalize(libRoot.absolute.path);
  final violations = <ImportViolation>[];
  for (final file in _dartFiles(root)) {
    for (final r in _directiveUris(file, packageName, libPath)) {
      final escapes = r.resolved == null;
      final candidate = r.resolved ?? r.uri;
      if (escapes ||
          forbidden.any((p) =>
              _matches(p, candidate) ||
              (candidate == r.uri && _matches(p, r.uri)))) {
        violations.add(ImportViolation(
          file: file.path,
          line: r.line,
          uri: r.uri,
          resolved: candidate,
          reason: escapes ? 'escapes lib/' : null,
        ));
      }
    }
  }
  return violations;
}

/// A chain of package URIs from an entry file to a forbidden file.
class ImportChainViolation {
  /// Package URIs from the entry file to the forbidden file.
  final List<String> chain;

  /// Why this was reported when it is not an ordinary pattern match
  /// (e.g. `'escapes lib/'`); null otherwise.
  final String? reason;

  const ImportChainViolation(this.chain, {this.reason});

  @override
  String toString() =>
      chain.join(' -> ') + (reason != null ? ' [$reason]' : '');
}

/// Follows `package:<packageName>/` imports (incl. normalized relative ones and
/// conditional alternatives) from every .dart file under [root], within
/// [libRoot], and reports every reachable file whose package URI matches
/// [forbidden]. Files matching [boundary] are permitted and NOT traversed
/// into (carve-outs). Other packages' URIs (`dart:`, `package:other/`) are
/// matched against [forbidden] but never traversed. Reports the shortest
/// chain per forbidden target.
List<ImportChainViolation> findForbiddenReachable(
  Directory root,
  List<Pattern> forbidden, {
  required String packageName,
  required Directory libRoot,
  List<Pattern> boundary = const [],
  bool allowMissing = false,
}) {
  if (!root.existsSync()) {
    if (allowMissing) return const [];
    throw ArgumentError.value(root.path, 'root', 'does not exist');
  }
  final libPath = _normalize(libRoot.absolute.path);
  final prefix = 'package:$packageName/';
  String? uriOf(File f) {
    final path = _normalize(f.absolute.path);
    return path.startsWith('$libPath/')
        ? '$prefix${path.substring(libPath.length + 1)}'
        : null;
  }

  final parents = <String, String?>{};
  final queue = Queue<String>();
  for (final f in _dartFiles(root)) {
    final u = uriOf(f);
    if (u != null && !parents.containsKey(u)) {
      parents[u] = null;
      queue.add(u);
    }
  }
  final reported = <String>{};
  final violations = <ImportChainViolation>[];
  List<String> chainTo(String u) {
    final chain = <String>[];
    for (String? c = u; c != null; c = parents[c]) {
      chain.add(c);
    }
    return chain.reversed.toList();
  }

  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    final file = File('$libPath/${current.substring(prefix.length)}');
    if (!file.existsSync()) continue;
    for (final r in _directiveUris(file, packageName, libPath)) {
      final target = r.resolved;
      if (target == null) {
        if (reported.add('escape:$current->${r.uri}')) {
          violations.add(ImportChainViolation(
            [...chainTo(current), r.uri],
            reason: 'escapes lib/',
          ));
        }
        continue;
      }
      if (boundary.any((p) => _matches(p, target))) continue;
      if (forbidden.any((p) =>
          _matches(p, target) || (target == r.uri && _matches(p, r.uri)))) {
        if (reported.add(target)) {
          violations.add(ImportChainViolation([...chainTo(current), target]));
        }
        continue;
      }
      if (target.startsWith(prefix) && !parents.containsKey(target)) {
        parents[target] = current;
        queue.add(target);
      }
    }
  }
  return violations;
}

/// Resolves the lib directory of [packageName] via the current package config.
///
/// Independent of the working directory under `dart test`. Under
/// `flutter test`, where `Isolate.resolvePackageUriSync` is unsupported, falls
/// back to the nearest `.dart_tool/package_config.json` found walking up from
/// the running script, then from the current directory. Throws [StateError]
/// when the package cannot be resolved.
Directory packageLibDir(String packageName) {
  Uri? uri;
  try {
    uri = Isolate.resolvePackageUriSync(Uri.parse('package:$packageName/'));
  } on UnsupportedError {
    uri = _resolveFromPackageConfig(packageName);
  }
  if (uri == null) {
    throw StateError('Cannot resolve package:$packageName/');
  }
  return Directory.fromUri(uri);
}

Uri _resolveFromPackageConfig(String packageName) => packageLibDirFromStarts(
      packageName,
      [
        if (Platform.script.scheme == 'file')
          File.fromUri(Platform.script).parent,
        Directory.current,
      ],
    ).uri;

/// Tries [packageLibDirFromConfig] from each of [starts] in order and returns
/// the first success. When all fail, throws a [StateError] that includes every
/// underlying failure reason.
///
/// Public only so tests can exercise the aggregation of the `flutter test`
/// fallback of [packageLibDir].
Directory packageLibDirFromStarts(
  String packageName,
  Iterable<Directory> starts,
) {
  final reasons = <String>[];
  for (final start in starts) {
    try {
      return packageLibDirFromConfig(packageName, start);
    } on StateError catch (e) {
      if (!reasons.contains(e.message)) reasons.add(e.message);
    }
  }
  throw StateError(
    reasons.isEmpty
        ? 'Cannot resolve package:$packageName/'
        : 'Cannot resolve package:$packageName/ (${reasons.join('; ')})',
  );
}

/// Resolves [packageName]'s lib directory from the nearest
/// `.dart_tool/package_config.json` found walking up from [startDir].
///
/// Public only so tests can exercise the `flutter test` fallback of
/// [packageLibDir]. Throws [StateError] when no config is found, the package
/// is not listed, or the resolved directory does not exist.
Directory packageLibDirFromConfig(String packageName, Directory startDir) {
  for (var dir = startDir.absolute;; dir = dir.parent) {
    final config = File('${dir.path}/.dart_tool/package_config.json');
    if (config.existsSync()) {
      final json =
          jsonDecode(config.readAsStringSync()) as Map<String, Object?>;
      for (final entry in (json['packages']! as List<Object?>)
          .cast<Map<String, Object?>>()) {
        if (entry['name'] != packageName) continue;
        var rootUri = entry['rootUri']! as String;
        if (!rootUri.endsWith('/')) rootUri = '$rootUri/';
        var packageUri = (entry['packageUri'] as String?) ?? 'lib/';
        if (!packageUri.endsWith('/')) packageUri = '$packageUri/';
        final lib = Directory.fromUri(
          config.uri.resolve(rootUri).resolve(packageUri),
        );
        if (!lib.existsSync()) {
          throw StateError(
              'package:$packageName/ resolves to missing ${lib.path}');
        }
        return lib;
      }
      throw StateError('package:$packageName is not in ${config.path}');
    }
    if (dir.parent.path == dir.path) break;
  }
  throw StateError('No .dart_tool/package_config.json above ${startDir.path}');
}

Iterable<File> _dartFiles(Directory root) => root
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

class _DirectiveUri {
  final String uri;
  final int line;

  /// Normalized URI; null when a relative URI escapes the lib directory.
  final String? resolved;
  const _DirectiveUri(this.uri, this.line, this.resolved);
}

/// Every import/export URI in [file] (including conditional alternatives),
/// normalized.
List<_DirectiveUri> _directiveUris(
    File file, String? packageName, String? libPath) {
  final unit = parseString(
    content: file.readAsStringSync(),
    throwIfDiagnostics: false,
  ).unit;
  final result = <_DirectiveUri>[];
  for (final d in unit.directives.whereType<NamespaceDirective>()) {
    final nodes = <StringLiteral>[
      d.uri,
      for (final c in d.configurations) c.uri
    ];
    for (final node in nodes) {
      final uri = node.stringValue;
      if (uri == null) continue;
      result.add(_DirectiveUri(
        uri,
        unit.lineInfo.getLocation(node.offset).lineNumber,
        _resolve(uri, file, packageName, libPath),
      ));
    }
  }
  return result;
}

/// Returns the normalized URI, the raw [uri] when no normalization applies,
/// or null when a relative URI escapes the package's lib directory.
String? _resolve(String uri, File file, String? packageName, String? libPath) {
  final parsed = Uri.tryParse(uri);
  if (parsed != null && parsed.hasScheme) return _normalizeSchemeUri(parsed);
  if (packageName == null || libPath == null) return uri;
  final target = _normalize(
    file.absolute.parent.uri.resolve(uri).toFilePath(),
  );
  if (target.startsWith('$libPath/')) {
    return 'package:$packageName/${target.substring(libPath.length + 1)}';
  }
  return null;
}

/// Resolves `..`/`.` segments and collapses duplicate slashes so spellings
/// like `package:a/b/../c.dart` and `package:a//c.dart` match `package:a/c.dart`.
String _normalizeSchemeUri(Uri parsed) {
  final path = parsed.path.replaceAll(RegExp('/{2,}'), '/');
  return parsed.replace(path: path).normalizePath().toString();
}

String _normalize(String path) {
  final normalized = Uri.file(path)
      .normalizePath()
      .toFilePath()
      .replaceAll(RegExp('/{2,}'), '/');
  return normalized.length > 1 && normalized.endsWith(Platform.pathSeparator)
      ? normalized.substring(0, normalized.length - 1)
      : normalized;
}

bool _matches(Pattern pattern, String uri) => switch (pattern) {
      final RegExp r => r.hasMatch(uri),
      final String s => uri.startsWith(s),
      _ => pattern.allMatches(uri).isNotEmpty,
    };
