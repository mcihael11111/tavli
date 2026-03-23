import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/features/game/data/models/board_state.dart';
import 'package:tavli/features/game/data/models/dice_roll.dart';
import 'package:tavli/features/game/data/models/game_result.dart';
import 'package:tavli/features/game/domain/engine/game_engine.dart';
import 'package:tavli/features/game/domain/engine/move_generator.dart';
import 'package:tavli/features/ai/engine/ai_player.dart';
import 'package:tavli/features/ai/difficulty/difficulty_level.dart';

/// Integration test: simulate full games from start to finish.
void main() {
  const engine = GameEngine();
  const generator = MoveGenerator();

  group('Full game simulation', () {
    test('two AIs can play a complete game to conclusion', () {
      final rng = Random(123);
      final ai1 = AiPlayer(rng: Random(456));
      final ai2 = AiPlayer(rng: Random(789));

      var state = BoardState.initial();
      int turnCount = 0;
      const maxTurns = 1000; // safety limit — some games go long

      while (!engine.isGameOver(state) && turnCount < maxTurns) {
        final roll = DiceRoll.random(rng);
        final player = state.activePlayer;
        final ai = player == 1 ? ai1 : ai2;
        const difficulty = DifficultyLevel.medium;

        final turn = ai.selectTurn(state, roll, difficulty);
        if (turn != null) {
          state = engine.applyMoves(state, turn.moves);
        }

        state = engine.endTurn(state);
        turnCount++;
      }

      expect(engine.isGameOver(state), true,
          reason: 'Game should finish within $maxTurns turns');

      final result = engine.getResult(state);
      expect(result, isNotNull);
      expect(result!.winner, anyOf(1, 2));
      expect(result.points, greaterThan(0));
    });

    test('game preserves checker count invariant throughout', () {
      final rng = Random(42);
      final ai = AiPlayer(rng: Random(99));

      var state = BoardState.initial();
      int turnCount = 0;

      while (!engine.isGameOver(state) && turnCount < 1000) {
        // Verify invariant: total checkers always = 30.
        final total = _totalCheckers(state);
        expect(total, 30,
            reason: 'Turn $turnCount: total checkers should be 30, got $total');

        final roll = DiceRoll.random(rng);
        final turn = ai.selectTurn(state, roll, DifficultyLevel.easy);
        if (turn != null) {
          state = engine.applyMoves(state, turn.moves);
        }
        state = engine.endTurn(state);
        turnCount++;
      }

      // Final check.
      expect(_totalCheckers(state), 30);
    });

    test('AI at every difficulty can complete a game', () {
      for (final difficulty in DifficultyLevel.values) {
        final rng = Random(difficulty.index * 100);
        final ai = AiPlayer(rng: Random(difficulty.index * 200));

        var state = BoardState.initial();
        int turnCount = 0;

        while (!engine.isGameOver(state) && turnCount < 500) {
          final roll = DiceRoll.random(rng);
          final turn = ai.selectTurn(state, roll, difficulty);
          if (turn != null) {
            state = engine.applyMoves(state, turn.moves);
          }
          state = engine.endTurn(state);
          turnCount++;
        }

        expect(engine.isGameOver(state), true,
            reason: '${difficulty.englishName} AI should finish a game');
      }
    });

    test('game result types are correctly detected', () {
      // Single game: both have borne off.
      final singleState = BoardState(
        points: List<int>.filled(24, 0),
        borneOff1: 15, borneOff2: 5,
      );
      final singleResult = engine.getResult(singleState);
      expect(singleResult?.type, GameResultType.single);

      // Gammon: loser has 0 borne off, not in winner's home or bar.
      final gammonPts = List<int>.filled(24, 0);
      gammonPts[12] = -15;
      final gammonState = BoardState(
        points: gammonPts, borneOff1: 15, borneOff2: 0,
      );
      final gammonResult = engine.getResult(gammonState);
      expect(gammonResult?.type, GameResultType.gammon);

      // Backgammon: loser on bar.
      final bgPts = List<int>.filled(24, 0);
      bgPts[12] = -14;
      final bgState = BoardState(
        points: bgPts, borneOff1: 15, borneOff2: 0, bar2: 1,
      );
      final bgResult = engine.getResult(bgState);
      expect(bgResult?.type, GameResultType.backgammon);
    });

    test('doubling cube multiplies game result correctly', () {
      final state = BoardState(
        points: List<int>.filled(24, 0),
        borneOff1: 15, borneOff2: 5, doublingCubeValue: 8,
      );
      final result = engine.getResult(state)!;
      expect(result.points, 8); // single × 8
    });

    test('all opening rolls produce legal turns', () {
      final state = BoardState.initial();
      for (int d1 = 1; d1 <= 6; d1++) {
        for (int d2 = 1; d2 <= 6; d2++) {
          final roll = DiceRoll(die1: d1, die2: d2);
          final turns = generator.generateAllLegalTurns(state, roll);
          expect(turns, isNotEmpty,
              reason: 'Roll $d1-$d2 should have legal turns from starting position');
        }
      }
    });
  });
}

int _totalCheckers(BoardState state) {
  int total = state.bar1 + state.bar2 + state.borneOff1 + state.borneOff2;
  for (int i = 0; i < 24; i++) {
    total += state.points[i].abs();
  }
  return total;
}
