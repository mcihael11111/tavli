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

  Directory dir(String rel) => Directory('${tmp.path}/$rel');
  final flutter = RegExp(r'^package:flutter/');

  test('reports forbidden imports and exports with file and line', () {
    write(
      'lib/a.dart',
      "import 'dart:math';\nimport 'package:flutter/material.dart';\n",
    );
    write('lib/src/b.dart', "export 'package:flutter/foundation.dart';\n");

    final violations = findForbiddenImports(dir('lib'), [flutter]);

    expect(violations, hasLength(2));
    final a = violations.singleWhere((v) => v.file.endsWith('a.dart'));
    expect(a.line, 2);
    expect(a.uri, 'package:flutter/material.dart');
    expect(a.resolved, a.uri);
    expect(violations.any((v) => v.file.endsWith('b.dart')), isTrue);
  });

  test('catches a forbidden conditional-import alternative', () {
    write(
      'lib/a.dart',
      "import 'stub.dart' if (dart.library.io) 'package:flutter/material.dart';\n",
    );
    final violations = findForbiddenImports(dir('lib'), [flutter]);
    expect(violations.single.uri, 'package:flutter/material.dart');
    expect(violations.single.line, 1);
  });

  test('catches a conditional on its own line', () {
    write(
      'lib/a.dart',
      "import 'stub.dart'\n"
          "    if (dart.library.io) 'package:flutter/material.dart'\n"
          "    if (dart.library.html) 'dart:ui';\n",
    );
    final violations = findForbiddenImports(dir('lib'), [flutter, 'dart:ui']);
    expect(violations.map((v) => v.uri),
        ['package:flutter/material.dart', 'dart:ui']);
    expect(violations.map((v) => v.line), [2, 3]);
  });

  test('handles raw strings, double quotes and two imports on one line', () {
    write('lib/a.dart', "import r'dart:ui'; import \"dart:io\";\n");
    final violations = findForbiddenImports(dir('lib'), ['dart:ui', 'dart:io']);
    expect(violations.map((v) => v.uri), ['dart:ui', 'dart:io']);
  });

  test('ignores comments and non-dart files', () {
    write(
        'lib/a.dart',
        "// import 'package:flutter/x.dart';\n"
            "/* import 'package:flutter/y.dart'; */\n"
            "const s = \"import 'package:flutter/z.dart';\";\n");
    write('lib/readme.md', "import 'package:flutter/material.dart';\n");
    expect(findForbiddenImports(dir('lib'), [flutter]), isEmpty);
  });

  test('relative imports are normalized to package: URIs', () {
    write('lib/flame_game/a.dart', '');
    write('lib/gameplay/x.dart', "import '../flame_game/a.dart';\n");
    final violations = findForbiddenImports(
      dir('lib/gameplay'),
      ['package:tavli/flame_game/'],
      packageName: 'tavli',
      libRoot: dir('lib'),
    );
    expect(violations, hasLength(1));
    expect(violations.single.uri, '../flame_game/a.dart');
    expect(violations.single.resolved, 'package:tavli/flame_game/a.dart');
    expect(violations.single.toString(), contains('(package:tavli/'));
  });

  test('relative imports staying inside allowed areas are fine', () {
    write('lib/gameplay/y.dart', '');
    write('lib/gameplay/x.dart', "import 'y.dart';\n");
    expect(
      findForbiddenImports(
        dir('lib/gameplay'),
        ['package:tavli/flame_game/'],
        packageName: 'tavli',
        libRoot: dir('lib'),
      ),
      isEmpty,
    );
  });

  test('relative import escaping lib is always a violation', () {
    write('lib/x.dart', "import '../tool/helper.dart';\n");
    final violations = findForbiddenImports(
      dir('lib'),
      const [],
      packageName: 'tavli',
      libRoot: dir('lib'),
    );
    expect(violations, hasLength(1));
    expect(violations.single.uri, '../tool/helper.dart');
  });

  test('missing directory throws by default, empty with allowMissing', () {
    expect(
      () => findForbiddenImports(dir('nope'), ['dart:ui']),
      throwsA(isA<ArgumentError>()
          .having((e) => e.toString(), 'message', contains('does not exist'))),
    );
    expect(
      findForbiddenImports(dir('nope'), ['dart:ui'], allowMissing: true),
      isEmpty,
    );
  });

  test('toString is human readable for test failure messages', () {
    const v = ImportViolation(
        file: 'lib/a.dart', line: 3, uri: 'dart:ui', resolved: 'dart:ui');
    expect(v.toString(), 'lib/a.dart:3 references dart:ui');
    const r = ImportViolation(
        file: 'lib/a.dart',
        line: 3,
        uri: '../b.dart',
        resolved: 'package:tavli/b.dart');
    expect(r.toString(),
        'lib/a.dart:3 references ../b.dart (package:tavli/b.dart)');
  });
}
