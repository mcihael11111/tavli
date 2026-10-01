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
  'package:tavli/features/game/presentation/',
  'package:tavli/features/multiplayer/',
  'package:tavli/features/replay/',
  'package:tavli/features/spectate/',
  'package:tavli/features/dualboard/',
  'package:tavli/core/constants/variants/',
];

/// Permitted and not traversed: shared vocabulary for non-gameplay features;
/// SP1 adds canonical tavli_core types + adapters; SP5 removes these carve-outs.
const _boundary = <Pattern>[
  'package:tavli/features/game/domain/engine/variants/game_variant.dart',
  'package:tavli/features/game/data/models/game_result.dart',
  'package:tavli/core/constants/tradition.dart',
  'package:tavli/features/game/presentation/widgets/turn_handoff_pill.dart',
];

List<ImportChainViolation> _scan(Directory gameplay, Directory lib) =>
    findForbiddenReachable(
      gameplay,
      _legacy,
      packageName: 'tavli',
      libRoot: lib,
      boundary: _boundary,
      // SP3: set allowMissing: false once lib/gameplay exists.
      allowMissing: true,
    );

void main() {
  test('packageLibDir resolves the real app lib (not a wrong tree)', () {
    expect(
        File('${packageLibDir('tavli').path}/main.dart').existsSync(), isTrue);
  });

  test('lib/gameplay does not (transitively) import legacy gameplay code', () {
    final lib = packageLibDir('tavli');
    final violations = _scan(Directory('${lib.path}/gameplay'), lib);
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  group('positive controls (guard against a vacuous pass)', () {
    late Directory lib;

    setUp(() {
      final tmp = Directory.systemTemp.createTempSync('boundary_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      lib = Directory('${tmp.path}/lib')..createSync();
    });

    void write(String rel, String content) => File('${lib.path}/$rel')
      ..createSync(recursive: true)
      ..writeAsStringSync(content);

    List<ImportChainViolation> scan() =>
        _scan(Directory('${lib.path}/gameplay'), lib);

    test('package: import of legacy code is caught', () {
      write('gameplay/x.dart',
          "import 'package:tavli/flame_game/tavli_game.dart';\n");
      expect(scan(), hasLength(1));
    });

    test('relative import of legacy code is caught', () {
      write('gameplay/x.dart', "import '../flame_game/tavli_game.dart';\n");
      expect(scan(), hasLength(1));
    });

    test('conditional import of legacy code is caught', () {
      write(
          'gameplay/x.dart',
          "import 'stub.dart' if (dart.library.io) "
              "'package:tavli/features/ai/engine/ai_player.dart';\n");
      expect(scan(), hasLength(1));
    });

    test('2-hop import via a shared helper is caught', () {
      write('gameplay/x.dart', "import '../shared/helper.dart';\n");
      write('shared/helper.dart', "import '../flame_game/tavli_game.dart';\n");
      final v = scan();
      expect(v, hasLength(1));
      expect(v.single.chain, hasLength(3));
    });

    test('carve-out is permitted and not traversed', () {
      write(
          'gameplay/x.dart',
          "import 'package:tavli/features/game/domain/engine/variants/"
              "game_variant.dart';\n");
      write('features/game/domain/engine/variants/game_variant.dart',
          "import 'variant_rules.dart';\n");
      write('features/game/domain/engine/variants/variant_rules.dart', '');
      expect(scan(), isEmpty);
    });
  });
}
