import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/features/multiplayer/data/game_room.dart';
import 'package:tavli/features/multiplayer/matchmaking/matchmaking_service.dart';
import 'package:tavli/features/multiplayer/domain/rating_system.dart';
import 'package:tavli/features/game/data/models/game_result.dart';

/// Integration test for the full multiplayer flow using in-memory services.
///
/// Tests the complete lifecycle:
///   matchmaking → room creation → joining → turns → game end → ratings
void main() {
  group('Multiplayer full flow (in-memory)', () {
    test('two players match, play turns, and get rated', () async {
      // ── Step 1: Matchmaking ──
      final matchmaker = MatchmakingService();
      addTearDown(matchmaker.dispose);

      final match1Future = matchmaker.findMatch(
        playerUid: 'alice-uid',
        playerName: 'Alice',
        rating: 1200,
      );
      final match2Future = matchmaker.findMatch(
        playerUid: 'bob-uid',
        playerName: 'Bob',
        rating: 1150,
      );

      final results = await Future.wait([match1Future, match2Future]);
      expect(results[0].player1Uid, isNotNull);
      expect(results[0].player2Uid, isNotNull);

      // ── Step 2: Create game room ──
      final now = DateTime.now();
      var room = GameRoom(
        gameId: 'ROOM-001',
        player1: const PlayerInfo(
          uid: 'alice-uid',
          name: 'Alice',
          color: 'white',
          rating: 1200,
        ),
        boardState: _initialBoard(),
        currentTurn: 'player1',
        status: GameRoomStatus.waiting,
        createdAt: now,
        lastMoveAt: now,
      );

      expect(room.status, equals(GameRoomStatus.waiting));
      expect(room.player2, isNull);

      // ── Step 3: Player 2 joins ──
      room = room.copyWith(
        player2: const PlayerInfo(
          uid: 'bob-uid',
          name: 'Bob',
          color: 'black',
          rating: 1150,
        ),
        status: GameRoomStatus.inProgress,
      );

      expect(room.status, equals(GameRoomStatus.inProgress));
      expect(room.player2, isNotNull);
      expect(room.player2!.name, equals('Bob'));

      // ── Step 4: Simulate turns ──

      // Turn 1: Player 1 rolls and moves
      room = room.copyWith(
        diceRoll: const DiceState(die1: 3, die2: 5),
        currentTurn: 'player1',
        turnStartedAt: DateTime.now(),
      );
      expect(room.diceRoll!.die1, equals(3));

      // Player 1 submits moves
      room = room.copyWith(
        moveHistory: [
          {'from': 7, 'to': 4, 'die': 3},
          {'from': 12, 'to': 7, 'die': 5},
        ],
        lastTurnMoves: [
          {'from': 7, 'to': 4, 'die': 3},
          {'from': 12, 'to': 7, 'die': 5},
        ],
        currentTurn: 'player2',
        lastMoveAt: DateTime.now(),
      );
      expect(room.currentTurn, equals('player2'));
      expect(room.moveHistory.length, equals(2));

      // Turn 2: Player 2 rolls and moves
      room = room.copyWith(
        diceRoll: const DiceState(die1: 6, die2: 4),
        turnStartedAt: DateTime.now(),
      );

      room = room.copyWith(
        moveHistory: [
          ...room.moveHistory,
          {'from': 0, 'to': 6, 'die': 6},
          {'from': 11, 'to': 15, 'die': 4},
        ],
        lastTurnMoves: [
          {'from': 0, 'to': 6, 'die': 6},
          {'from': 11, 'to': 15, 'die': 4},
        ],
        currentTurn: 'player1',
        lastMoveAt: DateTime.now(),
      );
      expect(room.currentTurn, equals('player1'));
      expect(room.moveHistory.length, equals(4));

      // ── Step 5: Doubling cube ──
      room = room.copyWith(pendingDoubleFrom: 'player1');
      expect(room.pendingDoubleFrom, equals('player1'));

      // Opponent accepts
      room = room.copyWith(
        doublingCube: const DoublingCubeState(value: 2, owner: 'player2'),
        clearPendingDouble: true,
      );
      expect(room.doublingCube.value, equals(2));
      expect(room.doublingCube.owner, equals('player2'));
      expect(room.pendingDoubleFrom, isNull);

      // ── Step 6: Game end ──
      room = room.copyWith(
        status: GameRoomStatus.finished,
        winner: 'player1',
      );
      expect(room.status, equals(GameRoomStatus.finished));
      expect(room.winner, equals('player1'));

      // ── Step 7: Rating update ──
      const ratingSystem = RatingSystem();
      final ratingUpdate = ratingSystem.calculateNewRatings(
        winnerRating: 1200,
        loserRating: 1150,
        winnerGamesPlayed: 10,
        loserGamesPlayed: 15,
        resultType: GameResultType.single,
      );

      expect(ratingUpdate.newWinnerRating, greaterThan(1200));
      expect(ratingUpdate.newLoserRating, lessThan(1150));
      expect(ratingUpdate.winnerDelta, greaterThan(0));
      expect(ratingUpdate.loserDelta, lessThan(0));

      // ── Step 8: Verify JSON round-trip ──
      final json = room.toJson();
      final restored = GameRoom.fromJson(json);

      expect(restored.gameId, equals(room.gameId));
      expect(restored.winner, equals('player1'));
      expect(restored.status, equals(GameRoomStatus.finished));
      expect(restored.doublingCube.value, equals(2));
      expect(restored.moveHistory.length, equals(4));
    });

    test('game abandonment flow', () {
      final now = DateTime.now();
      var room = GameRoom(
        gameId: 'ROOM-002',
        player1: const PlayerInfo(
          uid: 'alice-uid',
          name: 'Alice',
          color: 'white',
        ),
        player2: const PlayerInfo(
          uid: 'bob-uid',
          name: 'Bob',
          color: 'black',
        ),
        boardState: _initialBoard(),
        currentTurn: 'player1',
        status: GameRoomStatus.inProgress,
        createdAt: now,
        lastMoveAt: now,
      );

      // Player 2 disconnects
      room = room.copyWith(
        status: GameRoomStatus.abandoned,
        winner: 'player1',
      );

      expect(room.status, equals(GameRoomStatus.abandoned));
      expect(room.winner, equals('player1'));

      // JSON should preserve abandoned status
      final json = room.toJson();
      final restored = GameRoom.fromJson(json);
      expect(restored.status, equals(GameRoomStatus.abandoned));
    });

    test('double declined ends game', () {
      final now = DateTime.now();
      var room = GameRoom(
        gameId: 'ROOM-003',
        player1: const PlayerInfo(
          uid: 'alice-uid',
          name: 'Alice',
          color: 'white',
        ),
        player2: const PlayerInfo(
          uid: 'bob-uid',
          name: 'Bob',
          color: 'black',
        ),
        boardState: _initialBoard(),
        currentTurn: 'player1',
        status: GameRoomStatus.inProgress,
        createdAt: now,
        lastMoveAt: now,
      );

      // Player 1 offers double
      room = room.copyWith(pendingDoubleFrom: 'player1');

      // Player 2 declines → player 1 wins
      room = room.copyWith(
        status: GameRoomStatus.finished,
        winner: 'player1',
        clearPendingDouble: true,
      );

      expect(room.status, equals(GameRoomStatus.finished));
      expect(room.winner, equals('player1'));
      expect(room.pendingDoubleFrom, isNull);
    });

    test('heartbeat tracking for disconnect detection', () {
      final now = DateTime.now();
      var room = GameRoom(
        gameId: 'ROOM-004',
        player1: const PlayerInfo(
          uid: 'alice-uid',
          name: 'Alice',
          color: 'white',
        ),
        player2: const PlayerInfo(
          uid: 'bob-uid',
          name: 'Bob',
          color: 'black',
        ),
        boardState: _initialBoard(),
        currentTurn: 'player1',
        status: GameRoomStatus.inProgress,
        createdAt: now,
        lastMoveAt: now,
      );

      // Both players send heartbeats
      final hb1 = DateTime.now();
      room = room.copyWith(heartbeats: {'player1': hb1});

      final hb2 = DateTime.now();
      room = room.copyWith(
        heartbeats: {...room.heartbeats, 'player2': hb2},
      );

      expect(room.heartbeats.length, equals(2));
      expect(room.heartbeats['player1'], equals(hb1));
      expect(room.heartbeats['player2'], equals(hb2));

      // Detect stale heartbeat (>30s old)
      final staleThreshold = DateTime.now().subtract(
        const Duration(seconds: 30),
      );
      final p1Stale = room.heartbeats['player1']!.isBefore(staleThreshold);
      // Just created, so not stale
      expect(p1Stale, isFalse);
    });
  });
}

Map<String, dynamic> _initialBoard() => {
      'points': List.generate(24, (i) {
        if (i == 23) return 2;
        if (i == 12) return 5;
        if (i == 7) return 3;
        if (i == 5) return 5;
        if (i == 0) return -2;
        if (i == 11) return -5;
        if (i == 16) return -3;
        if (i == 18) return -5;
        return 0;
      }),
      'bar1': 0,
      'bar2': 0,
      'borneOff1': 0,
      'borneOff2': 0,
    };
