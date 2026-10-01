import 'dart:io';

/// One forbidden `import`/`export` directive found in a Dart source file.
class ImportViolation {
  final String file;
  final int line;
  final String uri;

  const ImportViolation({
    required this.file,
    required this.line,
    required this.uri,
  });

  @override
  String toString() => '$file:$line imports $uri';
}

final _directive = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''');

/// Scans every `.dart` file under [root] for import/export URIs matching any
/// of [forbidden] (a `String` matches exactly or as a prefix; a `RegExp`
/// matches via `hasMatch`). Commented-out lines are ignored.
List<ImportViolation> findForbiddenImports(
  Directory root,
  List<Pattern> forbidden,
) {
  if (!root.existsSync()) return const [];
  final violations = <ImportViolation>[];
  final files = root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));
  for (final file in files) {
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final match = _directive.firstMatch(lines[i]);
      if (match == null) continue;
      final uri = match.group(1)!;
      if (forbidden.any((p) => _matches(p, uri))) {
        violations.add(ImportViolation(file: file.path, line: i + 1, uri: uri));
      }
    }
  }
  return violations;
}

bool _matches(Pattern pattern, String uri) => switch (pattern) {
      final RegExp r => r.hasMatch(uri),
      final String s => uri == s || uri.startsWith(s),
      _ => pattern.allMatches(uri).isNotEmpty,
    };
