import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/features/game/presentation/widgets/turn_handoff_pill.dart';

void main() {
  testWidgets('shows player turn label', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: TurnHandoffPill(
          isPlayerTurn: true,
          isBotMoving: false,
          botName: 'Mikhail',
        ),
      ),
    ));
    expect(find.text('Your turn'), findsOneWidget);
  });

  testWidgets('shows bot thinking label', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: TurnHandoffPill(
          isPlayerTurn: false,
          isBotMoving: false,
          botName: 'Mikhail',
        ),
      ),
    ));
    expect(find.text('Mikhail thinking…'), findsOneWidget);
  });

  testWidgets('shows bot moving label', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: TurnHandoffPill(
          isPlayerTurn: false,
          isBotMoving: true,
          botName: 'Mikhail',
        ),
      ),
    ));
    expect(find.text('Mikhail moving…'), findsOneWidget);
  });
}
