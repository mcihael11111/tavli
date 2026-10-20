/// App `DifficultyLevel` -> bot level plus the teaching flag (design §3).
library;

import 'package:tavli/features/ai/difficulty/difficulty_level.dart';
import 'package:tavli_bot/tavli_bot.dart';

/// The bot level to search at and whether teaching analysis is on.
typedef BotSetting = ({BotLevel level, bool teaching});

extension DifficultyToBot on DifficultyLevel {
  /// `easyWithHelp` is Easy plus teaching; Παππούς is Expert.
  BotSetting get botSetting => switch (this) {
        DifficultyLevel.easy => (level: BotLevel.easy, teaching: false),
        DifficultyLevel.easyWithHelp => (level: BotLevel.easy, teaching: true),
        DifficultyLevel.medium => (level: BotLevel.medium, teaching: false),
        DifficultyLevel.hard => (level: BotLevel.hard, teaching: false),
        DifficultyLevel.pappous => (level: BotLevel.expert, teaching: false),
      };
}
