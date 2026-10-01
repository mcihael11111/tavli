import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tavli_testkit/tavli_testkit.dart';

/// Legacy gameplay code that the rewrite replaces. New code under
/// lib/gameplay/ must not import it, so each legacy mode can be deleted as
/// soon as its replacement ships (spec §6.1).
const _legacy = <Pattern>[
  'package:tavli/flame_game/',
  'package:tavli/features/game/domain/',
  'package:tavli/features/game/data/models/',
  'package:tavli/features/game/presentation/providers/',
  'package:tavli/features/ai/engine/',
  'package:tavli/features/ai/models/',
  'package:tavli/features/multiplayer/data/',
  'package:tavli/features/multiplayer/matchmaking/',
  'package:tavli/features/multiplayer/presentation/online_game_provider.dart',
];

List<ImportViolation> _scan(Directory gameplay, Directory lib) =>
    findForbiddenImports(
      gameplay,
      _legacy,
      packageName: 'tavli',
      libRoot: lib,
      // lib/gameplay is created in SP3; until then there is nothing to scan.
      allowMissing: true,
    );

void main() {
  test('lib/gameplay does not import legacy gameplay code', () {
    final violations = _scan(Directory('lib/gameplay'), Directory('lib'));
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  group('positive controls (guard against a vacuous pass)', () {
    late Directory lib;

    setUp(() {
      final tmp = Directory.systemTemp.createTempSync('boundary_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      lib = Directory('${tmp.path}/lib')..createSync();
    });

    void write(String content) => File('${lib.path}/gameplay/x.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync(content);

    test('package: import of legacy code is caught', () {
      write("import 'package:tavli/flame_game/tavli_game.dart';\n");
      expect(_scan(Directory('${lib.path}/gameplay'), lib), hasLength(1));
    });

    test('relative import of legacy code is caught', () {
      write("import '../flame_game/tavli_game.dart';\n");
      expect(_scan(Directory('${lib.path}/gameplay'), lib), hasLength(1));
    });

    test('conditional import of legacy code is caught', () {
      write("import 'stub.dart' if (dart.library.io) "
          "'package:tavli/features/ai/engine/ai_player.dart';\n");
      expect(_scan(Directory('${lib.path}/gameplay'), lib), hasLength(1));
    });
  });
}
