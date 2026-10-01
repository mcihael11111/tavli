import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/positions.dart';
import '../support/steps.dart';

void main() {
  group('pinning', () {
    test('§4.2 pin: 8->6 pins two:19, pinned checker cannot move, undo', () {
      final p = pos(one: {8: 1, 24: 14}, two: {19: 1, 24: 14});
      final after = pos(
        one: {6: 1, 24: 14},
        two: {19: 1, 24: 14},
        pinnedTwo: {19},
      );
      final a =
          roundTrip(pinRules, p, S.one, const Step(8, 6, 2), after: after);
      expect(a.pinned, isTrue);
      expect(a.hit || a.unpinned || a.bearOff, isFalse);
      expect(after.isPinned(S.two, 19), isTrue);
      expect(allStepsOf(pinRules, after, S.two).where((s) => s.from == 19),
          isEmpty);
    });

    test('§4.2 pin: stacking onto my own pinner is not a new pin', () {
      final p = pos(
        one: {8: 1, 6: 1, 24: 13},
        two: {19: 1, 24: 14},
        pinnedTwo: {19},
      );
      final a = roundTrip(pinRules, p, S.one, const Step(8, 6, 2));
      expect(a.pinned, isFalse);
    });

    test('§4.2 pin closed to owner: cannot land on my pinned checker point',
        () {
      final p = pos(
        one: {1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 6: 1, 7: 1, 24: 8},
        two: {24: 1, 12: 14},
        pinnedOne: {1},
      );
      expect(allStepsOf(pinRules, p, S.one).where((s) => s.to == 1), isEmpty);
      // The pinned checker itself never moves.
      expect(allStepsOf(pinRules, p, S.one).where((s) => s.from == 1), isEmpty);
    });

    test('§4.2 pin: two opposing checkers block', () {
      final p = pos(one: {8: 1, 24: 14}, two: {19: 2, 24: 13});
      expect(stepsOf(pinRules, p, S.one, 2), {const Step(24, 22, 2)});
    });

    test('D11 no bear-off while pinned outside home (allHome false)', () {
      final p = pos(
        one: {20: 1, 5: 14},
        two: {5: 1, 24: 14},
        pinnedOne: {20},
      );
      expect(allStepsOf(pinRules, p, S.one).where((s) => s.to == 0), isEmpty);
    });

    test('D11 no bear-off while pinned inside home', () {
      final p = pos(
        one: {5: 14, 3: 1},
        two: {22: 1, 24: 14},
        pinnedOne: {3},
      );
      expect(p.allHome(S.one), isTrue);
      expect(stepsOf(pinRules, p, S.one, 5).where((s) => s.to == 0), isEmpty);
      expect(allStepsOf(pinRules, p, S.one).where((s) => s.to == 0), isEmpty);
    });

    test('D11 bear-off allowed in a pinning game once nothing is pinned', () {
      final p = pos(one: {5: 14, 3: 1}, two: {24: 15});
      expect(stepsOf(pinRules, p, S.one, 5), contains(const Step(5, 0, 5)));
    });

    test('§4.2 unpin: the last pinner leaving releases, undo re-pins', () {
      final p = pos(
        one: {6: 1, 24: 14},
        two: {19: 1, 24: 14},
        pinnedTwo: {19},
      );
      final a = roundTrip(
        pinRules,
        p,
        S.one,
        const Step(6, 3, 3),
        after: pos(one: {3: 1, 24: 14}, two: {19: 1, 24: 14}),
      );
      expect(a.unpinned, isTrue);
      expect(a.pinned || a.hit || a.bearOff, isFalse);
    });

    test('§4.2 unpin: a remaining pinner keeps the pin', () {
      final p = pos(
        one: {6: 2, 24: 13},
        two: {19: 1, 24: 14},
        pinnedTwo: {19},
      );
      final a = roundTrip(pinRules, p, S.one, const Step(6, 3, 3));
      expect(a.unpinned, isFalse);
    });

    test('§4.2 unpin and pin in one step both undo exactly', () {
      final p = pos(
        one: {6: 1, 24: 14},
        two: {19: 1, 22: 1, 24: 13},
        pinnedTwo: {19},
      );
      final a = roundTrip(
        pinRules,
        p,
        S.one,
        const Step(6, 3, 3),
        after: pos(
          one: {3: 1, 24: 14},
          two: {19: 1, 22: 1, 24: 13},
          pinnedTwo: {22},
        ),
      );
      expect(a.unpinned && a.pinned, isTrue);
    });

    test('§4.2 unpin by bearing off the last pinner', () {
      // one all home pinning two:19 (= my 6) with its last checker.
      final p = pos(one: {6: 1, 2: 1}, two: {19: 1}, pinnedTwo: {19});
      final a = roundTrip(
        pinRules,
        p,
        S.one,
        const Step(6, 0, 6),
        after: pos(one: {2: 1}, two: {19: 1}),
      );
      expect(a.bearOff && a.unpinned, isTrue);
    });
  });
}
