import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/features/tutorial/presentation/tutorial_screen.dart';

void main() {
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
      // Navigate through all lessons.
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Start Playing!'), findsOneWidget);
    });
  });
}
