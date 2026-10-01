import 'dart:io';

import 'package:tavli_testkit/tavli_testkit.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('import_lint_'));
  tearDown(() => tmp.deleteSync(recursive: true));

  void write(String rel, String content) {
    File('${tmp.path}/$rel')
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  test('reports forbidden imports and exports with file and line', () {
    write('lib/a.dart',
        "import 'dart:math';\nimport 'package:flutter/material.dart';\n");
    write('lib/src/b.dart', "export 'package:flutter/foundation.dart';\n");

    final violations = findForbiddenImports(
      Directory('${tmp.path}/lib'),
      [RegExp(r'^package:flutter/')],
    );

    expect(violations, hasLength(2));
    final a = violations.singleWhere((v) => v.file.endsWith('a.dart'));
    expect(a.line, 2);
    expect(a.uri, 'package:flutter/material.dart');
    expect(violations.any((v) => v.file.endsWith('b.dart')), isTrue);
  });

  test('handles double quotes and ignores non-dart files and comments', () {
    write('lib/a.dart',
        '// import \'package:flutter/x.dart\';\nimport "dart:ui";\n');
    write('lib/readme.md', "import 'package:flutter/material.dart';\n");

    final violations = findForbiddenImports(
      Directory('${tmp.path}/lib'),
      [RegExp(r'^package:flutter/'), 'dart:ui'],
    );

    expect(violations, hasLength(1));
    expect(violations.single.uri, 'dart:ui');
  });

  test('missing directory yields no violations', () {
    expect(
      findForbiddenImports(Directory('${tmp.path}/nope'), ['dart:ui']),
      isEmpty,
    );
  });

  test('toString is human readable for test failure messages', () {
    const v = ImportViolation(file: 'lib/a.dart', line: 3, uri: 'dart:ui');
    expect(v.toString(), 'lib/a.dart:3 imports dart:ui');
  });
}
