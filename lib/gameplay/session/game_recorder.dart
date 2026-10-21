/// Records a finished vs-bot match through the existing services (design
/// §3, game end): progression, match history, achievements and coins.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tavli/features/ai/difficulty/difficulty_level.dart';
import 'package:tavli/features/ai/personality/bot_personality.dart';
import 'package:tavli/features/game/data/models/game_result.dart' as app;
import 'package:tavli/features/profile/data/achievements.dart';
import 'package:tavli/features/profile/presentation/match_history_screen.dart'
    show MatchHistoryService, MatchRecord;
import 'package:tavli/features/shop/data/shop_items.dart' show ShopService;
import 'package:tavli/shared/services/progression_service.dart';

/// What recording awarded, for the victory screen to show.
typedef RecordOutcome = ({int coinsEarned, List<Achievement> unlocked});

/// Records vs-bot results; pass & play never calls it.
abstract interface class GameRecorder {
  /// Records [result] (winner 1 = the human) against the bot. Never throws.
  RecordOutcome recordVsBot({
    required app.GameResult result,
    required DifficultyLevel difficulty,
    required BotPersonality personality,
  });
}

/// [GameRecorder] over the app's service singletons, as the legacy victory
/// screen recorded.
class ServiceGameRecorder implements GameRecorder {
  const ServiceGameRecorder();

  /// Coins for a win at [d].
  static int winReward(DifficultyLevel d) => switch (d) {
        DifficultyLevel.easy || DifficultyLevel.easyWithHelp => 5,
        DifficultyLevel.medium => 10,
        DifficultyLevel.hard => 20,
        DifficultyLevel.pappous => 30,
      };

  @override
  RecordOutcome recordVsBot({
    required app.GameResult result,
    required DifficultyLevel difficulty,
    required BotPersonality personality,
  }) {
    var coins = 0;
    var unlocked = const <Achievement>[];
    final won = result.winner == 1;
    try {
      ProgressionService.instance.recordGame(difficulty, result);
      unawaited(MatchHistoryService.record(MatchRecord(
        timestamp: DateTime.now(),
        difficulty: difficulty,
        opponentName: '${personality.greekName} (${difficulty.greekName})',
        playerWon: won,
        resultType: result.type,
        cubeValue: result.cubeValue,
      )).catchError((Object e) => debugPrint('Match history error: $e')));
      unlocked = AchievementService.instance
          .checkAndUnlock(result: result, difficulty: difficulty);
      for (final a in unlocked) {
        if (a.rewardCoins > 0) {
          ShopService.instance.addCoins(a.rewardCoins);
          coins += a.rewardCoins;
        }
      }
      if (won) {
        final reward = winReward(difficulty);
        ShopService.instance.addCoins(reward);
        coins += reward;
      }
    } catch (e) {
      debugPrint('GameRecorder: save error: $e');
    }
    return (coinsEarned: coins, unlocked: unlocked);
  }
}
