/// Dice as data (design spec §5.2).
library;

import 'dart:math';

/// Two dice. The reducer takes dice only as action data and never rolls;
/// callers (app, server, tests) roll with [DiceRoll.random].
final class DiceRoll {
  final int d1, d2;

  /// Throws [RangeError] unless both dice are in 1..6.
  DiceRoll(this.d1, this.d2) {
    RangeError.checkValueInInterval(d1, 1, 6, 'd1');
    RangeError.checkValueInInterval(d2, 1, 6, 'd2');
  }

  /// A uniformly random roll from [rng].
  factory DiceRoll.random(Random rng) =>
      DiceRoll(1 + rng.nextInt(6), 1 + rng.nextInt(6));

  bool get isDouble => d1 == d2;

  @override
  bool operator ==(Object other) =>
      other is DiceRoll && other.d1 == d1 && other.d2 == d2;

  @override
  int get hashCode => Object.hash(d1, d2);

  @override
  String toString() => 'DiceRoll($d1, $d2)';
}
