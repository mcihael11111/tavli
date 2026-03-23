import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/features/game/data/models/board_state.dart';
import 'package:tavli/features/game/data/models/game_state.dart';
import 'package:tavli/features/multiplayer/data/game_room.dart';
import 'package:tavli/features/multiplayer/presentation/online_game_state.dart';

void main() {
  group('OnlineGameState', () {
    OnlineGameState makeState({
      int localPlayer = 1,
      int activePlayer = 1,
      GamePhase phase = GamePhase.playerTurnStart,
      DoublingCubeState cube = const DoublingCubeState(),
      String? pendingDouble,
    }) =>
        OnlineGameState(
          gameRoomId: 'test-room',
          localPlayerNumber: localPlayer,
          board: BoardState.initial(activePlayer: activePlayer),
          phase: phase,
          doublingCube: cube,
          pendingDoubleFrom: pendingDouble,
        );

    group('turn detection', () {
      test('isMyTurn when active player matches local player', () {
        final state = makeState(localPlayer: 1, activePlayer: 1);
        expect(state.isMyTurn, isTrue);
        expect(state.isOpponentTurn, isFalse);
      });

      test('isOpponentTurn when active player differs', () {
        final state = makeState(localPlayer: 1, activePlayer: 2);
        expect(state.isMyTurn, isFalse);
        expect(state.isOpponentTurn, isTrue);
      });

      test('works for player 2', () {
        final state = makeState(localPlayer: 2, activePlayer: 2);
        expect(state.isMyTurn, isTrue);
      });
    });

    group('player keys', () {
      test('localPlayerKey is correct for player 1', () {
        final state = makeState(localPlayer: 1);
        expect(state.localPlayerKey, equals('player1'));
        expect(state.opponentPlayerKey, equals('player2'));
      });

      test('localPlayerKey is correct for player 2', () {
        final state = makeState(localPlayer: 2);
        expect(state.localPlayerKey, equals('player2'));
        expect(state.opponentPlayerKey, equals('player1'));
      });
    });

    group('doubling cube', () {
      test('can offer double at turn start with no cube owner', () {
        final state = makeState(
          localPlayer: 1,
          activePlayer: 1,
          phase: GamePhase.playerTurnStart,
        );
        expect(state.canOfferDouble, isTrue);
      });

      test('cannot offer double during moving phase', () {
        final state = makeState(
          localPlayer: 1,
          activePlayer: 1,
          phase: GamePhase.movingCheckers,
        );
        expect(state.canOfferDouble, isFalse);
      });

      test('cannot offer double on opponent turn', () {
        final state = makeState(
          localPlayer: 1,
          activePlayer: 2,
          phase: GamePhase.playerTurnStart,
        );
        expect(state.canOfferDouble, isFalse);
      });

      test('cannot offer double when double is pending', () {
        final state = makeState(
          localPlayer: 1,
          activePlayer: 1,
          phase: GamePhase.playerTurnStart,
          pendingDouble: 'player1',
        );
        expect(state.canOfferDouble, isFalse);
      });

      test('can offer double when cube owner is local player', () {
        final state = makeState(
          localPlayer: 1,
          activePlayer: 1,
          phase: GamePhase.playerTurnStart,
          cube: const DoublingCubeState(value: 2, owner: 'player1'),
        );
        expect(state.canOfferDouble, isTrue);
      });

      test('cannot offer double when cube owned by opponent', () {
        final state = makeState(
          localPlayer: 1,
          activePlayer: 1,
          phase: GamePhase.playerTurnStart,
          cube: const DoublingCubeState(value: 2, owner: 'player2'),
        );
        expect(state.canOfferDouble, isFalse);
      });
    });

    group('copyWith', () {
      test('updates fields correctly', () {
        final state = makeState();
        final updated = state.copyWith(
          opponentName: 'NewName',
          opponentRating: 1500,
          connectionStatus: ConnectionStatus.reconnecting,
        );

        expect(updated.opponentName, equals('NewName'));
        expect(updated.opponentRating, equals(1500));
        expect(updated.connectionStatus, equals(ConnectionStatus.reconnecting));
        expect(updated.gameRoomId, equals('test-room'));
      });

      test('clearRoll sets currentRoll to null', () {
        final state = makeState().copyWith(
          currentRoll: null, // would normally have a DiceRoll
        );
        final cleared = state.copyWith(clearRoll: true);
        expect(cleared.currentRoll, isNull);
      });

      test('clearSelectedPoint clears selection and available moves', () {
        final state = makeState().copyWith(selectedPoint: 5);
        final cleared = state.copyWith(clearSelectedPoint: true);

        expect(cleared.selectedPoint, isNull);
        expect(cleared.availableMovesForSelected, isEmpty);
      });

      test('clearPendingDouble sets pendingDoubleFrom to null', () {
        final state = makeState(pendingDouble: 'player1');
        final cleared = state.copyWith(clearPendingDouble: true);

        expect(cleared.pendingDoubleFrom, isNull);
      });
    });

    group('ConnectionStatus', () {
      test('all values are distinct', () {
        const values = ConnectionStatus.values;
        expect(values.length, equals(4));
        expect(values.toSet().length, equals(4));
      });
    });

    group('OnlineGameParams', () {
      test('equality based on gameRoomId', () {
        const a = OnlineGameParams(
          gameRoomId: 'room1',
          localPlayerNumber: 1,
          localPlayerUid: 'uid1',
        );
        const b = OnlineGameParams(
          gameRoomId: 'room1',
          localPlayerNumber: 2,
          localPlayerUid: 'uid2',
        );
        expect(a, equals(b)); // Same room ID = equal
      });

      test('inequality for different rooms', () {
        const a = OnlineGameParams(
          gameRoomId: 'room1',
          localPlayerNumber: 1,
          localPlayerUid: 'uid1',
        );
        const b = OnlineGameParams(
          gameRoomId: 'room2',
          localPlayerNumber: 1,
          localPlayerUid: 'uid1',
        );
        expect(a, isNot(equals(b)));
      });
    });
  });
}
