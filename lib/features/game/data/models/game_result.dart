/// The outcome type of a finished game.
enum GameResultType {
  /// Loser borne off at least one checker (1x stake).
  single,

  /// Loser has NOT borne off any checkers (2x stake).
  gammon,

  /// Loser has NOT borne off any AND still has checker on bar or in
  /// winner's home board (3x stake).
  backgammon,
}

/// Complete result of a finished game.
class GameResult {
  /// The winning player (1 or 2).
  final int winner;

  /// How decisively the game was won.
  final GameResultType type;

  /// Stake multiplier from the doubling cube.
  final int cubeValue;

  const GameResult({
    required this.winner,
    required this.type,
    this.cubeValue = 1,
  });

  /// Total points scored (type multiplier × cube value).
  int get points {
    final multiplier = switch (type) {
      GameResultType.single => 1,
      GameResultType.gammon => 2,
      GameResultType.backgammon => 3,
    };
    return multiplier * cubeValue;
  }

  @override
  String toString() => 'GameResult(winner=$winner, $type, ${points}pts)';
}
