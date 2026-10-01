/// How a game ended and what it scored (design spec §5.4).
library;

import '../board/side.dart';

/// The kind of game end.
enum ResultKind {
  single,
  gammon,
  triple,
  mother,
  draw,
  checkersRemaining,
  resign,
}

/// The result of a finished game.
final class GameResult {
  /// The winner; null for a draw.
  final Side? winner;
  final ResultKind kind;

  /// Points to the winner, cube included; for a draw, points to EACH side.
  final int points;

  /// The cube value the game ended at.
  final int cubeValue;

  const GameResult({
    required this.winner,
    required this.kind,
    required this.points,
    required this.cubeValue,
  });

  @override
  bool operator ==(Object other) =>
      other is GameResult &&
      other.winner == winner &&
      other.kind == kind &&
      other.points == points &&
      other.cubeValue == cubeValue;

  @override
  int get hashCode => Object.hash(winner, kind, points, cubeValue);

  @override
  String toString() => 'GameResult(${winner?.name ?? 'draw'}, ${kind.name}, '
      '$points, cube $cubeValue)';
}
