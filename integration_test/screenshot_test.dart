import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tavli/app/app.dart';
import 'package:tavli/shared/services/progression_service.dart';
import 'package:tavli/shared/services/settings_service.dart';
import 'package:tavli/features/profile/data/achievements.dart';
import 'package:tavli/features/social/friends/friend_service.dart';
import 'package:tavli/shared/services/app_info.dart';

/// Takes screenshots of every key screen in the app.
///
/// Run with:
///   flutter test integration_test/screenshot_test.dart
///
/// Screenshots are saved to the `screenshots/` folder.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Helper: pump app, wait for animations, take screenshot.
  Future<void> takeScreenshot(
    WidgetTester tester,
    String name,
  ) async {
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    await binding.takeScreenshot('screenshots/$name');
  }

  group('App screenshots', () {
    setUpAll(() async {
      // Mark onboarding done so splash goes straight to home.
      SharedPreferences.setMockInitialValues({
        'tavli_onboarding_done': true,
      });
      await ProgressionService.initialize();
      await SettingsService.initialize();
      await AchievementService.initialize();
      await FriendService.initialize();
      await AppInfo.initialize();
    });

    testWidgets('capture all key screens', (tester) async {
      // Launch the app.
      await tester.pumpWidget(const ProviderScope(child: TavliApp()));

      // 1. Splash screen.
      await tester.pump(const Duration(milliseconds: 500));
      await binding.takeScreenshot('screenshots/01_splash');

      // Wait for splash to navigate to home (2s delay + animation).
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 2. Home screen.
      await takeScreenshot(tester, '02_home');

      // 3. Profile screen — tap profile nav item.
      await tester.tap(find.byIcon(Icons.person));
      await takeScreenshot(tester, '03_profile');

      // 4. Customization screen — tap palette nav item.
      await tester.tap(find.byIcon(Icons.palette));
      await takeScreenshot(tester, '04_customization');

      // 5. Settings screen — tap settings nav item.
      await tester.tap(find.byIcon(Icons.settings));
      await takeScreenshot(tester, '05_settings');

      // Go back to home for the next flow.
      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();

      // 6. Difficulty screen — find and tap "Play vs AI" / Portes button.
      //    (We look for a button that navigates to /difficulty.)
      final portesButton = find.textContaining('Portes');
      if (portesButton.evaluate().isNotEmpty) {
        await tester.tap(portesButton.first);
        await takeScreenshot(tester, '06_difficulty');

        // Go back to home.
        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton.first);
          await tester.pumpAndSettle();
        }
      }

      // 7. Tutorial screen — find and tap Tutorial button.
      final tutorialButton = find.textContaining('Tutorial');
      if (tutorialButton.evaluate().isNotEmpty) {
        await tester.tap(tutorialButton.first);
        await takeScreenshot(tester, '07_tutorial');

        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton.first);
          await tester.pumpAndSettle();
        }
      }

      // 8. Profile > Match History.
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      final historyButton = find.textContaining('Match History');
      if (historyButton.evaluate().isNotEmpty) {
        await tester.tap(historyButton.first);
        await takeScreenshot(tester, '08_match_history');

        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton.first);
          await tester.pumpAndSettle();
        }
      }

      // 9. Profile > Achievements.
      final achievementsButton = find.textContaining('Achievements');
      if (achievementsButton.evaluate().isNotEmpty) {
        await tester.tap(achievementsButton.first);
        await takeScreenshot(tester, '09_achievements');

        final backButton = find.byIcon(Icons.arrow_back);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton.first);
          await tester.pumpAndSettle();
        }
      }

      // 10. Online flow — go home, tap Online / Play Online.
      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();
      final onlineButton = find.textContaining('Online');
      if (onlineButton.evaluate().isNotEmpty) {
        await tester.tap(onlineButton.first);
        await tester.pumpAndSettle();

        // Could land on sign-in or lobby depending on auth state.
        await takeScreenshot(tester, '10_online');
      }

      debugPrint('✅ All screenshots saved to screenshots/ folder.');
    });
  });

  // Separate test for onboarding (requires fresh state).
  group('Onboarding screenshots', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({
        'tavli_onboarding_done': false,
      });
      await ProgressionService.initialize();
      await SettingsService.initialize();
      await AchievementService.initialize();
      await FriendService.initialize();
      await AppInfo.initialize();
    });

    testWidgets('capture onboarding screens', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: TavliApp()));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should be on onboarding screen 1.
      await takeScreenshot(tester, '00_onboarding_1_welcome');

      // Swipe or tap next for each page.
      for (int i = 2; i <= 4; i++) {
        final nextButton = find.textContaining('Next');
        if (nextButton.evaluate().isNotEmpty) {
          await tester.tap(nextButton.first);
          await tester.pumpAndSettle();
          await takeScreenshot(tester, '00_onboarding_$i');
        } else {
          // Try swiping left.
          await tester.fling(
            find.byType(PageView),
            const Offset(-300, 0),
            1000,
          );
          await tester.pumpAndSettle();
          await takeScreenshot(tester, '00_onboarding_$i');
        }
      }
    });
  });
}
