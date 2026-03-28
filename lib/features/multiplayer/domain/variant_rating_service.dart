import 'package:shared_preferences/shared_preferences.dart';
import '../../game/data/models/game_result.dart' show GameResultType;
import '../../game/domain/engine/variants/game_variant.dart';
import 'rating_system.dart';

/// Per-variant rating service.
///
/// Maintains separate ELO ratings for each variant. When a player starts
/// a new variant, their rating is seeded from their existing ratings using
/// a Bayesian prior (weighted average) rather than the default starting rating.
class VariantRatingService {
  static const _ratingPrefix = 'variant_rating_';
  static const _gamesPrefix = 'variant_games_';
  static const _defaultRating = 1200;
  static const _bayesianWeight = 0.6; // How much existing ratings influence new variant start

  static VariantRatingService? _instance;
  final SharedPreferences _prefs;
  final RatingSystem _ratingSystem;

  VariantRatingService._(this._prefs) : _ratingSystem = const RatingSystem();

  static Future<VariantRatingService> initialize() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    _instance = VariantRatingService._(prefs);
    return _instance!;
  }

  static VariantRatingService get instance {
    if (_instance == null) {
      throw StateError('VariantRatingService not initialized.');
    }
    return _instance!;
  }

  // ── Rating Getters ─────────────────────────────────────────

  /// Get the player's rating for a specific variant.
  int ratingFor(GameVariant variant) {
    final stored = _prefs.getInt('$_ratingPrefix${variant.name}');
    if (stored != null) return stored;

    // First time playing this variant — use Bayesian prior from other ratings.
    return _bayesianPriorRating(variant);
  }

  /// Get the number of rated games for a variant.
  int gamesFor(GameVariant variant) =>
      _prefs.getInt('$_gamesPrefix${variant.name}') ?? 0;

  /// Get all variant ratings as a map.
  Map<GameVariant, int> get allRatings {
    final map = <GameVariant, int>{};
    for (final v in GameVariant.values) {
      if (_prefs.containsKey('$_ratingPrefix${v.name}')) {
        map[v] = _prefs.getInt('$_ratingPrefix${v.name}')!;
      }
    }
    return map;
  }

  /// Weighted average rating across all played variants.
  int get overallRating {
    final ratings = allRatings;
    if (ratings.isEmpty) return _defaultRating;

    int totalWeightedRating = 0;
    int totalGames = 0;
    for (final entry in ratings.entries) {
      final games = gamesFor(entry.key);
      if (games > 0) {
        totalWeightedRating += entry.value * games;
        totalGames += games;
      }
    }
    return totalGames > 0 ? totalWeightedRating ~/ totalGames : _defaultRating;
  }

  // ── Rating Updates ─────────────────────────────────────────

  /// Update rating after a game result.
  /// Returns the rating delta for the player.
  int recordResult({
    required GameVariant variant,
    required int opponentRating,
    required bool won,
    required GameResultType resultType,
  }) {
    final currentRating = ratingFor(variant);
    final currentGames = gamesFor(variant);

    final update = won
        ? _ratingSystem.calculateNewRatings(
            winnerRating: currentRating,
            loserRating: opponentRating,
            winnerGamesPlayed: currentGames,
            loserGamesPlayed: 100, // Assume opponent is established
            resultType: resultType,
          )
        : _ratingSystem.calculateNewRatings(
            winnerRating: opponentRating,
            loserRating: currentRating,
            winnerGamesPlayed: 100,
            loserGamesPlayed: currentGames,
            resultType: resultType,
          );

    final newRating = won ? update.newWinnerRating : update.newLoserRating;
    final delta = newRating - currentRating;

    _prefs.setInt('$_ratingPrefix${variant.name}', newRating);
    _prefs.setInt('$_gamesPrefix${variant.name}', currentGames + 1);

    return delta;
  }

  // ── Bayesian Prior ─────────────────────────────────────────

  /// Calculate a starting rating for a new variant based on existing ratings.
  ///
  /// Instead of starting everyone at 1200, we use a weighted average of their
  /// ratings in other variants (especially same mechanic family) as a prior.
  /// This prevents a 1700 Portes player from being matched with 1200 beginners
  /// when they first try Plakoto.
  int _bayesianPriorRating(GameVariant newVariant) {
    final existing = allRatings;
    if (existing.isEmpty) return _defaultRating;

    // Weight same-mechanic variants more heavily.
    double weightedSum = 0;
    double totalWeight = 0;

    for (final entry in existing.entries) {
      final games = gamesFor(entry.key);
      if (games == 0) continue;

      double weight = games.toDouble().clamp(1, 30);

      // Same mechanic family gets 2x weight.
      if (entry.key.mechanicFamily == newVariant.mechanicFamily) {
        weight *= 2;
      }
      // Same tradition gets 1.5x weight.
      if (entry.key.tradition == newVariant.tradition) {
        weight *= 1.5;
      }

      weightedSum += entry.value * weight;
      totalWeight += weight;
    }

    if (totalWeight == 0) return _defaultRating;

    final prior = (weightedSum / totalWeight).round();

    // Blend prior with default: 60% prior, 40% default.
    // This prevents wildly high/low starting ratings.
    return (prior * _bayesianWeight + _defaultRating * (1 - _bayesianWeight))
        .round();
  }
}

// Uses GameResultType from game_result.dart (imported via rating_system.dart).
