import 'dart:math' as math;

import '../../game/data/models/game_result.dart';

/// Elo rating calculator per spec.
///
/// K-factor scaling:
/// - First 30 games: K=40
/// - Games 31-100: K=25
/// - After 100 games: K=16
///
/// Gammon = 1.5 wins, backgammon = 2.0 wins for rating.
class RatingSystem {
  const RatingSystem();

  /// Calculate new ratings after a game.
  RatingUpdate calculateNewRatings({
    required int winnerRating,
    required int loserRating,
    required int winnerGamesPlayed,
    required int loserGamesPlayed,
    required GameResultType resultType,
  }) {
    final winnerK = _kFactor(winnerGamesPlayed);
    final loserK = _kFactor(loserGamesPlayed);

    // Expected scores (Elo formula).
    final expectedWinner = _expectedScore(winnerRating, loserRating);
    final expectedLoser = 1.0 - expectedWinner;

    // Actual score — gammon/backgammon are weighted.
    final actualScore = switch (resultType) {
      GameResultType.single => 1.0,
      GameResultType.gammon => 1.5,
      GameResultType.backgammon => 2.0,
    };

    // Winner gains based on weighted actual score vs expectation.
    final newWinnerRating = winnerRating +
        (winnerK * (actualScore - expectedWinner)).round();
    // Loser's actual score is 0; penalty is symmetric to winner's gain.
    final newLoserRating = loserRating +
        (loserK * (0 - expectedLoser)).round();

    return RatingUpdate(
      newWinnerRating: newWinnerRating.clamp(100, 4000),
      newLoserRating: newLoserRating.clamp(100, 4000),
      winnerDelta: newWinnerRating - winnerRating,
      loserDelta: newLoserRating - loserRating,
    );
  }

  double _expectedScore(int ratingA, int ratingB) {
    return 1.0 / (1.0 + math.pow(10, (ratingB - ratingA) / 400.0));
  }

  int _kFactor(int gamesPlayed) {
    if (gamesPlayed < 30) return 40;
    if (gamesPlayed < 100) return 25;
    return 16;
  }
}

class RatingUpdate {
  final int newWinnerRating;
  final int newLoserRating;
  final int winnerDelta;
  final int loserDelta;

  const RatingUpdate({
    required this.newWinnerRating,
    required this.newLoserRating,
    required this.winnerDelta,
    required this.loserDelta,
  });
}
