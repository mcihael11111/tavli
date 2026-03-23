import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/features/multiplayer/data/game_room.dart';

void main() {
  group('GameRoom', () {
    final now = DateTime(2024, 6, 15, 12, 0, 0);
    final player1 = const PlayerInfo(
      uid: 'uid1',
      name: 'Alice',
      color: 'white',
      rating: 1200,
    );
    final player2 = const PlayerInfo(
      uid: 'uid2',
      name: 'Bob',
      color: 'black',
      rating: 1100,
    );

    GameRoom makeRoom({
      PlayerInfo? p2,
      GameRoomStatus status = GameRoomStatus.waiting,
    }) =>
        GameRoom(
          gameId: 'ABCD1234',
          player1: player1,
          player2: p2,
          boardState: {
            'points': List.generate(24, (_) => 0),
            'bar1': 0,
            'bar2': 0,
            'borneOff1': 0,
            'borneOff2': 0,
          },
          currentTurn: 'player1',
          status: status,
          createdAt: now,
          lastMoveAt: now,
        );

    group('JSON serialization', () {
      test('round-trips correctly with both players', () {
        final room = makeRoom(p2: player2, status: GameRoomStatus.inProgress);
        final json = room.toJson();
        final restored = GameRoom.fromJson(json);

        expect(restored.gameId, equals('ABCD1234'));
        expect(restored.player1.uid, equals('uid1'));
        expect(restored.player1.name, equals('Alice'));
        expect(restored.player1.color, equals('white'));
        expect(restored.player1.rating, equals(1200));
        expect(restored.player2, isNotNull);
        expect(restored.player2!.uid, equals('uid2'));
        expect(restored.player2!.name, equals('Bob'));
        expect(restored.currentTurn, equals('player1'));
        expect(restored.status, equals(GameRoomStatus.inProgress));
        expect(restored.variant, equals('portes'));
      });

      test('round-trips correctly without player 2', () {
        final room = makeRoom();
        final json = room.toJson();
        final restored = GameRoom.fromJson(json);

        expect(restored.player2, isNull);
        expect(restored.status, equals(GameRoomStatus.waiting));
      });

      test('preserves move history', () {
        final room = makeRoom(p2: player2).copyWith(
          moveHistory: [
            {'from': 23, 'to': 20},
            {'from': 12, 'to': 9},
          ],
        );
        final json = room.toJson();
        final restored = GameRoom.fromJson(json);

        expect(restored.moveHistory.length, equals(2));
        expect(restored.moveHistory[0]['from'], equals(23));
      });

      test('preserves dice state', () {
        final room = makeRoom(p2: player2).copyWith(
          diceRoll: const DiceState(die1: 3, die2: 5),
        );
        final json = room.toJson();
        final restored = GameRoom.fromJson(json);

        expect(restored.diceRoll, isNotNull);
        expect(restored.diceRoll!.die1, equals(3));
        expect(restored.diceRoll!.die2, equals(5));
      });

      test('preserves doubling cube state', () {
        final room = makeRoom(p2: player2).copyWith(
          doublingCube: const DoublingCubeState(value: 4, owner: 'player1'),
        );
        final json = room.toJson();
        final restored = GameRoom.fromJson(json);

        expect(restored.doublingCube.value, equals(4));
        expect(restored.doublingCube.owner, equals('player1'));
      });

      test('preserves heartbeats', () {
        final heartbeatTime = DateTime(2024, 6, 15, 12, 30, 0);
        final room = makeRoom(p2: player2).copyWith(
          heartbeats: {'player1': heartbeatTime},
        );
        final json = room.toJson();
        final restored = GameRoom.fromJson(json);

        expect(restored.heartbeats['player1'], equals(heartbeatTime));
      });

      test('preserves pending double', () {
        final room = makeRoom(p2: player2).copyWith(
          pendingDoubleFrom: 'player2',
        );
        final json = room.toJson();
        final restored = GameRoom.fromJson(json);

        expect(restored.pendingDoubleFrom, equals('player2'));
      });

      test('preserves variant', () {
        final room = GameRoom(
          gameId: 'TEST',
          player1: player1,
          boardState: const {'points': []},
          currentTurn: 'player1',
          createdAt: now,
          lastMoveAt: now,
          variant: 'plakoto',
        );
        final json = room.toJson();
        final restored = GameRoom.fromJson(json);

        expect(restored.variant, equals('plakoto'));
      });

      test('handles null optional fields in JSON', () {
        final json = {
          'gameId': 'TEST',
          'players': {
            'player1': {
              'uid': 'uid1',
              'name': 'Alice',
              'color': 'white',
            },
          },
          'boardState': {'points': []},
          'currentTurn': 'player1',
          'status': 'waiting',
          'createdAt': now.toIso8601String(),
          'lastMoveAt': now.toIso8601String(),
        };
        final restored = GameRoom.fromJson(json);

        expect(restored.player2, isNull);
        expect(restored.diceRoll, isNull);
        expect(restored.moveHistory, isEmpty);
        expect(restored.lastTurnMoves, isEmpty);
        expect(restored.winner, isNull);
        expect(restored.heartbeats, isEmpty);
        expect(restored.pendingDoubleFrom, isNull);
        expect(restored.variant, equals('portes'));
        expect(restored.turnTimeLimit, equals(30));
      });
    });

    group('copyWith', () {
      test('updates single fields', () {
        final room = makeRoom(p2: player2, status: GameRoomStatus.inProgress);
        final updated = room.copyWith(currentTurn: 'player2');

        expect(updated.currentTurn, equals('player2'));
        expect(updated.gameId, equals(room.gameId));
        expect(updated.player1.uid, equals(room.player1.uid));
      });

      test('clearDiceRoll sets diceRoll to null', () {
        final room = makeRoom().copyWith(
          diceRoll: const DiceState(die1: 1, die2: 2),
        );
        final cleared = room.copyWith(clearDiceRoll: true);

        expect(cleared.diceRoll, isNull);
      });

      test('clearPendingDouble sets pendingDoubleFrom to null', () {
        final room = makeRoom().copyWith(pendingDoubleFrom: 'player1');
        final cleared = room.copyWith(clearPendingDouble: true);

        expect(cleared.pendingDoubleFrom, isNull);
      });

      test('clearTurnStartedAt sets turnStartedAt to null', () {
        final room = makeRoom().copyWith(turnStartedAt: DateTime.now());
        final cleared = room.copyWith(clearTurnStartedAt: true);

        expect(cleared.turnStartedAt, isNull);
      });
    });
  });

  group('PlayerInfo', () {
    test('JSON round-trip', () {
      const player = PlayerInfo(
        uid: 'test-uid',
        name: 'TestPlayer',
        color: 'white',
        rating: 1500,
      );
      final json = player.toJson();
      final restored = PlayerInfo.fromJson(json);

      expect(restored.uid, equals('test-uid'));
      expect(restored.name, equals('TestPlayer'));
      expect(restored.color, equals('white'));
      expect(restored.rating, equals(1500));
    });

    test('defaults rating to 1000', () {
      final json = {'uid': 'x', 'name': 'X', 'color': 'black'};
      final player = PlayerInfo.fromJson(json);
      expect(player.rating, equals(1000));
    });
  });

  group('DiceState', () {
    test('JSON round-trip', () {
      const dice = DiceState(die1: 4, die2: 6);
      final json = dice.toJson();
      final restored = DiceState.fromJson(json);

      expect(restored.die1, equals(4));
      expect(restored.die2, equals(6));
    });
  });

  group('DoublingCubeState', () {
    test('JSON round-trip with owner', () {
      const cube = DoublingCubeState(value: 8, owner: 'player2');
      final json = cube.toJson();
      final restored = DoublingCubeState.fromJson(json);

      expect(restored.value, equals(8));
      expect(restored.owner, equals('player2'));
    });

    test('defaults to value 1 with no owner', () {
      const cube = DoublingCubeState();
      expect(cube.value, equals(1));
      expect(cube.owner, isNull);
    });

    test('handles missing fields in JSON', () {
      final restored = DoublingCubeState.fromJson({});
      expect(restored.value, equals(1));
      expect(restored.owner, isNull);
    });
  });

  group('GameRoomStatus', () {
    test('all statuses round-trip through name', () {
      for (final status in GameRoomStatus.values) {
        expect(
          GameRoomStatus.values.byName(status.name),
          equals(status),
        );
      }
    });
  });
}
