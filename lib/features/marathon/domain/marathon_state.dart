import '../../game/data/models/game_result.dart';
import '../../game/domain/engine/variants/game_variant.dart';
import '../../../core/constants/tradition.dart';

/// State for a Marathon match — rotating through variants in a tradition.
///
/// A marathon cycles through all variants in a tradition (e.g., Portes -> Plakoto -> Fevga)
/// and awards points per game. First player to reach the target score wins.
class MarathonState {
  /// The tradition being played.
  final Tradition tradition;

  /// Ordered list of variants in the rotation.
  final List<GameVariant> variants;

  /// Index of the current variant in [variants].
  final int currentVariantIndex;

  /// Player 1 (human) score.
  final int player1Score;

  /// Player 2 (AI/opponent) score.
  final int player2Score;

  /// Target score to win the marathon.
  final int targetScore;

  /// Results from each completed game.
  final List<MarathonGameRecord> gameHistory;

  /// Whether the marathon is finished.
  final bool isComplete;

  /// The overall winner (1 or 2), or null if not complete.
  final int? winner;

  const MarathonState({
    required this.tradition,
    required this.variants,
    this.currentVariantIndex = 0,
    this.player1Score = 0,
    this.player2Score = 0,
    this.targetScore = 5,
    this.gameHistory = const [],
    this.isComplete = false,
    this.winner,
  });

  /// The current variant to play.
  GameVariant get currentVariant => variants[currentVariantIndex];

  /// Total games played so far.
  int get gamesPlayed => gameHistory.length;

  /// Create initial state for a tradition's marathon.
  factory MarathonState.forTradition(Tradition tradition, {int targetScore = 5}) {
    return MarathonState(
      tradition: tradition,
      variants: tradition.variants,
      targetScore: targetScore,
    );
  }

  /// Record a game result and advance to the next variant.
  MarathonState recordResult(GameResult result) {
    final points = result.points;
    final newP1 = result.winner == 1 ? player1Score + points : player1Score;
    final newP2 = result.winner == 2 ? player2Score + points : player2Score;

    final record = MarathonGameRecord(
      variant: currentVariant,
      result: result,
      player1ScoreAfter: newP1,
      player2ScoreAfter: newP2,
    );

    final newHistory = [...gameHistory, record];

    // Check if marathon is won.
    if (newP1 >= targetScore || newP2 >= targetScore) {
      return MarathonState(
        tradition: tradition,
        variants: variants,
        currentVariantIndex: currentVariantIndex,
        player1Score: newP1,
        player2Score: newP2,
        targetScore: targetScore,
        gameHistory: newHistory,
        isComplete: true,
        winner: newP1 >= targetScore ? 1 : 2,
      );
    }

    // Advance to next variant (cycle).
    final nextIndex = (currentVariantIndex + 1) % variants.length;

    return MarathonState(
      tradition: tradition,
      variants: variants,
      currentVariantIndex: nextIndex,
      player1Score: newP1,
      player2Score: newP2,
      targetScore: targetScore,
      gameHistory: newHistory,
    );
  }
}

/// Record of a single game within a marathon.
class MarathonGameRecord {
  final GameVariant variant;
  final GameResult result;
  final int player1ScoreAfter;
  final int player2ScoreAfter;

  const MarathonGameRecord({
    required this.variant,
    required this.result,
    required this.player1ScoreAfter,
    required this.player2ScoreAfter,
  });
}
