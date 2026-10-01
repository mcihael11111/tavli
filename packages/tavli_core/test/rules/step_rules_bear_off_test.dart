import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/positions.dart';
import '../support/steps.dart';

void main() {
  group('bear-off', () {
    test('G6 exact: die 3 bears off pip 3', () {
      final p = pos(one: {3: 1, 1: 1}, two: {6: 2});
      expect(stepsOf(hitRules, p, S.one, 3), {const Step(3, 0, 3)});
      final a = roundTrip(
        hitRules,
        p,
        S.one,
        const Step(3, 0, 3),
        after: pos(one: {1: 1}, two: {6: 2}),
      );
      expect(a.bearOff, isTrue);
      expect(a.hit || a.pinned || a.unpinned, isFalse);
    });

    test('G6 higher die bears off the highest pip, not a lower one', () {
      final p = pos(one: {3: 1, 1: 1}, two: {6: 2});
      expect(stepsOf(hitRules, p, S.one, 6), {const Step(3, 0, 6)});
      expect(stepsOf(hitRules, p, S.one, 4), {const Step(3, 0, 4)});
    });

    test('G6 overshoot steps with different dice stay distinct', () {
      final p = pos(one: {3: 1}, two: {6: 2});
      expect(stepsOf(hitRules, p, S.one, 5), {const Step(3, 0, 5)});
      expect(stepsOf(hitRules, p, S.one, 6), {const Step(3, 0, 6)});
    });

    test('G6 must move when a higher checker exists', () {
      final p = pos(one: {5: 1, 2: 1}, two: {6: 2});
      expect(stepsOf(hitRules, p, S.one, 4), {const Step(5, 1, 4)});
    });

    test('G5 not all home: no bear-off step', () {
      final p = pos(one: {7: 1, 3: 14}, two: {6: 2});
      for (var d = 1; d <= 6; d++) {
        expect(
          stepsOf(hitRules, p, S.one, d).where((s) => s.to == 0),
          isEmpty,
          reason: 'die $d',
        );
      }
      expect(stepsOf(hitRules, p, S.one, 3), {const Step(7, 4, 3)});
    });

    test('G5 checker on the bar blocks bear-off', () {
      final p = pos(one: {3: 14}, two: {6: 2}, barOne: 1);
      expect(allStepsOf(hitRules, p, S.one).where((s) => s.to == 0), isEmpty);
    });

    test('G6 bear-off works for a same-direction game', () {
      final p = posSame(one: {2: 1, 1: 1}, two: {6: 2});
      expect(stepsOf(blockRules, p, S.one, 6), {const Step(2, 0, 6)});
    });
  });
}
