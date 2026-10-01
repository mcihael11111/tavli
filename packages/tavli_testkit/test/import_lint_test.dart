import 'dart:convert';
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
    expect(violations.single.reason, 'escapes lib/');
    expect(violations.single.toString(), endsWith(' [escapes lib/]'));
  });

  test('package URIs with dot segments or duplicate slashes are normalized',
      () {
    write(
      'lib/gameplay/x.dart',
      "import 'package:tavli/gameplay/../flame_game/a.dart';\n"
          "import 'package:tavli//flame_game/b.dart';\n",
    );
    final violations = findForbiddenImports(
      dir('lib/gameplay'),
      ['package:tavli/flame_game/'],
    );
    expect(violations, hasLength(2));
    expect(violations.map((v) => v.resolved), [
      'package:tavli/flame_game/a.dart',
      'package:tavli/flame_game/b.dart',
    ]);
    expect(violations.every((v) => v.reason == null), isTrue);
  });

  test('libRoot with a trailing slash behaves like one without', () {
    write('lib/flame_game/a.dart', '');
    write('lib/gameplay/x.dart', "import '../flame_game/a.dart';\n");
    final violations = findForbiddenImports(
      dir('lib/gameplay/'),
      ['package:tavli/flame_game/'],
      packageName: 'tavli',
      libRoot: dir('lib/'),
    );
    expect(violations.single.resolved, 'package:tavli/flame_game/a.dart');
  });

  test('relative imports with duplicate slashes and lib// are normalized', () {
    write('lib/flame_game/a.dart', '');
    write('lib/gameplay/x.dart', "import '..//flame_game/a.dart';\n");
    final violations = findForbiddenImports(
      dir('lib/gameplay'),
      ['package:tavli/flame_game/'],
      packageName: 'tavli',
      libRoot: Directory('${tmp.path}/lib//'),
    );
    expect(violations.single.resolved, 'package:tavli/flame_game/a.dart');
  });

  test('packageLibDir resolves a workspace package lib directory', () {
    final lib = packageLibDir('tavli_testkit');
    expect(File('${lib.path}/src/bench.dart').existsSync(), isTrue);
    expect(() => packageLibDir('no_such_package_xyz'), throwsStateError);
  });

  test('allowlist-style patterns do not flag normalized relative imports', () {
    write('lib/src/x.dart', '');
    write('lib/a.dart', "export 'src/x.dart';\n");
    final violations = findForbiddenImports(
      dir('lib'),
      [RegExp(r'^(?!package:tavli/)')],
      packageName: 'tavli',
      libRoot: dir('lib'),
    );
    expect(violations, isEmpty);
  });

  group('packageLibDirFromConfig', () {
    void config(List<Map<String, String>> packages) {
      write(
        '.dart_tool/package_config.json',
        jsonEncode({'configVersion': 2, 'packages': packages}),
      );
    }

    test('resolves root and slash-less workspace member roots', () {
      write('lib/a.dart', '');
      write('packages/foo/lib/b.dart', '');
      config([
        {'name': 'root', 'rootUri': '../', 'packageUri': 'lib/'},
        {'name': 'foo', 'rootUri': '../packages/foo', 'packageUri': 'lib/'},
      ]);
      final start = dir('packages/foo/lib');
      final root = packageLibDirFromConfig('root', start);
      final foo = packageLibDirFromConfig('foo', start);
      expect(File('${root.path}/a.dart').existsSync(), isTrue);
      expect(File('${foo.path}/b.dart').existsSync(), isTrue);
    });

    test('unknown package or missing directory throws StateError', () {
      write('lib/a.dart', '');
      config([
        {'name': 'root', 'rootUri': '../', 'packageUri': 'lib/'},
        {'name': 'ghost', 'rootUri': '../packages/ghost', 'packageUri': 'lib/'},
      ]);
      expect(
          () => packageLibDirFromConfig('nope', dir('lib')), throwsStateError);
      expect(
          () => packageLibDirFromConfig('ghost', dir('lib')), throwsStateError);
    });
  });

  group('packageLibDirFromStarts', () {
    test('final error includes the underlying reasons', () {
      write('lib/a.dart', '');
      write(
        '.dart_tool/package_config.json',
        jsonEncode({
          'configVersion': 2,
          'packages': [
            {
              'name': 'ghost',
              'rootUri': '../packages/ghost',
              'packageUri': 'lib/'
            },
          ],
        }),
      );
      expect(
        () => packageLibDirFromStarts('ghost', [dir('lib')]),
        throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('Cannot resolve package:ghost/'),
                contains('missing')))),
      );
      expect(
        () => packageLibDirFromStarts('nope', [dir('lib'), dir('.')]),
        throwsA(isA<StateError>()
            .having((e) => e.message, 'message', contains('is not in'))),
      );
    });
  });

  group('findForbiddenReachable', () {
    final forbidden = ['package:tavli/legacy/'];

    List<ImportChainViolation> run({
      List<Pattern> boundary = const [],
      String entry = 'gameplay',
    }) =>
        findForbiddenReachable(
          dir('lib/$entry'),
          forbidden,
          packageName: 'tavli',
          libRoot: dir('lib'),
          boundary: boundary,
        );

    test('direct hit', () {
      write('lib/gameplay/x.dart', "import 'package:tavli/legacy/a.dart';\n");
      final v = run();
      expect(v, hasLength(1));
      expect(v.single.chain,
          ['package:tavli/gameplay/x.dart', 'package:tavli/legacy/a.dart']);
    });

    test('2-hop hit via an unlisted file', () {
      write('lib/gameplay/x.dart', "import '../shared/h.dart';\n");
      write('lib/shared/h.dart', "import 'package:tavli/legacy/a.dart';\n");
      final v = run();
      expect(v.single.chain, [
        'package:tavli/gameplay/x.dart',
        'package:tavli/shared/h.dart',
        'package:tavli/legacy/a.dart',
      ]);
      expect(v.single.toString(), contains(' -> '));
    });

    test('boundary file is permitted and not traversed', () {
      write('lib/gameplay/x.dart', "import '../shared/ok.dart';\n");
      write('lib/shared/ok.dart', "import 'package:tavli/legacy/a.dart';\n");
      expect(run(boundary: ['package:tavli/shared/ok.dart']), isEmpty);
    });

    test('boundary wins over forbidden for the same file', () {
      write('lib/gameplay/x.dart', "import 'package:tavli/legacy/ok.dart';\n");
      expect(run(boundary: ['package:tavli/legacy/ok.dart']), isEmpty);
    });

    test('cycles terminate', () {
      write('lib/gameplay/x.dart', "import '../shared/a.dart';\n");
      write('lib/shared/a.dart', "import 'b.dart';\n");
      write('lib/shared/b.dart',
          "import 'a.dart';\nimport 'package:tavli/legacy/z.dart';\n");
      final v = run();
      expect(v, hasLength(1));
      expect(v.single.chain.length, 4);
    });

    test('conditional alternatives are followed', () {
      write(
        'lib/gameplay/x.dart',
        "import 'stub.dart' if (dart.library.io) '../shared/h.dart';\n",
      );
      write('lib/gameplay/stub.dart', '');
      write('lib/shared/h.dart', "import 'package:tavli/legacy/a.dart';\n");
      expect(run(), hasLength(1));
    });

    test('shortest chain is reported per target', () {
      write('lib/gameplay/x.dart',
          "import '../shared/a.dart';\nimport 'package:tavli/legacy/t.dart';\n");
      write('lib/shared/a.dart', "import 'package:tavli/legacy/t.dart';\n");
      final v = run();
      expect(v, hasLength(1));
      expect(v.single.chain, hasLength(2));
    });

    test('relative imports escaping libRoot are reported with a reason', () {
      write('lib/gameplay/x.dart', "import '../../tool/h.dart';\n");
      final v = run();
      expect(v.single.chain,
          ['package:tavli/gameplay/x.dart', '../../tool/h.dart']);
      expect(v.single.reason, 'escapes lib/');
      expect(v.single.toString(), endsWith(' [escapes lib/]'));
    });

    test('other packages and dart: URIs are not traversed', () {
      write('lib/gameplay/x.dart',
          "import 'dart:math';\nimport 'package:other/o.dart';\n");
      expect(run(), isEmpty);
    });

    test('missing root throws unless allowMissing', () {
      expect(() => run(entry: 'nope'), throwsArgumentError);
      expect(
        findForbiddenReachable(
          dir('lib/nope'),
          forbidden,
          packageName: 'tavli',
          libRoot: dir('lib'),
          allowMissing: true,
        ),
        isEmpty,
      );
    });
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
