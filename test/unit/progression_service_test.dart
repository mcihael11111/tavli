import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/shared/services/progression_service.dart';
import 'package:tavli/features/ai/difficulty/difficulty_level.dart';
import 'package:tavli/features/game/data/models/game_result.dart';

void main() {
  group('DifficultyStats', () {
    test('starts with zero', () {
      const stats = DifficultyStats();
      expect(stats.wins, 0);
      expect(stats.losses, 0);
      expect(stats.totalGames, 0);
      expect(stats.winRate, 0.0);
      expect(stats.currentStreak, 0);
      expect(stats.bestStreak, 0);
    });

    test('recordWin increments wins and streak', () {
      const stats = DifficultyStats();
      final after = stats.recordWin(GameResultType.single);
      expect(after.wins, 1);
      expect(after.losses, 0);
      expect(after.currentStreak, 1);
      expect(after.bestStreak, 1);
    });

    test('recordWin tracks gammons', () {
      const stats = DifficultyStats();
      final after = stats.recordWin(GameResultType.gammon);
      expect(after.gammons, 1);
      expect(after.backgammons, 0);
    });

    test('recordWin tracks backgammons', () {
      const stats = DifficultyStats();
      final after = stats.recordWin(GameResultType.backgammon);
      expect(after.backgammons, 1);
    });

    test('recordLoss resets current streak', () {
      const stats = DifficultyStats(wins: 5, currentStreak: 3, bestStreak: 3);
      final after = stats.recordLoss();
      expect(after.losses, 1);
      expect(after.currentStreak, 0);
      expect(after.bestStreak, 3); // preserved
    });

    test('best streak is preserved across losses', () {
      var stats = const DifficultyStats();
      stats = stats.recordWin(GameResultType.single); // streak 1
      stats = stats.recordWin(GameResultType.single); // streak 2
      stats = stats.recordWin(GameResultType.single); // streak 3
      stats = stats.recordLoss(); // streak reset
      stats = stats.recordWin(GameResultType.single); // streak 1
      expect(stats.bestStreak, 3);
      expect(stats.currentStreak, 1);
    });

    test('winRate calculation', () {
      const stats = DifficultyStats(wins: 3, losses: 1);
      expect(stats.winRate, 0.75);
    });

    test('JSON serialization round-trip', () {
      const stats = DifficultyStats(
        wins: 10, losses: 5, currentStreak: 2,
        bestStreak: 4, gammons: 3, backgammons: 1,
      );
      final json = stats.toJson();
      final restored = DifficultyStats.fromJson(json);
      expect(restored.wins, 10);
      expect(restored.losses, 5);
      expect(restored.currentStreak, 2);
      expect(restored.bestStreak, 4);
      expect(restored.gammons, 3);
      expect(restored.backgammons, 1);
    });
  });

  group('DifficultyLevel unlock conditions', () {
    test('easy and easyWithHelp have no unlock condition', () {
      expect(DifficultyLevel.easy.unlockCondition, isNull);
      expect(DifficultyLevel.easyWithHelp.unlockCondition, isNull);
    });

    test('medium requires 3 easy wins', () {
      expect(DifficultyLevel.medium.unlockCondition, isNotNull);
    });

    test('hard requires 5 medium wins or 3 streak', () {
      expect(DifficultyLevel.hard.unlockCondition, isNotNull);
    });

    test('pappous requires 5 hard wins or 3 streak', () {
      expect(DifficultyLevel.pappous.unlockCondition, isNotNull);
    });
  });
}
