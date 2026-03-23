import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/features/game/data/models/board_state.dart';
import 'package:tavli/features/game/data/models/move.dart';
import 'package:tavli/features/game/data/models/game_result.dart';
import 'package:tavli/features/game/domain/engine/game_engine.dart';
import 'package:tavli/core/constants/game_constants.dart';

void main() {
  late GameEngine engine;

  setUp(() {
    engine = const GameEngine();
  });

  group('applyMove', () {
    test('normal move decrements source and increments destination', () {
      final state = BoardState.initial();
      // P1 moves checker from 12-point (index 12) by 1 → index 11
      // But index 11 has -5 (blocked). Let's move from 7 by 1 → 6.
      // Wait, index 6 is empty. Let's move from 23 by 1 → 22.
      const move = Move(fromPoint: 23, toPoint: 22, dieUsed: 1);
      final result = engine.applyMove(state, move);

      expect(result.points[23], 1); // was 2, now 1
      expect(result.points[22], 1); // was 0, now 1
    });

    test('hitting sends opponent to bar', () {
      final pts = List<int>.filled(24, 0);
      pts[10] = 1;  // P1 checker
      pts[8] = -1;  // P2 blot
      final state = BoardState(points: pts);

      const move = Move(
        fromPoint: 10, toPoint: 8, dieUsed: 2, isHit: true,
      );
      final result = engine.applyMove(state, move);

      expect(result.points[10], 0);
      expect(result.points[8], 1);  // P1 now occupies
      expect(result.bar2, 1);       // P2 checker on bar
    });

    test('bar entry removes from bar and places on board', () {
      final pts = List<int>.filled(24, 0);
      final state = BoardState(points: pts, bar1: 1);

      // P1 enters from bar with die 3 → point 21 (24-3)
      const move = Move(
        fromPoint: GameConstants.barIndex, toPoint: 21, dieUsed: 3,
      );
      final result = engine.applyMove(state, move);

      expect(result.bar1, 0);
      expect(result.points[21], 1);
    });

    test('bear off increments borneOff', () {
      final pts = List<int>.filled(24, 0);
      pts[2] = 1;
      final state = BoardState(points: pts);

      const move = Move(
        fromPoint: 2,
        toPoint: GameConstants.bearOffIndex,
        dieUsed: 3,
      );
      final result = engine.applyMove(state, move);

      expect(result.points[2], 0);
      expect(result.borneOff1, 1);
    });

    test('player 2 bar entry goes to points 0-5', () {
      final pts = List<int>.filled(24, 0);
      final state = BoardState(points: pts, bar2: 1, activePlayer: 2);

      // P2 enters with die 4 → point 3 (die - 1)
      const move = Move(
        fromPoint: GameConstants.barIndex, toPoint: 3, dieUsed: 4,
      );
      final result = engine.applyMove(state, move);

      expect(result.bar2, 0);
      expect(result.points[3], -1);
    });

    test('player 2 bear off', () {
      final pts = List<int>.filled(24, 0);
      pts[20] = -1;
      final state = BoardState(points: pts, activePlayer: 2);

      const move = Move(
        fromPoint: 20,
        toPoint: GameConstants.bearOffIndex,
        dieUsed: 4, // 24-20 = 4
      );
      final result = engine.applyMove(state, move);

      expect(result.points[20], 0);
      expect(result.borneOff2, 1);
    });

    test('bar entry with hit', () {
      final pts = List<int>.filled(24, 0);
      pts[21] = -1; // P2 blot where P1 wants to enter
      final state = BoardState(points: pts, bar1: 1);

      const move = Move(
        fromPoint: GameConstants.barIndex,
        toPoint: 21,
        dieUsed: 3,
        isHit: true,
      );
      final result = engine.applyMove(state, move);

      expect(result.bar1, 0);
      expect(result.bar2, 1);
      expect(result.points[21], 1);
    });
  });

  group('endTurn', () {
    test('switches active player from 1 to 2', () {
      final state = BoardState.initial(activePlayer: 1);
      expect(engine.endTurn(state).activePlayer, 2);
    });

    test('switches active player from 2 to 1', () {
      final state = BoardState.initial(activePlayer: 2);
      expect(engine.endTurn(state).activePlayer, 1);
    });
  });

  group('isGameOver', () {
    test('not over at start', () {
      expect(engine.isGameOver(BoardState.initial()), false);
    });

    test('over when player 1 bears off all 15', () {
      final state = BoardState(
        points: List<int>.filled(24, 0),
        borneOff1: 15,
      );
      expect(engine.isGameOver(state), true);
    });

    test('over when player 2 bears off all 15', () {
      final state = BoardState(
        points: List<int>.filled(24, 0),
        borneOff2: 15,
      );
      expect(engine.isGameOver(state), true);
    });
  });

  group('getResult', () {
    test('returns null when game is not over', () {
      expect(engine.getResult(BoardState.initial()), isNull);
    });

    test('single game when loser has borne off checkers', () {
      final state = BoardState(
        points: List<int>.filled(24, 0),
        borneOff1: 15,
        borneOff2: 3,
      );
      final result = engine.getResult(state)!;
      expect(result.winner, 1);
      expect(result.type, GameResultType.single);
      expect(result.points, 1);
    });

    test('gammon when loser has 0 borne off', () {
      final pts = List<int>.filled(24, 0);
      pts[12] = -15; // all P2 checkers on point 12
      final state = BoardState(
        points: pts,
        borneOff1: 15,
        borneOff2: 0,
      );
      final result = engine.getResult(state)!;
      expect(result.winner, 1);
      expect(result.type, GameResultType.gammon);
      expect(result.points, 2);
    });

    test('backgammon when loser has checker on bar', () {
      final pts = List<int>.filled(24, 0);
      pts[12] = -14;
      final state = BoardState(
        points: pts,
        borneOff1: 15,
        borneOff2: 0,
        bar2: 1,
      );
      final result = engine.getResult(state)!;
      expect(result.winner, 1);
      expect(result.type, GameResultType.backgammon);
      expect(result.points, 3);
    });

    test('backgammon when loser has checker in winner home board', () {
      final pts = List<int>.filled(24, 0);
      pts[3] = -1;   // P2 checker in P1's home (points 0-5)
      pts[12] = -14;
      final state = BoardState(
        points: pts,
        borneOff1: 15,
        borneOff2: 0,
      );
      final result = engine.getResult(state)!;
      expect(result.type, GameResultType.backgammon);
    });

    test('cube value multiplies points', () {
      final state = BoardState(
        points: List<int>.filled(24, 0),
        borneOff1: 15,
        borneOff2: 3,
        doublingCubeValue: 4,
      );
      final result = engine.getResult(state)!;
      expect(result.points, 4); // single × 4
    });

    test('gammon with cube value', () {
      final pts = List<int>.filled(24, 0);
      pts[12] = -15;
      final state = BoardState(
        points: pts,
        borneOff1: 15,
        borneOff2: 0,
        doublingCubeValue: 2,
      );
      final result = engine.getResult(state)!;
      expect(result.points, 4); // gammon(2) × cube(2)
    });

    test('player 2 wins with backgammon', () {
      final pts = List<int>.filled(24, 0);
      pts[20] = 1; // P1 checker in P2's home (18-23)
      pts[12] = 14;
      final state = BoardState(
        points: pts,
        borneOff2: 15,
        borneOff1: 0,
        activePlayer: 2,
      );
      final result = engine.getResult(state)!;
      expect(result.winner, 2);
      expect(result.type, GameResultType.backgammon);
    });
  });

  group('doubling cube', () {
    test('canOfferDouble when cube is centered', () {
      final state = BoardState.initial(activePlayer: 1);
      expect(engine.canOfferDouble(state, 1), true);
      expect(engine.canOfferDouble(state, 2), false);
    });

    test('canOfferDouble when player owns cube', () {
      final state = BoardState.initial(activePlayer: 1).copyWith(
        cubeOwner: 1,
        doublingCubeValue: 2,
      );
      expect(engine.canOfferDouble(state, 1), true);
    });

    test('cannot offer double when opponent owns cube', () {
      final state = BoardState.initial(activePlayer: 1).copyWith(
        cubeOwner: 2,
        doublingCubeValue: 2,
      );
      expect(engine.canOfferDouble(state, 1), false);
    });

    test('acceptDouble doubles the cube value', () {
      final state = BoardState.initial(activePlayer: 1);
      final doubled = engine.acceptDouble(state);
      expect(doubled.doublingCubeValue, 2);
      expect(doubled.cubeOwner, 2); // acceptor owns it
    });

    test('redouble works correctly', () {
      final state = BoardState.initial(activePlayer: 2).copyWith(
        doublingCubeValue: 2,
        cubeOwner: 2,
      );
      final redoubled = engine.acceptDouble(state);
      expect(redoubled.doublingCubeValue, 4);
      expect(redoubled.cubeOwner, 1);
    });
  });
}
