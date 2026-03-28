import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tavli/features/tutorial/presentation/tutorial_screen.dart';
import 'package:tavli/shared/services/settings_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.initialize();
  });

  group('TutorialScreen', () {
    testWidgets('renders first lesson', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TutorialScreen()));
      expect(find.text('The Board'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('can navigate to next lesson', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TutorialScreen()));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Moving Checkers'), findsOneWidget);
    });

    testWidgets('shows progress indicator', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TutorialScreen()));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('last lesson shows Start Playing button', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TutorialScreen()));
      // Tavli tradition: 6 base + 3 tradition-specific = 9 lessons.
      // Navigate through all but the last.
      for (int i = 0; i < 8; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Start Playing!'), findsOneWidget);
    });

    testWidgets('shows tradition-specific lessons for Tavli', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TutorialScreen()));
      // Navigate to the tradition-specific lessons (after 6 base lessons).
      for (int i = 0; i < 6; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      // First tradition-specific lesson for Tavli is "Plakoto — Pinning".
      expect(find.textContaining('Plakoto'), findsOneWidget);
    });
  });
}
