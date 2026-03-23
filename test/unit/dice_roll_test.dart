import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/features/game/data/models/dice_roll.dart';

void main() {
  group('DiceRoll', () {
    test('isDoubles true when dice match', () {
      expect(const DiceRoll(die1: 3, die2: 3).isDoubles, true);
      expect(const DiceRoll(die1: 6, die2: 6).isDoubles, true);
    });

    test('isDoubles false when dice differ', () {
      expect(const DiceRoll(die1: 3, die2: 5).isDoubles, false);
    });

    test('movesAvailable returns 2 for normal roll', () {
      const roll = DiceRoll(die1: 3, die2: 5);
      expect(roll.movesAvailable, [3, 5]);
    });

    test('movesAvailable returns 4 for doubles', () {
      const roll = DiceRoll(die1: 4, die2: 4);
      expect(roll.movesAvailable, [4, 4, 4, 4]);
    });

    test('random generates valid dice', () {
      final rng = Random(42);
      for (int i = 0; i < 100; i++) {
        final roll = DiceRoll.random(rng);
        expect(roll.die1, inInclusiveRange(1, 6));
        expect(roll.die2, inInclusiveRange(1, 6));
      }
    });

    test('equality', () {
      expect(
        const DiceRoll(die1: 3, die2: 5),
        equals(const DiceRoll(die1: 3, die2: 5)),
      );
      expect(
        const DiceRoll(die1: 3, die2: 5),
        isNot(equals(const DiceRoll(die1: 5, die2: 3))),
      );
    });
  });
}
