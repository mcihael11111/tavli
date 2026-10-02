import 'dart:math';

import 'package:tavli_bot/src/eval/features.dart';
import 'package:tavli_bot/src/eval/race_eval.dart';
import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/positions.dart';

const _race = RaceEvaluator();
final _portes = Variant.portes.rules;

void main() {
  test('race: a mirrored position swaps the sides (±0.02)', () {
    final races = [
      posOpp({6: 10, 4: 5}, {7: 10, 6: 5}),
      posOpp({7: 10, 6: 5}, {8: 15}),
      posOpp({1: 1}, {6: 15}),
      posOpp({6: 4, 3: 3, 2: 4, 1: 4}, {6: 1, 5: 1, 4: 4, 3: 3, 2: 3, 1: 3}),
      posOpp({12: 3, 6: 12}, {10: 2, 5: 13}),
    ];
    for (final p in races) {
      expect(isRace(p, _portes), isTrue, reason: '$p');
      final w = _race.evaluate(p, Side.one, _portes).winProb;
      final w2 = _race.evaluate(mirror(p), Side.one, _portes).winProb;
      expect(w, closeTo(1 - w2, 0.02), reason: '$p');
    }
  });

  test('race: exactly antisymmetric on random positions of every variant', () {
    final rng = Random(3);
    for (final v in Variant.values) {
      for (final p in randomPositions(v, 30, rng)) {
        expectAntisymmetric(_race, p, v.rules, reason: '$v');
      }
    }
  });
}
