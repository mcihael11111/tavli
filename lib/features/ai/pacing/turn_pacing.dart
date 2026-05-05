import 'package:tavli/features/ai/difficulty/difficulty_level.dart';
import 'package:tavli/features/ai/personality/bot_personality.dart';

/// Pacing values for an AI turn — how long the bot pauses before acting,
/// how long the dice rattle, and the small breathers between phases.
///
/// Values are tuned per (difficulty, personality) so different bots feel
/// distinct: Mikhail-on-hard takes the longest "thinking beat", impulsive
/// personalities (cousinNikos) move quickest. Shared base values keep the
/// dice rattle and inter-move settle uniform across bots.
///
/// Spec: docs/superpowers/specs/2026-05-05-gameplay-feel-and-pacing-design.md §5
class TurnPacing {
  /// Initial pause before the AI rolls — registers intent.
  final Duration thinkingBeat;

  /// Pause after dice land before the AI starts moving — lets the player
  /// read the roll.
  final Duration dicePostRollBreather;

  /// Gap between successive AI moves within the same turn.
  final Duration interMoveSettle;

  /// Final settle beat before control returns to the player.
  final Duration finalSettle;

  /// How long the dice tumble/flicker before settling on their real values.
  final Duration diceRattle;

  const TurnPacing({
    required this.thinkingBeat,
    required this.dicePostRollBreather,
    required this.interMoveSettle,
    required this.finalSettle,
    required this.diceRattle,
  });

  static const _baseRattle = Duration(milliseconds: 280);
  static const _basePostRoll = Duration(milliseconds: 160);
  static const _baseInterMove = Duration(milliseconds: 40);
  static const _baseFinalSettle = Duration(milliseconds: 60);

  /// Build pacing for a specific bot. Only [thinkingBeat] varies; the other
  /// timings are uniform across bots so the rattle/inter-move feel is
  /// consistent.
  factory TurnPacing.forBot(
    DifficultyLevel difficulty,
    BotPersonality personality,
  ) {
    final beat = _thinkingBeat(difficulty, personality);
    return TurnPacing(
      thinkingBeat: beat,
      dicePostRollBreather: _basePostRoll,
      interMoveSettle: _baseInterMove,
      finalSettle: _baseFinalSettle,
      diceRattle: _baseRattle,
    );
  }

  static Duration _thinkingBeat(DifficultyLevel d, BotPersonality p) {
    final isMikhail = p == BotPersonality.mikhail;
    final isNikos = p == BotPersonality.cousinNikos;
    switch (d) {
      case DifficultyLevel.easy:
      case DifficultyLevel.easyWithHelp:
        if (isMikhail) return const Duration(milliseconds: 100);
        return const Duration(milliseconds: 60);
      case DifficultyLevel.medium:
        if (isMikhail) return const Duration(milliseconds: 160);
        if (isNikos) return const Duration(milliseconds: 80);
        return const Duration(milliseconds: 110);
      case DifficultyLevel.hard:
        if (isMikhail) return const Duration(milliseconds: 220);
        if (isNikos) return const Duration(milliseconds: 100);
        return const Duration(milliseconds: 150);
      case DifficultyLevel.pappous:
        // Παππούς: deliberate, slightly longer than hard's mid-tier.
        if (isMikhail) return const Duration(milliseconds: 240);
        if (isNikos) return const Duration(milliseconds: 120);
        return const Duration(milliseconds: 170);
    }
  }
}
