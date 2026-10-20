import 'package:tavli_core/src/play/play_generator.dart'
    show generateCascadeUnpruned;
import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../../benchmark/bench_fixtures.dart';
import '../support/cascades.dart';
import '../support/positions.dart';

final _gul = Variant.gulBara.rules;

/// Pruned and unpruned trees agree on everything a caller sees.
void _same(Position p, Side s, List<int> q, {bool enumerate = true}) {
  final a = generateCascade(p, s, q, _gul, TurnContext());
  final b = generateCascadeUnpruned(p, s, q, _gul, TurnContext());
  expect(a.diceUsed, b.diceUsed);
  expect(a.remainder, b.remainder);
  expect(a.root.nextSteps.toList(), b.root.nextSteps.toList());
  if (enumerate) expect(a.enumerateFinals(), b.enumerateFinals());
}

void main() {
  group('cascade pruning bound (SP3 §5.4 (a))', () {
    test('worst failing cascade: same result, a fraction of the states', () {
      const f = worstFailingCascade;
      final p = f.position;
      final a = generateCascade(p, f.side, f.dice, _gul, TurnContext());
      final b = generateCascadeUnpruned(p, f.side, f.dice, _gul, TurnContext());
      expect(a.diceUsed, f.finals);
      expect(b.diceUsed, f.finals);
      expect(a.remainder, b.remainder);
      expect(a.searchedStates * 20, lessThan(b.searchedStates));
      expect(a.enumerateFinals(), b.enumerateFinals());
    });

    test('worst succeeding cascade: same first steps, fewer states', () {
      const f = worstCascade;
      final a =
          generateCascade(f.position, f.side, f.dice, _gul, TurnContext());
      final b = generateCascadeUnpruned(
          f.position, f.side, f.dice, _gul, TurnContext());
      expect(a.diceUsed, b.diceUsed);
      expect(a.root.nextSteps.toList(), b.root.nextSteps.toList());
      expect(a.searchedStates, lessThan(b.searchedStates));
    });

    smallCascades.forEach((name, c) {
      test('small case agrees: $name', () {
        final (p, q) = c;
        _same(p, Side.one, q);
      });
    });

    test('bear-off endings and trapped checkers agree', () {
      // All home: lines end the game early (A4).
      _same(posSame(one: {6: 3, 5: 2, 1: 1}, two: {24: 15}), Side.one,
          cascadeQueue(1));
      // Checkers behind a full prime (my 12..17) never get home.
      _same(
          posSame(
            one: {24: 6, 10: 2, 5: 2, 1: 5},
            two: {24: 3, 1: 2, 2: 2, 3: 2, 4: 2, 5: 2, 20: 1, 21: 1},
          ),
          Side.one,
          cascadeQueue(1));
    });

    test('a non-decreasing queue is required; others are searched plainly', () {
      // Not a real queue shape, but generateCascade accepts it.
      _same(posSame(one: {24: 2, 18: 1, 1: 12}, two: {24: 15}), Side.one,
          const [6, 5, 5, 4]);
    });
  });
}
