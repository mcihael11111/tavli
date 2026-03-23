import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tavli/features/game/presentation/home_screen.dart';

void main() {
  Widget createApp() {
    return const ProviderScope(
      child: MaterialApp(home: HomeScreen()),
    );
  }

  group('HomeScreen', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.text('TAVLI'), findsOneWidget);
    });

    testWidgets('renders Greek subtitle', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.text('Τ Α Β Λ Ι'), findsOneWidget);
    });

    testWidgets('renders play mode cards', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.text('Play vs Μιχαήλ'), findsOneWidget);
      expect(find.text('Play Online'), findsOneWidget);
      expect(find.text('Pass & Play'), findsOneWidget);
      expect(find.text('Learn to Play'), findsOneWidget);
    });

    testWidgets('renders Mikhail greeting', (tester) async {
      await tester.pumpWidget(createApp());
      // The greeting avatar "Μ" should appear.
      expect(find.text('Μ'), findsOneWidget);
    });

    testWidgets('disabled cards show SOON badge', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.text('SOON'), findsOneWidget); // Play Online
    });

    testWidgets('play mode cards have semantic labels', (tester) async {
      await tester.pumpWidget(createApp());
      // Check that Semantics wrappers exist.
      final semantics = find.byType(Semantics);
      expect(semantics, findsWidgets);
    });
  });
}
