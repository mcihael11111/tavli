import 'package:equatable/equatable.dart';
import 'dice_roll.dart';
import 'move.dart';

/// A complete turn: one dice roll and all moves made with it.
class Turn extends Equatable {
  final DiceRoll roll;
  final List<Move> moves;

  const Turn({required this.roll, required this.moves});

  /// Number of die values consumed by this turn.
  int get movesUsed => moves.length;

  @override
  List<Object?> get props => [roll, moves];

  @override
  String toString() => 'Turn(roll=$roll, moves=$moves)';
}
