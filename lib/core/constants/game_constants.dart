/// Game-wide constants for Tavli.
abstract final class GameConstants {
  /// Total points on a backgammon board.
  static const int totalPoints = 24;

  /// Checkers per player.
  static const int checkersPerPlayer = 15;

  /// Points in each quadrant.
  static const int pointsPerQuadrant = 6;

  /// Sentinel value: checker is on the bar.
  static const int barIndex = -1;

  /// Sentinel value: checker is borne off.
  static const int bearOffIndex = -2;

  /// Home board range for player 1 (points 1-6 → indices 0-5).
  static const int homeStart = 0;
  static const int homeEnd = 5;

  /// Home board range for player 2 (points 19-24 → indices 18-23).
  static const int opponentHomeStart = 18;
  static const int opponentHomeEnd = 23;

  /// Initial checker placement for player 1 (positive values).
  /// Index = point index (0-based), value = number of checkers.
  static const Map<int, int> initialPlacementPlayer1 = {
    23: 2,  // 24-point: 2 checkers
    12: 5,  // 13-point: 5 checkers
    7: 3,   // 8-point:  3 checkers
    5: 5,   // 6-point:  5 checkers
  };

  /// Initial checker placement for player 2 (negative values in board).
  /// Mirrored from player 1.
  static const Map<int, int> initialPlacementPlayer2 = {
    0: 2,   // 1-point (opponent's 24): 2 checkers
    11: 5,  // 12-point (opponent's 13): 5 checkers
    16: 3,  // 17-point (opponent's 8): 3 checkers
    18: 5,  // 19-point (opponent's 6): 5 checkers
  };

  /// Maximum value on a single die.
  static const int maxDieValue = 6;

  /// Minimum value on a single die.
  static const int minDieValue = 1;

  /// Number of moves granted by doubles.
  static const int doublesMultiplier = 4;

  /// Doubling cube starting value.
  static const int initialCubeValue = 1;
}
