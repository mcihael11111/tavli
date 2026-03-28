import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tavli/features/game/presentation/home_screen.dart';
import 'package:tavli/shared/services/settings_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.initialize();
  });

  Widget createApp() {
    return const ProviderScope(
      child: MaterialApp(home: HomeScreen()),
    );
  }

  group('HomeScreen', () {
    testWidgets('renders tradition title', (tester) async {
      await tester.pumpWidget(createApp());
      // Default tradition is Tavli.
      expect(find.text('Tavli'), findsOneWidget);
    });

    testWidgets('renders variant cards', (tester) async {
      await tester.pumpWidget(createApp());
      // Default tradition (Tavli) has Portes, Plakoto, Fevga.
      expect(find.text('Πόρτες'), findsOneWidget);
      expect(find.text('Πλακωτό'), findsOneWidget);
      expect(find.text('Φεύγα'), findsOneWidget);
    });

    testWidgets('renders play mode cards', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.textContaining('Play Online'), findsOneWidget);
      expect(find.textContaining('Pass & Play'), findsOneWidget);
      expect(find.textContaining('Learn'), findsOneWidget);
    });

    testWidgets('renders bot greeting', (tester) async {
      await tester.pumpWidget(createApp());
      // Default bot is Mikhail — avatar "Μ" should appear.
      expect(find.text('Μ'), findsOneWidget);
      expect(find.text('Mikhail'), findsOneWidget);
    });

    testWidgets('renders marathon mode card', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.textContaining('Marathon'), findsOneWidget);
    });

    testWidgets('renders explore other traditions', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.text('Explore Other Traditions'), findsOneWidget);
    });

    testWidgets('play mode cards have semantic labels', (tester) async {
      await tester.pumpWidget(createApp());
      final semantics = find.byType(Semantics);
      expect(semantics, findsWidgets);
    });
  });
}
