import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tavli/features/ai/difficulty/difficulty_level.dart';
import 'package:tavli/features/game/data/models/game_state.dart';
import 'package:tavli/features/game/domain/engine/variants/game_variant.dart';
import 'package:tavli/features/game/presentation/game_screen.dart';
import 'package:tavli/features/game/presentation/providers/game_provider.dart';
import 'package:tavli/shared/services/copy_service.dart';
import 'package:tavli/shared/services/settings_service.dart';

/// Baseline frame timings for the LEGACY game screen (vs Easy bot, Portes).
///
/// Player moves are applied through the provider (not Flame taps), so this
/// measures render/rebuild/bot cost rather than hit-testing. Run on the
/// Galaxy S with: tool/device/profile_run.sh legacy_game_perf
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('legacy game: 6 player turns vs easy bot', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.initialize();

    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        home: GameScreen(
          difficulty: DifficultyLevel.easy,
          variant: GameVariant.portes,
        ),
      ),
    ));
    await tester.pump(const Duration(seconds: 1));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(GameScreen)),
    );
    GameState state() => container.read(gameProvider);

    Future<void> idle(int ms) async {
      final end = DateTime.now().add(Duration(milliseconds: ms));
      while (DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    await binding.traceAction(() async {
      // Opening roll.
      await tester.tap(find.text(TavliCopy.rollButton));
      await idle(1500);

      var playerTurns = 0;
      final deadline = DateTime.now().add(const Duration(seconds: 90));
      while (playerTurns < 6 &&
          state().phase != GamePhase.gameOver &&
          DateTime.now().isBefore(deadline)) {
        final s = state();
        if (s.isPlayerTurn && s.phase == GamePhase.playerTurnStart) {
          await tester.tap(find.text(TavliCopy.roll));
          await idle(600);
        } else if (s.isPlayerTurn &&
            s.phase == GamePhase.movingCheckers &&
            s.legalTurns.isNotEmpty) {
          final notifier = container.read(gameProvider.notifier);
          for (final move in s.legalTurns.first.moves) {
            notifier.selectChecker(move.fromPoint);
            await idle(150);
            notifier.makeMove(move.toPoint);
            await idle(250);
          }
          playerTurns++;
        } else {
          await idle(200); // bot turn / transitions
        }
      }
    }, reportKey: 'legacy_game_easy');
  });
}
