import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/features/game/data/models/board_state.dart';
import 'package:tavli/features/game/data/models/move.dart';
import 'package:tavli/features/game/domain/engine/move_validator.dart';
import 'package:tavli/core/constants/game_constants.dart';

void main() {
  const validator = MoveValidator();

  group('MoveValidator — Normal moves', () {
    test('valid move to empty point', () {
      final pts = List<int>.filled(24, 0);
      pts[10] = 1;
      final state = BoardState(points: pts);

      expect(
        validator.isMoveValid(state, const Move(fromPoint: 10, toPoint: 7, dieUsed: 3)),
        true,
      );
    });

    test('valid move to friendly point', () {
      final pts = List<int>.filled(24, 0);
      pts[10] = 1;
      pts[7] = 2;
      final state = BoardState(points: pts);

      expect(
        validator.isMoveValid(state, const Move(fromPoint: 10, toPoint: 7, dieUsed: 3)),
        true,
      );
    });

    test('invalid move to blocked point (2+ opponent)', () {
      final pts = List<int>.filled(24, 0);
      pts[10] = 1;
      pts[7] = -2;
      final state = BoardState(points: pts);

      expect(
        validator.isMoveValid(state, const Move(fromPoint: 10, toPoint: 7, dieUsed: 3)),
        false,
      );
    });

    test('valid move hitting blot', () {
      final pts = List<int>.filled(24, 0);
      pts[10] = 1;
      pts[7] = -1; // blot
      final state = BoardState(points: pts);

      expect(
        validator.isMoveValid(
          state,
          const Move(fromPoint: 10, toPoint: 7, dieUsed: 3, isHit: true),
        ),
        true,
      );
    });

    test('invalid: no checker at source', () {
      final pts = List<int>.filled(24, 0);
      final state = BoardState(points: pts);

      expect(
        validator.isMoveValid(state, const Move(fromPoint: 10, toPoint: 7, dieUsed: 3)),
        false,
      );
    });

    test('invalid: wrong destination for die value', () {
      final pts = List<int>.filled(24, 0);
      pts[10] = 1;
      final state = BoardState(points: pts);

      // Die is 3 but destination is 5 away
      expect(
        validator.isMoveValid(state, const Move(fromPoint: 10, toPoint: 5, dieUsed: 3)),
        false,
      );
    });

    test('player 2 moves in positive direction', () {
      final pts = List<int>.filled(24, 0);
      pts[5] = -1;
      final state = BoardState(points: pts, activePlayer: 2);

      // P2 moves from 5 to 5+4 = 9
      expect(
        validator.isMoveValid(state, const Move(fromPoint: 5, toPoint: 9, dieUsed: 4)),
        true,
      );
    });

    test('player 2 cannot move backwards', () {
      final pts = List<int>.filled(24, 0);
      pts[5] = -1;
      final state = BoardState(points: pts, activePlayer: 2);

      // P2 cannot move from 5 to 1
      expect(
        validator.isMoveValid(state, const Move(fromPoint: 5, toPoint: 1, dieUsed: 4)),
        false,
      );
    });
  });

  group('MoveValidator — Bar entry', () {
    test('player 1 must enter from bar before other moves', () {
      final pts = List<int>.filled(24, 0);
      pts[10] = 1;
      final state = BoardState(points: pts, bar1: 1);

      // Normal move should be rejected when on bar
      expect(
        validator.isMoveValid(state, const Move(fromPoint: 10, toPoint: 7, dieUsed: 3)),
        false,
      );
    });

    test('player 1 enters to opponent home (24-die)', () {
      final pts = List<int>.filled(24, 0);
      final state = BoardState(points: pts, bar1: 1);

      // Die 3 → enter at point 21 (24-3)
      expect(
        validator.isMoveValid(
          state,
          const Move(fromPoint: GameConstants.barIndex, toPoint: 21, dieUsed: 3),
        ),
        true,
      );
    });

    test('player 1 bar entry to wrong point rejected', () {
      final pts = List<int>.filled(24, 0);
      final state = BoardState(points: pts, bar1: 1);

      expect(
        validator.isMoveValid(
          state,
          const Move(fromPoint: GameConstants.barIndex, toPoint: 20, dieUsed: 3),
        ),
        false,
      );
    });

    test('player 1 bar entry blocked by opponent', () {
      final pts = List<int>.filled(24, 0);
      pts[21] = -2; // blocked
      final state = BoardState(points: pts, bar1: 1);

      expect(
        validator.isMoveValid(
          state,
          const Move(fromPoint: GameConstants.barIndex, toPoint: 21, dieUsed: 3),
        ),
        false,
      );
    });

    test('player 2 enters to points 0-5 (die-1)', () {
      final pts = List<int>.filled(24, 0);
      final state = BoardState(points: pts, bar2: 1, activePlayer: 2);

      // Die 4 → enter at point 3 (4-1)
      expect(
        validator.isMoveValid(
          state,
          const Move(fromPoint: GameConstants.barIndex, toPoint: 3, dieUsed: 4),
        ),
        true,
      );
    });

    test('player 2 bar entry blocked', () {
      final pts = List<int>.filled(24, 0);
      pts[3] = 3; // P1 occupies with 3 checkers
      final state = BoardState(points: pts, bar2: 1, activePlayer: 2);

      expect(
        validator.isMoveValid(
          state,
          const Move(fromPoint: GameConstants.barIndex, toPoint: 3, dieUsed: 4),
        ),
        false,
      );
    });

    test('bar entry with die 1: P1 enters at 23', () {
      final pts = List<int>.filled(24, 0);
      final state = BoardState(points: pts, bar1: 1);

      expect(
        validator.isMoveValid(
          state,
          const Move(fromPoint: GameConstants.barIndex, toPoint: 23, dieUsed: 1),
        ),
        true,
      );
    });

    test('bar entry with die 6: P1 enters at 18', () {
      final pts = List<int>.filled(24, 0);
      final state = BoardState(points: pts, bar1: 1);

      expect(
        validator.isMoveValid(
          state,
          const Move(fromPoint: GameConstants.barIndex, toPoint: 18, dieUsed: 6),
        ),
        true,
      );
    });
  });

  group('MoveValidator — Bearing off', () {
    test('exact die bears off', () {
      final pts = List<int>.filled(24, 0);
      pts[2] = 1;  // P1 on 3-point
      final state = BoardState(points: pts);

      expect(
        validator.isMoveValid(
          state,
          const Move(fromPoint: 2, toPoint: GameConstants.bearOffIndex, dieUsed: 3),
        ),
        true,
      );
    });

    test('cannot bear off if not all in home', () {
      final pts = List<int>.filled(24, 0);
      pts[2] = 1;
      pts[10] = 1; // checker outside home
      final state = BoardState(points: pts);

      expect(
        validator.isMoveValid(
          state,
          const Move(fromPoint: 2, toPoint: GameConstants.bearOffIndex, dieUsed: 3),
        ),
        false,
      );
    });

    test('higher die bears off when no checker on higher point', () {
      final pts = List<int>.filled(24, 0);
      pts[2] = 1; // 3-point only
      final state = BoardState(points: pts);

      // Die 5 can bear off from 3-point since no checkers on 4 or 5-point
      expect(
        validator.isMoveValid(
          state,
          const Move(fromPoint: 2, toPoint: GameConstants.bearOffIndex, dieUsed: 5),
        ),
        true,
      );
    });

    test('higher die cannot bear off when checker on higher point exists', () {
      final pts = List<int>.filled(24, 0);
      pts[2] = 1; // 3-point
      pts[4] = 1; // 5-point — higher point occupied
      final state = BoardState(points: pts);

      // Die 5 cannot bear off from 3-point when 5-point has a checker
      expect(
        validator.isMoveValid(
          state,
          const Move(fromPoint: 2, toPoint: GameConstants.bearOffIndex, dieUsed: 5),
        ),
        false,
      );
    });

    test('lower die cannot bear off (must move within home)', () {
      final pts = List<int>.filled(24, 0);
      pts[4] = 1; // 5-point
      final state = BoardState(points: pts);

      // Die 2 cannot bear off from 5-point (need exact 5 or higher)
      expect(
        validator.isMoveValid(
          state,
          const Move(fromPoint: 4, toPoint: GameConstants.bearOffIndex, dieUsed: 2),
        ),
        false,
      );
    });

    test('player 2 exact bear off', () {
      final pts = List<int>.filled(24, 0);
      pts[21] = -1; // P2 on their 3-point (24-21=3)
      final state = BoardState(points: pts, activePlayer: 2);

      expect(
        validator.isMoveValid(
          state,
          const Move(fromPoint: 21, toPoint: GameConstants.bearOffIndex, dieUsed: 3),
        ),
        true,
      );
    });

    test('player 2 higher die bear off', () {
      final pts = List<int>.filled(24, 0);
      pts[21] = -1; // P2 3-point, no checkers on 1-pt or 2-pt (22, 23)
      final state = BoardState(points: pts, activePlayer: 2);

      expect(
        validator.isMoveValid(
          state,
          const Move(fromPoint: 21, toPoint: GameConstants.bearOffIndex, dieUsed: 5),
        ),
        true,
      );
    });

    test('player 2 higher die blocked by higher point', () {
      final pts = List<int>.filled(24, 0);
      pts[21] = -1; // P2 3-point
      pts[20] = -1; // P2 4-point (closer to home → higher for P2)
      // Wait, for P2 higher means closer to index 18.
      // P2 home is 18-23. exactDie = 24 - fromPoint.
      // Point 21: exactDie = 3. Point 20: exactDie = 4.
      // To bear off from 21 with die 5: need no checkers on points
      // with smaller index (20, 19, 18) — those are "higher" points for P2.
      final state = BoardState(points: pts, activePlayer: 2);

      expect(
        validator.isMoveValid(
          state,
          const Move(fromPoint: 21, toPoint: GameConstants.bearOffIndex, dieUsed: 5),
        ),
        false, // point 20 has a checker
      );
    });

    test('bear off from 1-point with die 1', () {
      final pts = List<int>.filled(24, 0);
      pts[0] = 1;
      final state = BoardState(points: pts);

      expect(
        validator.isMoveValid(
          state,
          const Move(fromPoint: 0, toPoint: GameConstants.bearOffIndex, dieUsed: 1),
        ),
        true,
      );
    });

    test('bear off from 6-point with die 6', () {
      final pts = List<int>.filled(24, 0);
      pts[5] = 1;
      final state = BoardState(points: pts);

      expect(
        validator.isMoveValid(
          state,
          const Move(fromPoint: 5, toPoint: GameConstants.bearOffIndex, dieUsed: 6),
        ),
        true,
      );
    });
  });
}
