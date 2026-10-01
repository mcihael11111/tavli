import 'dart:io';

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
  final files = root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));
  for (final file in files) {
    final unit = parseString(
      content: file.readAsStringSync(),
      throwIfDiagnostics: false,
    ).unit;
    for (final d in unit.directives.whereType<NamespaceDirective>()) {
      final uris = <StringLiteral>[
        d.uri,
        for (final c in d.configurations) c.uri
      ];
      for (final node in uris) {
        final uri = node.stringValue;
        if (uri == null) continue;
        final resolved = _resolve(uri, file, packageName, libPath);
        final escapes = resolved == null;
        final candidate = resolved ?? uri;
        if (escapes ||
            forbidden.any((p) => _matches(p, candidate) || _matches(p, uri))) {
          violations.add(ImportViolation(
            file: file.path,
            line: unit.lineInfo.getLocation(node.offset).lineNumber,
            uri: uri,
            resolved: candidate,
            reason: escapes ? 'escapes lib/' : null,
          ));
        }
      }
    }
  }
  return violations;
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
  final normalized = Uri.file(path).normalizePath().toFilePath();
  return normalized.length > 1 && normalized.endsWith(Platform.pathSeparator)
      ? normalized.substring(0, normalized.length - 1)
      : normalized;
}

bool _matches(Pattern pattern, String uri) => switch (pattern) {
      final RegExp r => r.hasMatch(uri),
      final String s => uri.startsWith(s),
      _ => pattern.allMatches(uri).isNotEmpty,
    };
