import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/features/ai/pacing/turn_pacing.dart';
import 'package:tavli/features/ai/difficulty/difficulty_level.dart';
import 'package:tavli/features/ai/personality/bot_personality.dart';

void main() {
  group('TurnPacing.forBot', () {
    test('returns positive durations for every (difficulty, personality) pair', () {
      for (final d in DifficultyLevel.values) {
        for (final p in BotPersonality.values) {
          final pacing = TurnPacing.forBot(d, p);
          expect(pacing.thinkingBeat.inMilliseconds, greaterThan(0), reason: '$d/$p thinkingBeat');
          expect(pacing.diceRattle.inMilliseconds, greaterThan(0), reason: '$d/$p diceRattle');
          expect(pacing.dicePostRollBreather.inMilliseconds, greaterThan(0));
          expect(pacing.interMoveSettle.inMilliseconds, greaterThan(0));
          expect(pacing.finalSettle.inMilliseconds, greaterThan(0));
        }
      }
    });

    test('Mikhail-hard thinking beat is the longest', () {
      final mikhailHard = TurnPacing.forBot(DifficultyLevel.hard, BotPersonality.mikhail);
      final spyrosHard = TurnPacing.forBot(DifficultyLevel.hard, BotPersonality.spyrosUncle);
      final nikosHard = TurnPacing.forBot(DifficultyLevel.hard, BotPersonality.cousinNikos);
      expect(mikhailHard.thinkingBeat.inMilliseconds, equals(220));
      expect(spyrosHard.thinkingBeat.inMilliseconds, equals(150));
      expect(nikosHard.thinkingBeat.inMilliseconds, equals(100));
    });

    test('easy and easyWithHelp share thinking beats', () {
      for (final p in BotPersonality.values) {
        final easy = TurnPacing.forBot(DifficultyLevel.easy, p);
        final easyHelp = TurnPacing.forBot(DifficultyLevel.easyWithHelp, p);
        expect(easy.thinkingBeat, equals(easyHelp.thinkingBeat));
      }
    });

    test('shared base values are constant', () {
      final p = TurnPacing.forBot(DifficultyLevel.medium, BotPersonality.mikhail);
      expect(p.diceRattle.inMilliseconds, equals(280));
      expect(p.dicePostRollBreather.inMilliseconds, equals(160));
      expect(p.interMoveSettle.inMilliseconds, equals(40));
      expect(p.finalSettle.inMilliseconds, equals(60));
    });
  });
}
