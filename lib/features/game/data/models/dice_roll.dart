import 'dart:math';
import 'package:equatable/equatable.dart';

/// Represents a roll of two dice.
class DiceRoll extends Equatable {
  final int die1;
  final int die2;

  const DiceRoll({required this.die1, required this.die2})
      : assert(die1 >= 1 && die1 <= 6, 'die1 must be 1-6'),
        assert(die2 >= 1 && die2 <= 6, 'die2 must be 1-6');

  /// Whether both dice show the same value.
  bool get isDoubles => die1 == die2;

  /// The individual die values available for moves.
  /// Doubles produce 4 moves; normal rolls produce 2.
  List<int> get movesAvailable =>
      isDoubles ? [die1, die1, die1, die1] : [die1, die2];

  /// Generate a random dice roll.
  factory DiceRoll.random([Random? rng]) {
    final r = rng ?? Random();
    return DiceRoll(
      die1: r.nextInt(6) + 1,
      die2: r.nextInt(6) + 1,
    );
  }

  @override
  List<Object?> get props => [die1, die2];

  @override
  String toString() => 'DiceRoll($die1, $die2)';
}
