import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/features/game/domain/engine/game_engine.dart';
import 'package:tavli/features/game/domain/engine/move_generator.dart';
import 'package:tavli_core/tavli_core.dart' hide DiceRoll;

import 'portes_legacy.dart';

/// Portes differential (SP1 plan Task 18): the legacy `MoveGenerator`'s
/// final boards must equal `tavli_core`'s legal finals, on positions from
/// a seeded legacy easy-vs-easy self-play x all 21 rolls (mapping:
/// [toCore], matrix §1).
///
/// A mismatch is settled by the matrix (G1-G9). A legacy bug goes into
/// [knownLegacyBugs] under its rule ID; a core bug is fixed in core.

/// Positions sampled from the self-play.
const _positions = 40;

/// Keep every [_every]th ply, so samples span openings, contact play,
/// bar entries and bear-offs, with both sides to move.
const _every = 3;

void main() {
  test(
      'Portes: legacy MoveGenerator finals == tavli_core finals '
      '($_positions self-play positions x 21 rolls)', () {
    const gen = MoveGenerator();
    const eng = GameEngine();
    final rules = Variant.portes.rules;
    final mismatches = <Mismatch>[];
    var compared = 0, finals = 0, bar = 0, bearOff = 0;
    final boards =
        legacySelfPlay(count: _positions, keep: (ply) => ply % _every == 0);
    for (final board in boards) {
      final p = toCore(board), side = sideToMove(board);
      if (p.onBar(side) > 0) bar++;
      if (p.allHome(side)) bearOff++;
      for (final roll in allRolls) {
        final legacy = {
          for (final t in gen.generateAllLegalTurns(board, roll))
            toCore(eng.applyMoves(board, t.moves)),
        };
        final core =
            generatePlays(p, side, coreDice(roll), rules, TurnContext()).finals;
        compared++;
        finals += core.length;
        final m = compareFinals(p, side, roll, legacy, core);
        if (m != null) mismatches.add(m);
      }
    }
    final open = unexplained(mismatches);
    // ignore: avoid_print
    print('Portes differential: $compared position x roll pairs, '
        '$finals core finals, $bar with a checker on the bar, $bearOff '
        'bearing off; ${mismatches.length} mismatches '
        '(${mismatches.length - open.length} known legacy bugs)');
    printOnFailure(open.take(5).join('\n\n'));
    expect(open, isEmpty, reason: '${open.length} unexplained mismatches');
    expect(compared, _positions * 21);
  });

  group('known legacy bugs', () {
    // A fake mismatch: the start position, 3-1, where "legacy" has one
    // final core lacks.
    final p = toCore(legacySelfPlay(count: 1, keep: (_) => true).single);
    final roll = allRolls.firstWhere((r) => r.die1 == 3 && r.die2 == 1);
    final core = generatePlays(
            p, Side.one, coreDice(roll), Variant.portes.rules, TurnContext())
        .finals;
    final bogus = Position.forRules(Variant.plakoto.rules);

    test('compareFinals reports a difference and keys it by case', () {
      expect(compareFinals(p, Side.one, roll, core, core), isNull);
      final m = compareFinals(p, Side.one, roll, {...core, bogus}, core)!;
      expect(m.onlyLegacy, {bogus});
      expect(m.onlyCore, isEmpty);
      expect(m.key, endsWith(' one 3-1'));
    });

    test('a case listed under a rule ID is suppressed, others are not', () {
      final m = compareFinals(p, Side.one, roll, {...core, bogus}, core)!;
      final bugs = {
        'G6': KnownLegacyBug('fake, for this test', {m.key}),
      };
      expect(knownBugRule(m, bugs), 'G6');
      expect(unexplained([m], bugs), isEmpty);
      expect(unexplained([m], const {}), [m]);
      expect(
          knownBugRule(m, const {
            'G6': KnownLegacyBug('other', {'x'})
          }),
          isNull);
    });
  });
}
