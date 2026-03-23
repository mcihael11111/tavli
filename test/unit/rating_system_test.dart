import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/features/game/data/models/game_result.dart';
import 'package:tavli/features/multiplayer/domain/rating_system.dart';

void main() {
  const rating = RatingSystem();

  group('RatingSystem', () {
    group('K-factor scaling', () {
      test('uses K=40 for first 30 games', () {
        final result = rating.calculateNewRatings(
          winnerRating: 1000,
          loserRating: 1000,
          winnerGamesPlayed: 5,
          loserGamesPlayed: 5,
          resultType: GameResultType.single,
        );
        // Equal ratings → expected = 0.5, actual = 1.0, delta = K * 0.5 = 20
        expect(result.winnerDelta, equals(20));
        expect(result.loserDelta, equals(-20));
      });

      test('uses K=25 for games 31-100', () {
        final result = rating.calculateNewRatings(
          winnerRating: 1000,
          loserRating: 1000,
          winnerGamesPlayed: 50,
          loserGamesPlayed: 50,
          resultType: GameResultType.single,
        );
        // K=25, delta = 25 * 0.5 = 12.5 → 13 (rounded)
        expect(result.winnerDelta, equals(13));
        expect(result.loserDelta, equals(-13));
      });

      test('uses K=16 for 100+ games', () {
        final result = rating.calculateNewRatings(
          winnerRating: 1000,
          loserRating: 1000,
          winnerGamesPlayed: 150,
          loserGamesPlayed: 150,
          resultType: GameResultType.single,
        );
        // K=16, delta = 16 * 0.5 = 8
        expect(result.winnerDelta, equals(8));
        expect(result.loserDelta, equals(-8));
      });
    });

    group('gammon/backgammon weighting', () {
      test('gammon gives 1.5x weighted score', () {
        final single = rating.calculateNewRatings(
          winnerRating: 1000,
          loserRating: 1000,
          winnerGamesPlayed: 5,
          loserGamesPlayed: 5,
          resultType: GameResultType.single,
        );
        final gammon = rating.calculateNewRatings(
          winnerRating: 1000,
          loserRating: 1000,
          winnerGamesPlayed: 5,
          loserGamesPlayed: 5,
          resultType: GameResultType.gammon,
        );
        // Gammon delta should be larger than single
        expect(gammon.winnerDelta, greaterThan(single.winnerDelta));
      });

      test('backgammon gives 2.0x weighted score', () {
        final gammon = rating.calculateNewRatings(
          winnerRating: 1000,
          loserRating: 1000,
          winnerGamesPlayed: 5,
          loserGamesPlayed: 5,
          resultType: GameResultType.gammon,
        );
        final bg = rating.calculateNewRatings(
          winnerRating: 1000,
          loserRating: 1000,
          winnerGamesPlayed: 5,
          loserGamesPlayed: 5,
          resultType: GameResultType.backgammon,
        );
        expect(bg.winnerDelta, greaterThan(gammon.winnerDelta));
      });
    });

    group('rating difference effects', () {
      test('underdog wins more rating than favorite', () {
        final result = rating.calculateNewRatings(
          winnerRating: 800,
          loserRating: 1200,
          winnerGamesPlayed: 50,
          loserGamesPlayed: 50,
          resultType: GameResultType.single,
        );
        // Underdog (800) beat favorite (1200) — big gain
        expect(result.winnerDelta, greaterThan(15));
        // Favorite loses more
        expect(result.loserDelta, lessThan(-5));
      });

      test('favorite wins less rating than underdog would', () {
        final result = rating.calculateNewRatings(
          winnerRating: 1200,
          loserRating: 800,
          winnerGamesPlayed: 50,
          loserGamesPlayed: 50,
          resultType: GameResultType.single,
        );
        // Favorite (1200) beat underdog (800) — small gain
        expect(result.winnerDelta, lessThan(10));
      });
    });

    group('rating bounds', () {
      test('ratings are clamped to [100, 4000]', () {
        final result = rating.calculateNewRatings(
          winnerRating: 3990,
          loserRating: 110,
          winnerGamesPlayed: 5,
          loserGamesPlayed: 5,
          resultType: GameResultType.backgammon,
        );
        expect(result.newWinnerRating, lessThanOrEqualTo(4000));
        expect(result.newLoserRating, greaterThanOrEqualTo(100));
      });
    });

    group('RatingUpdate fields', () {
      test('deltas match old vs new rating', () {
        final result = rating.calculateNewRatings(
          winnerRating: 1000,
          loserRating: 1000,
          winnerGamesPlayed: 50,
          loserGamesPlayed: 50,
          resultType: GameResultType.single,
        );
        expect(result.newWinnerRating, equals(1000 + result.winnerDelta));
        expect(result.newLoserRating, equals(1000 + result.loserDelta));
      });

      test('winner always gains, loser always loses', () {
        final result = rating.calculateNewRatings(
          winnerRating: 1500,
          loserRating: 1200,
          winnerGamesPlayed: 100,
          loserGamesPlayed: 100,
          resultType: GameResultType.single,
        );
        expect(result.winnerDelta, greaterThan(0));
        expect(result.loserDelta, lessThan(0));
      });
    });
  });
}
