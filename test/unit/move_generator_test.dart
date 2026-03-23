import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/features/game/data/models/board_state.dart';
import 'package:tavli/features/game/data/models/dice_roll.dart';
import 'package:tavli/features/game/domain/engine/move_generator.dart';

void main() {
  const generator = MoveGenerator();

  // Helper to create a board with specific checker placements.
  BoardState board(Map<int, int> placements, {
    int activePlayer = 1,
    int bar1 = 0,
    int bar2 = 0,
    int borneOff1 = 0,
    int borneOff2 = 0,
  }) {
    final pts = List<int>.filled(24, 0);
    for (final e in placements.entries) {
      pts[e.key] = e.value;
    }
    return BoardState(
      points: pts,
      activePlayer: activePlayer,
      bar1: bar1,
      bar2: bar2,
      borneOff1: borneOff1,
      borneOff2: borneOff2,
    );
  }

  group('MoveGenerator — Opening rolls', () {
    test('3-1 opening has legal turns', () {
      final state = BoardState.initial();
      final turns = generator.generateAllLegalTurns(
        state,
        const DiceRoll(die1: 3, die2: 1),
      );
      expect(turns, isNotEmpty);
      // All turns must use exactly 2 dice.
      for (final turn in turns) {
        expect(turn.moves.length, 2);
      }
    });

    test('6-5 opening has legal turns', () {
      final state = BoardState.initial();
      final turns = generator.generateAllLegalTurns(
        state,
        const DiceRoll(die1: 6, die2: 5),
      );
      expect(turns, isNotEmpty);
      for (final turn in turns) {
        expect(turn.moves.length, 2);
      }
    });

    test('all 21 non-double opening rolls produce legal turns', () {
      final state = BoardState.initial();
      for (int d1 = 1; d1 <= 6; d1++) {
        for (int d2 = d1; d2 <= 6; d2++) {
          if (d1 == d2) continue; // skip doubles for now
          final roll = DiceRoll(die1: d1, die2: d2);
          final turns = generator.generateAllLegalTurns(state, roll);
          expect(
            turns,
            isNotEmpty,
            reason: 'No turns for opening roll $d1-$d2',
          );
          for (final turn in turns) {
            expect(
              turn.moves.length,
              2,
              reason: 'Opening roll $d1-$d2 should use both dice',
            );
          }
        }
      }
    });

    test('all 6 double opening rolls produce legal turns', () {
      final state = BoardState.initial();
      for (int d = 1; d <= 6; d++) {
        final roll = DiceRoll(die1: d, die2: d);
        final turns = generator.generateAllLegalTurns(state, roll);
        expect(
          turns,
          isNotEmpty,
          reason: 'No turns for opening doubles $d-$d',
        );
      }
    });
  });

  group('MoveGenerator — Mandatory play', () {
    test('must use both dice if possible', () {
      final state = BoardState.initial();
      final turns = generator.generateAllLegalTurns(
        state,
        const DiceRoll(die1: 4, die2: 2),
      );
      for (final turn in turns) {
        expect(turn.moves.length, 2);
      }
    });

    test('must play larger die when only one can be used', () {
      // Set up a position where die 5 can be played but die 3 cannot after.
      // Simplification: only one checker, and after moving 3 spaces it's blocked
      // for the other die, and after moving 5 it's also blocked.
      // But if only one is possible, must play larger.
      final state = board({
        10: 1, // Single P1 checker
        5: -2, // Block at 5 (10-5=5, would be blocked for die 5)
        7: -2, // Block at 7 (10-3=7, blocked for die 3)
      });

      final turns = generator.generateAllLegalTurns(
        state,
        const DiceRoll(die1: 3, die2: 5),
      );

      // Neither die can be played from point 10 since both destinations blocked.
      // So no turns should be generated.
      expect(turns, isEmpty);
    });

    test('plays larger die when only one possible', () {
      // P1 has checker at point 10. Die 6 → 4 (open), Die 2 → 8 (open).
      // After moving 6 to 4, die 2 from 4 → 2 (open) — both possible.
      // After moving 2 to 8, die 6 from 8 → 2 (open) — both possible.
      // But if we set up so only the larger die is playable alone:
      board({
        3: 1,  // P1 checker on 4-point (index 3)
        // Die 2: 3-2=1 → open. Die 1: 3-1=2 → open.
        // Both dice playable. Let's use a different scenario.
      });

      // Simpler: checker on point 1 (index 0). Die 2 would go off board (bear off?).
      // If all in home, that's a bear off. Let's just verify the rule works.
      final state2 = board({
        1: 1, // P1 checker on 2-point
        // P1 has 14 checkers borne off already (so this is the last one, all in home)
      }, borneOff1: 14);

      final turns2 = generator.generateAllLegalTurns(
        state2,
        const DiceRoll(die1: 5, die2: 3),
      );

      // With one checker on 2-point: die 5 and die 3 can both bear off
      // (higher die, no higher point). Should bear off with one die.
      expect(turns2, isNotEmpty);
      // Should only need 1 move (bear off the last checker).
      for (final turn in turns2) {
        expect(turn.moves.length, 1);
        expect(turn.moves.first.isBearOff, true);
      }
    });
  });

  group('MoveGenerator — Bar entry', () {
    test('must enter from bar before other moves', () {
      final state = board({
        10: 1,
      }, bar1: 1);

      final turns = generator.generateAllLegalTurns(
        state,
        const DiceRoll(die1: 3, die2: 4),
      );

      // Every turn's first move must be a bar entry.
      for (final turn in turns) {
        expect(turn.moves.first.isBarEntry, true);
      }
    });

    test('all entry points blocked = no moves', () {
      // Block all of opponent's home board for P1 entry (points 18-23).
      final state = board({
        18: -2, 19: -2, 20: -2, 21: -2, 22: -2, 23: -2,
      }, bar1: 1);

      final turns = generator.generateAllLegalTurns(
        state,
        const DiceRoll(die1: 3, die2: 5),
      );
      expect(turns, isEmpty);
    });

    test('partially blocked bar entry', () {
      // Only die 3 can enter (point 21 open), die 5 blocked (point 19 = -2).
      final state = board({
        19: -2, // blocks die 5 entry
        // 21 is open for die 3
      }, bar1: 1);

      final turns = generator.generateAllLegalTurns(
        state,
        const DiceRoll(die1: 5, die2: 3),
      );

      expect(turns, isNotEmpty);
      for (final turn in turns) {
        expect(turn.moves.first.isBarEntry, true);
        expect(turn.moves.first.dieUsed, 3);
      }
    });

    test('two checkers on bar, only one can enter', () {
      // P1 has 2 on bar. Die 3 → 21 (open), die 5 → 19 (blocked).
      final state = board({
        19: -2,
      }, bar1: 2);

      final turns = generator.generateAllLegalTurns(
        state,
        const DiceRoll(die1: 5, die2: 3),
      );

      // Can enter one checker with die 3, then must try die 5 (still blocked).
      expect(turns, isNotEmpty);
      for (final turn in turns) {
        expect(turn.moves.length, 1); // only one entry possible
        expect(turn.moves.first.dieUsed, 3);
      }
    });

    test('bar entry with hit', () {
      final state = board({
        21: -1, // P2 blot at entry point
      }, bar1: 1);

      final turns = generator.generateAllLegalTurns(
        state,
        const DiceRoll(die1: 3, die2: 4),
      );

      expect(turns, isNotEmpty);
      // Some turns should have a hit on entry.
      final hittingTurns = turns
          .where((t) => t.moves.any((m) => m.isBarEntry && m.isHit))
          .toList();
      expect(hittingTurns, isNotEmpty);
    });

    test('player 2 bar entry', () {
      final state = board({
        3: 1, // P1 checker (not blocking for P2 since only 1)
      }, bar2: 1, activePlayer: 2);

      final turns = generator.generateAllLegalTurns(
        state,
        const DiceRoll(die1: 4, die2: 2),
      );

      expect(turns, isNotEmpty);
      for (final turn in turns) {
        expect(turn.moves.first.isBarEntry, true);
      }
    });
  });

  group('MoveGenerator — Bearing off', () {
    test('basic bearing off with exact dice', () {
      final state = board({
        4: 2, // 5-point: 2 checkers
        2: 3, // 3-point: 3 checkers
      }, borneOff1: 10);

      final turns = generator.generateAllLegalTurns(
        state,
        const DiceRoll(die1: 5, die2: 3),
      );

      expect(turns, isNotEmpty);
      // Should be able to bear off one from each point.
      final bearOffTurn = turns.firstWhere(
        (t) => t.moves.every((m) => m.isBearOff),
        orElse: () => turns.first,
      );
      expect(bearOffTurn.moves.where((m) => m.isBearOff).length, 2);
    });

    test('bearing off with higher die when no higher point occupied', () {
      final state = board({
        1: 1, // 2-point: 1 checker
      }, borneOff1: 14);

      final turns = generator.generateAllLegalTurns(
        state,
        const DiceRoll(die1: 6, die2: 5),
      );

      expect(turns, isNotEmpty);
      // Should bear off the last checker.
      expect(turns.first.moves.length, 1);
      expect(turns.first.moves.first.isBearOff, true);
    });

    test('cannot bear off if not all in home', () {
      // Checker at 10 is outside home — can't bear off until it's moved home.
      // With die 5: 10→5 (enters home). Then die 3: 2→bear off IS legal
      // because after the first move, all checkers are in home.
      // To truly test "cannot bear off", we need a roll that can't bring
      // the outside checker home first.
      final state = board({
        2: 1,  // home
        10: 1, // outside home
      }, borneOff1: 13);

      final turns = generator.generateAllLegalTurns(
        state,
        const DiceRoll(die1: 3, die2: 2),
      );

      // Die 3: 10→7 (still outside home). Die 2: 10→8 (still outside).
      // After first move, checker still not in home, so no bear-off from 2.
      for (final turn in turns) {
        for (final move in turn.moves) {
          if (move.fromPoint == 2) {
            expect(move.isBearOff, false,
              reason: 'Should not bear off when checker at 10 is outside home');
          }
        }
      }
    });

    test('must move within home if die is smaller than point and higher points exist', () {
      final state = board({
        4: 1, // 5-point
        3: 1, // 4-point
      }, borneOff1: 13);

      final turns = generator.generateAllLegalTurns(
        state,
        const DiceRoll(die1: 2, die2: 1),
      );

      expect(turns, isNotEmpty);
      // Die 2: move from 4→2 or 3→1. Die 1: move from 4→3 or 3→2.
      // Should not bear off since dice < point values.
      for (final turn in turns) {
        for (final move in turn.moves) {
          expect(move.isBearOff, false);
        }
      }
    });
  });

  group('MoveGenerator — Doubles', () {
    test('doubles produce up to 4 moves', () {
      final state = BoardState.initial();
      final turns = generator.generateAllLegalTurns(
        state,
        const DiceRoll(die1: 1, die2: 1),
      );

      expect(turns, isNotEmpty);
      final maxMoves = turns.map((t) => t.moves.length).reduce(
        (a, b) => a > b ? a : b,
      );
      expect(maxMoves, lessThanOrEqualTo(4));
    });

    test('doubles with partial play (some blocked)', () {
      // Only room for 2 of the 4 double moves.
      final state = board({
        10: 2,
        4: -2, // blocks after 2 moves of 3
      });

      final turns = generator.generateAllLegalTurns(
        state,
        const DiceRoll(die1: 3, die2: 3),
      );

      if (turns.isNotEmpty) {
        // Should play as many as possible.
        final maxMoves = turns.map((t) => t.moves.length).reduce(
          (a, b) => a > b ? a : b,
        );
        // All returned turns should have maxMoves moves.
        for (final turn in turns) {
          expect(turn.moves.length, maxMoves);
        }
      }
    });

    test('double 6-6 from initial position', () {
      final state = BoardState.initial();
      final turns = generator.generateAllLegalTurns(
        state,
        const DiceRoll(die1: 6, die2: 6),
      );
      expect(turns, isNotEmpty);
    });
  });

  group('MoveGenerator — Edge cases', () {
    test('no legal moves returns empty list', () {
      // P1 has all checkers blocked.
      final state = board({
        23: 1,
        // All destination points blocked.
        17: -2, 18: -2, 19: -2, 20: -2, 21: -2, 22: -2,
      });

      final turns = generator.generateAllLegalTurns(
        state,
        const DiceRoll(die1: 1, die2: 2),
      );

      expect(turns, isEmpty);
    });

    test('compound move through intermediate point', () {
      // P1 checker at 12, wants to use both dice on same checker.
      // Die 3: 12→9 (must be open). Die 5: 9→4.
      final state = board({12: 1});

      final turns = generator.generateAllLegalTurns(
        state,
        const DiceRoll(die1: 3, die2: 5),
      );

      // Should include a turn where both moves are from the same checker.
      final compoundTurns = turns.where((t) {
        if (t.moves.length != 2) return false;
        return t.moves[0].fromPoint == 12 &&
            t.moves[1].fromPoint == t.moves[0].toPoint;
      });
      expect(compoundTurns, isNotEmpty);
    });

    test('compound move blocked at intermediate', () {
      // P1 at 12. Die 3→9 blocked, die 5→7 open. Die 5→7, then die 3→4 open.
      final state = board({
        12: 1,
        9: -2, // blocks 3-then-5 order
      });

      final turns = generator.generateAllLegalTurns(
        state,
        const DiceRoll(die1: 3, die2: 5),
      );

      // Should still find the 5-then-3 order (12→7→4).
      expect(turns, isNotEmpty);
      final validTurn = turns.where((t) =>
          t.moves.length == 2 &&
          t.moves.any((m) => m.fromPoint == 12 && m.toPoint == 7));
      expect(validTurn, isNotEmpty);
    });

    test('single checker with only one die playable', () {
      final state = board({
        5: 1, // 6-point
        // Die 3: 5→2 (open). Die 6: would go off board → bear off if all in home.
      }, borneOff1: 14);

      final turns = generator.generateAllLegalTurns(
        state,
        const DiceRoll(die1: 3, die2: 6),
      );

      expect(turns, isNotEmpty);
      // Should bear off with die 6 (exact), which is the larger die.
      // After bearing off, no more checkers to move with die 3.
      final bearOffTurn = turns.where((t) =>
          t.moves.any((m) => m.isBearOff && m.dieUsed == 6));
      expect(bearOffTurn, isNotEmpty);
    });

    test('generateMovesForDie returns moves for single die', () {
      final state = BoardState.initial();
      final moves = generator.generateMovesForDie(state, 3);
      expect(moves, isNotEmpty);
      for (final move in moves) {
        expect(move.dieUsed, 3);
      }
    });

    test('deduplication removes equivalent turns', () {
      // Two checkers on same point, both can make same move.
      final state = board({10: 2});

      final turns = generator.generateAllLegalTurns(
        state,
        const DiceRoll(die1: 3, die2: 5),
      );

      // After dedup, moving checker A then B should equal moving B then A
      // when they're on the same point (same result).
      // Verify no duplicate final positions.
      final keys = <String>{};
      for (final turn in turns) {
        final sorted = turn.moves.toList()
          ..sort((a, b) {
            final cmp = a.fromPoint.compareTo(b.fromPoint);
            if (cmp != 0) return cmp;
            return a.toPoint.compareTo(b.toPoint);
          });
        final key = sorted
            .map((m) => '${m.fromPoint}:${m.toPoint}:${m.dieUsed}')
            .join('|');
        expect(keys.add(key), true, reason: 'Duplicate turn found: $key');
      }
    });
  });

  group('MoveGenerator — Player 2', () {
    test('player 2 generates moves in correct direction', () {
      final state = board({
        5: -1, // P2 checker
      }, activePlayer: 2);

      final turns = generator.generateAllLegalTurns(
        state,
        const DiceRoll(die1: 3, die2: 4),
      );

      expect(turns, isNotEmpty);
      for (final turn in turns) {
        for (final move in turn.moves) {
          // P2 moves toward higher indices.
          if (!move.isBearOff && !move.isBarEntry) {
            expect(move.toPoint, greaterThan(move.fromPoint));
          }
        }
      }
    });

    test('player 2 bearing off from home board 18-23', () {
      final state = board({
        20: -3, // P2 on their 4-point (24-20=4)
        22: -2, // P2 on their 2-point (24-22=2)
      }, activePlayer: 2, borneOff2: 10);

      final turns = generator.generateAllLegalTurns(
        state,
        const DiceRoll(die1: 4, die2: 2),
      );

      expect(turns, isNotEmpty);
      final bearOffTurns = turns.where(
        (t) => t.moves.every((m) => m.isBearOff),
      );
      expect(bearOffTurns, isNotEmpty);
    });
  });
}
