import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/features/game/data/models/board_state.dart';

void main() {
  group('BoardState', () {
    group('initial setup', () {
      test('has correct total checkers for player 1', () {
        final state = BoardState.initial();
        int total = state.bar1 + state.borneOff1;
        for (int i = 0; i < 24; i++) {
          if (state.points[i] > 0) total += state.points[i];
        }
        expect(total, 15);
      });

      test('has correct total checkers for player 2', () {
        final state = BoardState.initial();
        int total = state.bar2 + state.borneOff2;
        for (int i = 0; i < 24; i++) {
          if (state.points[i] < 0) total += -state.points[i];
        }
        expect(total, 15);
      });

      test('player 1 placement: 2 on 24-pt, 5 on 13-pt, 3 on 8-pt, 5 on 6-pt', () {
        final state = BoardState.initial();
        expect(state.points[23], 2);  // 24-point
        expect(state.points[12], 5);  // 13-point
        expect(state.points[7], 3);   // 8-point
        expect(state.points[5], 5);   // 6-point
      });

      test('player 2 placement mirrors player 1', () {
        final state = BoardState.initial();
        expect(state.points[0], -2);   // P2's 24-point (P1's 1-point)
        expect(state.points[11], -5);  // P2's 13-point (P1's 12-point)
        expect(state.points[16], -3);  // P2's 8-point (P1's 17-point)
        expect(state.points[18], -5);  // P2's 6-point (P1's 19-point)
      });

      test('no checkers on bar initially', () {
        final state = BoardState.initial();
        expect(state.bar1, 0);
        expect(state.bar2, 0);
      });

      test('no checkers borne off initially', () {
        final state = BoardState.initial();
        expect(state.borneOff1, 0);
        expect(state.borneOff2, 0);
      });

      test('doubling cube starts at 1 in center', () {
        final state = BoardState.initial();
        expect(state.doublingCubeValue, 1);
        expect(state.cubeOwner, isNull);
      });
    });

    group('checkerCount', () {
      test('returns player 1 count on positive points', () {
        final state = BoardState.initial();
        expect(state.checkerCount(23, 1), 2);
        expect(state.checkerCount(12, 1), 5);
      });

      test('returns 0 for player 1 on opponent-occupied points', () {
        final state = BoardState.initial();
        expect(state.checkerCount(0, 1), 0);
        expect(state.checkerCount(11, 1), 0);
      });

      test('returns player 2 count on negative points', () {
        final state = BoardState.initial();
        expect(state.checkerCount(0, 2), 2);
        expect(state.checkerCount(11, 2), 5);
      });
    });

    group('isPointOpen', () {
      test('open for player 1 if <= 1 opponent checker', () {
        final state = BoardState.initial();
        // Point with 0 opponent checkers — open.
        expect(state.isPointOpen(1, 1), true);
        // Point with 2+ opponent checkers — blocked.
        expect(state.isPointOpen(0, 1), false); // -2
        expect(state.isPointOpen(11, 1), false); // -5
      });

      test('open for player 2 if <= 1 player 1 checker', () {
        final state = BoardState.initial();
        expect(state.isPointOpen(1, 2), true);
        expect(state.isPointOpen(23, 2), false); // +2
        expect(state.isPointOpen(5, 2), false);  // +5
      });
    });

    group('isBlot', () {
      test('detects single opponent checker for player 1', () {
        final pts = List<int>.filled(24, 0);
        pts[10] = -1; // single P2 checker
        final state = BoardState(points: pts);
        expect(state.isBlot(10, 1), true);
        expect(state.isBlot(10, 2), false);
      });

      test('not a blot with 2+ checkers', () {
        final pts = List<int>.filled(24, 0);
        pts[10] = -2;
        final state = BoardState(points: pts);
        expect(state.isBlot(10, 1), false);
      });
    });

    group('allInHome', () {
      test('not all in home at start', () {
        final state = BoardState.initial();
        expect(state.allInHome(1), false);
        expect(state.allInHome(2), false);
      });

      test('all in home when only checkers are in home board', () {
        final pts = List<int>.filled(24, 0);
        pts[0] = 5;
        pts[1] = 5;
        pts[2] = 5;
        final state = BoardState(points: pts);
        expect(state.allInHome(1), true);
      });

      test('not all in home with checker on bar', () {
        final pts = List<int>.filled(24, 0);
        pts[0] = 5;
        pts[1] = 5;
        pts[2] = 4;
        final state = BoardState(points: pts, bar1: 1);
        expect(state.allInHome(1), false);
      });

      test('player 2 all in home', () {
        final pts = List<int>.filled(24, 0);
        pts[18] = -5;
        pts[19] = -5;
        pts[20] = -5;
        final state = BoardState(points: pts, activePlayer: 2);
        expect(state.allInHome(2), true);
      });
    });

    group('pipCount', () {
      test('initial pip count for player 1', () {
        final state = BoardState.initial();
        // 2*24 + 5*13 + 3*8 + 5*6 = 48 + 65 + 24 + 30 = 167
        expect(state.pipCount(1), 167);
      });

      test('initial pip count for player 2', () {
        final state = BoardState.initial();
        // 2*24 + 5*13 + 3*8 + 5*6 = 167 (symmetric)
        expect(state.pipCount(2), 167);
      });

      test('bar checkers count as 25 pips', () {
        final pts = List<int>.filled(24, 0);
        final state = BoardState(points: pts, bar1: 1);
        expect(state.pipCount(1), 25);
      });
    });

    group('equality', () {
      test('same state is equal', () {
        final a = BoardState.initial();
        final b = BoardState.initial();
        expect(a, equals(b));
      });

      test('different states are not equal', () {
        final a = BoardState.initial();
        final b = BoardState.initial(activePlayer: 2);
        expect(a, isNot(equals(b)));
      });
    });

    group('copyWith', () {
      test('copies without changes', () {
        final state = BoardState.initial();
        expect(state.copyWith(), equals(state));
      });

      test('copies with bar change', () {
        final state = BoardState.initial();
        final modified = state.copyWith(bar1: 2);
        expect(modified.bar1, 2);
        expect(modified.bar2, 0);
      });
    });
  });
}
