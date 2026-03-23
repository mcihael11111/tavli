import 'dart:async';
import 'package:uuid/uuid.dart';
import 'game_room.dart';

/// Service for multiplayer game room management.
///
/// Uses an in-memory store for MVP. Replace with Firestore for production.
/// The API is designed to be a drop-in for Firestore real-time listeners.
class MultiplayerService {
  static const _uuid = Uuid();

  // In-memory game rooms (replace with Firestore).
  final Map<String, GameRoom> _rooms = {};
  final Map<String, StreamController<GameRoom>> _roomStreams = {};

  /// Create a new game room. Returns the room ID.
  Future<String> createRoom({
    required String playerUid,
    required String playerName,
    int turnTimeLimit = 30,
  }) async {
    final gameId = _uuid.v4().substring(0, 8).toUpperCase();
    final now = DateTime.now();

    final room = GameRoom(
      gameId: gameId,
      player1: PlayerInfo(
        uid: playerUid,
        name: playerName,
        color: 'white',
      ),
      boardState: _initialBoardStateJson(),
      currentTurn: 'player1',
      status: GameRoomStatus.waiting,
      createdAt: now,
      lastMoveAt: now,
      turnTimeLimit: turnTimeLimit,
    );

    _rooms[gameId] = room;
    _roomStreams[gameId] = StreamController<GameRoom>.broadcast();
    _roomStreams[gameId]!.add(room);

    return gameId;
  }

  /// Join an existing game room.
  Future<bool> joinRoom({
    required String gameId,
    required String playerUid,
    required String playerName,
  }) async {
    final room = _rooms[gameId];
    if (room == null) return false;
    if (room.status != GameRoomStatus.waiting) return false;
    if (room.player2 != null) return false;

    final updated = GameRoom(
      gameId: room.gameId,
      player1: room.player1,
      player2: PlayerInfo(
        uid: playerUid,
        name: playerName,
        color: 'black',
      ),
      boardState: room.boardState,
      currentTurn: room.currentTurn,
      status: GameRoomStatus.inProgress,
      createdAt: room.createdAt,
      lastMoveAt: DateTime.now(),
      turnTimeLimit: room.turnTimeLimit,
    );

    _rooms[gameId] = updated;
    _roomStreams[gameId]?.add(updated);
    return true;
  }

  /// Submit a move (server would validate this).
  Future<bool> submitMove({
    required String gameId,
    required String playerUid,
    required Map<String, dynamic> move,
    required Map<String, dynamic> newBoardState,
  }) async {
    final room = _rooms[gameId];
    if (room == null) return false;
    if (room.status != GameRoomStatus.inProgress) return false;

    // Verify it's the right player's turn.
    final isPlayer1 = room.player1.uid == playerUid;
    final expectedTurn = isPlayer1 ? 'player1' : 'player2';
    if (room.currentTurn != expectedTurn) return false;

    final newHistory = [...room.moveHistory, move];
    final nextTurn = isPlayer1 ? 'player2' : 'player1';

    final updated = GameRoom(
      gameId: room.gameId,
      player1: room.player1,
      player2: room.player2,
      boardState: newBoardState,
      currentTurn: nextTurn,
      moveHistory: newHistory,
      status: room.status,
      createdAt: room.createdAt,
      lastMoveAt: DateTime.now(),
      turnTimeLimit: room.turnTimeLimit,
      turnStartedAt: DateTime.now(),
    );

    _rooms[gameId] = updated;
    _roomStreams[gameId]?.add(updated);
    return true;
  }

  /// Server-side dice roll (for fairness).
  Future<DiceState> rollDice(String gameId) async {
    // In production, this would be a Cloud Function.
    final die1 = DateTime.now().microsecond % 6 + 1;
    final die2 = DateTime.now().millisecond % 6 + 1;
    return DiceState(die1: die1, die2: die2);
  }

  /// Listen to game room updates (real-time).
  Stream<GameRoom>? watchRoom(String gameId) {
    return _roomStreams[gameId]?.stream;
  }

  /// Get current room state.
  GameRoom? getRoom(String gameId) => _rooms[gameId];

  /// End game.
  Future<void> endGame(String gameId, String winnerId) async {
    final room = _rooms[gameId];
    if (room == null) return;

    final updated = GameRoom(
      gameId: room.gameId,
      player1: room.player1,
      player2: room.player2,
      boardState: room.boardState,
      currentTurn: room.currentTurn,
      moveHistory: room.moveHistory,
      status: GameRoomStatus.finished,
      createdAt: room.createdAt,
      lastMoveAt: DateTime.now(),
      turnTimeLimit: room.turnTimeLimit,
    );

    _rooms[gameId] = updated;
    _roomStreams[gameId]?.add(updated);
  }

  /// Clean up.
  void dispose() {
    for (final controller in _roomStreams.values) {
      controller.close();
    }
  }

  Map<String, dynamic> _initialBoardStateJson() => {
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
}
