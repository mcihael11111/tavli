import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/core/constants/game_constants.dart';
import 'package:tavli/features/game/data/models/board_state.dart';
import 'package:tavli/features/game/data/models/dice_roll.dart';
import 'package:tavli/features/game/domain/engine/game_engine.dart';
import 'package:tavli/features/game/domain/engine/move_generator.dart';

/// End-to-end simulation: play N random games to completion using only the
/// engine's own move generator. Asserts the rule invariants the user flagged
/// for QA — bear-off correctness and win/loss detection — across many random
/// trajectories so we catch off-by-one bugs the hand-rolled fixtures miss.
///
/// "Random" here picks a uniformly random legal turn each ply. Games converge
/// quickly with random play — typical length 80-150 plies — so 4 full games
/// finish in well under a second.
void main() {
  test('4 random games each complete with a valid winner', () {
    const generator = MoveGenerator();
    const engine = GameEngine();

    for (int gameNum = 1; gameNum <= 4; gameNum++) {
      // Fixed seeds keep failures reproducible.
      final rng = Random(0xBEEF + gameNum);
      var board = BoardState.initial();
      var ply = 0;
      const maxPlies = 1000;

      while (!engine.isGameOver(board) && ply < maxPlies) {
        final roll = DiceRoll(
          die1: rng.nextInt(6) + 1,
          die2: rng.nextInt(6) + 1,
        );

        final turns = generator.generateAllLegalTurns(board, roll);
        if (turns.isNotEmpty) {
          final chosen = turns[rng.nextInt(turns.length)];
          for (final move in chosen.moves) {
            board = engine.applyMove(board, move);

            // Invariant: total checkers per player is always 15.
            final p1Total = _checkerCount(board, 1);
            final p2Total = _checkerCount(board, 2);
            expect(p1Total, GameConstants.checkersPerPlayer,
                reason: 'P1 checkers conserved (game $gameNum, ply $ply)');
            expect(p2Total, GameConstants.checkersPerPlayer,
                reason: 'P2 checkers conserved (game $gameNum, ply $ply)');

            // Invariant: borne-off counts never exceed 15.
            expect(board.borneOff1, lessThanOrEqualTo(15));
            expect(board.borneOff2, lessThanOrEqualTo(15));

            if (engine.isGameOver(board)) break;
          }
        }
        board = engine.endTurn(board);
        ply++;
      }

      expect(ply, lessThan(maxPlies),
          reason: 'game $gameNum did not converge within $maxPlies plies');
      expect(engine.isGameOver(board), true,
          reason: 'game $gameNum stopped without a winner');

      // Invariant: exactly one side reached 15 borne off.
      final p1Won = board.borneOff1 == GameConstants.checkersPerPlayer;
      final p2Won = board.borneOff2 == GameConstants.checkersPerPlayer;
      expect(p1Won ^ p2Won, true,
          reason: 'game $gameNum has ambiguous winner');

      // Invariant: getResult agrees with isGameOver and names the winner.
      final result = engine.getResult(board);
      expect(result, isNotNull, reason: 'game $gameNum has no result');
      final expectedWinner = p1Won ? 1 : 2;
      expect(result!.winner, expectedWinner,
          reason: 'game $gameNum result.winner mismatch');
    }
  });

  test('forced-bearoff mid-board: borne-off counter increments correctly', () {
    // Pin all of P1's checkers into the home board (points 0-5), then bear off
    // every one and verify borneOff1 reaches 15 and game ends exactly there.
    const engine = GameEngine();
    const generator = MoveGenerator();

    final initial = BoardState(
      points: const [
        2, 3, 3, 3, 2, 2,  // P1 home (15 total)
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, -15, // P2 stack on point 24
      ],
      activePlayer: 1,
      bar1: 0, bar2: 0,
      borneOff1: 0, borneOff2: 0,
    );

    var board = initial;
    final rng = Random(1);
    int safety = 0;
    while (board.borneOff1 < GameConstants.checkersPerPlayer && safety < 500) {
      final roll = DiceRoll(die1: rng.nextInt(6) + 1, die2: rng.nextInt(6) + 1);
      final turns = generator.generateAllLegalTurns(board, roll);
      if (turns.isNotEmpty) {
        // Greedy: pick the turn with the most bear-offs.
        turns.sort((a, b) {
          final ba = a.moves.where((m) => m.isBearOff).length;
          final bb = b.moves.where((m) => m.isBearOff).length;
          return bb.compareTo(ba);
        });
        for (final move in turns.first.moves) {
          board = engine.applyMove(board, move);
        }
      }
      board = board.copyWith(activePlayer: 1); // skip P2's turn — they're frozen
      safety++;
    }

    expect(board.borneOff1, 15);
    expect(engine.isGameOver(board), true);
    final r = engine.getResult(board);
    expect(r?.winner, 1);
  });
}

int _checkerCount(BoardState s, int player) {
  int total = 0;
  for (final v in s.points) {
    if (player == 1 && v > 0) total += v;
    if (player == 2 && v < 0) total += -v;
  }
  total += player == 1 ? s.bar1 : s.bar2;
  total += player == 1 ? s.borneOff1 : s.borneOff2;
  return total;
}
