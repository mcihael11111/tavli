import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../game/data/models/board_state.dart';
import '../../game/domain/engine/variants/game_variant.dart';
import '../../notifications/notification_service.dart';
import 'game_room.dart';

/// Firestore-backed multiplayer service.
///
/// Drop-in replacement for the in-memory MultiplayerService.
/// Integrates with [NotificationService] for game topic subscriptions.
class FirestoreMultiplayerService {
  static const _uuid = Uuid();
  final FirebaseFirestore _firestore;
  final Random _rng = Random.secure();

  FirestoreMultiplayerService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection('gameRooms');

  /// Create a new game room. Returns the room ID.
  Future<String> createRoom({
    required String playerUid,
    required String playerName,
    int playerRating = 1000,
    int turnTimeLimit = 30,
    String variant = 'portes',
    String tradition = 'tavli',
    String poolType = 'tradition',
  }) async {
    final gameId = _uuid.v4().substring(0, 8).toUpperCase();
    final now = DateTime.now();

    // Use variant-aware initial board state.
    final gameVariant = GameVariant.values.where((v) => v.name == variant).firstOrNull
        ?? GameVariant.portes;
    final initialBoard = BoardState.forVariant(gameVariant);

    final room = GameRoom(
      gameId: gameId,
      player1: PlayerInfo(
        uid: playerUid,
        name: playerName,
        color: 'white',
        rating: playerRating,
      ),
      boardState: _boardStateToJson(initialBoard),
      currentTurn: 'player1',
      status: GameRoomStatus.waiting,
      createdAt: now,
      lastMoveAt: now,
      turnTimeLimit: turnTimeLimit,
      variant: variant,
      tradition: tradition,
      poolType: poolType,
    );

    await _rooms.doc(gameId).set(room.toJson());

    // Subscribe to push notifications for this game room.
    await NotificationService.instance.subscribeToGame(gameId);

    return gameId;
  }

  /// Join an existing game room.
  Future<bool> joinRoom({
    required String gameId,
    required String playerUid,
    required String playerName,
    int playerRating = 1000,
  }) async {
    try {
      final result = await _firestore.runTransaction((transaction) async {
        final docRef = _rooms.doc(gameId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) return false;

        final room = GameRoom.fromJson(snapshot.data()!);
        if (room.status != GameRoomStatus.waiting) return false;
        if (room.player2 != null) return false;

        final updated = room.copyWith(
          player2: PlayerInfo(
            uid: playerUid,
            name: playerName,
            color: 'black',
            rating: playerRating,
          ),
          status: GameRoomStatus.inProgress,
          lastMoveAt: DateTime.now(),
        );

        transaction.set(docRef, updated.toJson());
        return true;
      });

      if (result) {
        // Subscribe to push notifications for this game room.
        await NotificationService.instance.subscribeToGame(gameId);
      }

      return result;
    } catch (_) {
      return false;
    }
  }

  /// Submit a complete turn (all moves at once).
  Future<bool> submitTurn({
    required String gameId,
    required String playerUid,
    required Map<String, dynamic> newBoardState,
    required List<Map<String, dynamic>> moves,
    required DiceState diceRoll,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _rooms.doc(gameId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) throw Exception('Room not found');

        final room = GameRoom.fromJson(snapshot.data()!);
        if (room.status != GameRoomStatus.inProgress) {
          throw Exception('Game not in progress');
        }

        // Verify it's the right player's turn.
        final isPlayer1 = room.player1.uid == playerUid;
        final expectedTurn = isPlayer1 ? 'player1' : 'player2';
        if (room.currentTurn != expectedTurn) {
          throw Exception('Not your turn');
        }

        final nextTurn = isPlayer1 ? 'player2' : 'player1';
        final newHistory = [...room.moveHistory, ...moves];

        final updated = room.copyWith(
          boardState: newBoardState,
          currentTurn: nextTurn,
          moveHistory: newHistory,
          lastTurnMoves: moves,
          diceRoll: diceRoll,
          lastMoveAt: DateTime.now(),
          turnStartedAt: DateTime.now(),
          clearPendingDouble: true,
        );

        transaction.set(docRef, updated.toJson());
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Write dice roll to the game room (client-side MVP).
  Future<DiceState?> rollDice(String gameId, String playerUid) async {
    final die1 = _rng.nextInt(6) + 1;
    final die2 = _rng.nextInt(6) + 1;
    final dice = DiceState(die1: die1, die2: die2);

    try {
      await _rooms.doc(gameId).update({
        'diceRoll': dice.toJson(),
        'turnStartedAt': DateTime.now().toIso8601String(),
      });
      return dice;
    } catch (_) {
      return null;
    }
  }

  /// Listen to game room updates (real-time).
  Stream<GameRoom> watchRoom(String gameId) {
    return _rooms.doc(gameId).snapshots().where((s) => s.exists).map(
          (snapshot) => GameRoom.fromJson(snapshot.data()!),
        );
  }

  /// Get current room state.
  Future<GameRoom?> getRoom(String gameId) async {
    final doc = await _rooms.doc(gameId).get();
    if (!doc.exists) return null;
    return GameRoom.fromJson(doc.data()!);
  }

  /// Offer a double.
  Future<void> offerDouble(String gameId, String fromPlayer) async {
    await _rooms.doc(gameId).update({
      'pendingDoubleFrom': fromPlayer,
    });
  }

  /// Respond to a double offer.
  Future<void> respondToDouble({
    required String gameId,
    required bool accepted,
    required DoublingCubeState newCubeState,
  }) async {
    if (accepted) {
      await _rooms.doc(gameId).update({
        'pendingDoubleFrom': null,
        'doublingCube': newCubeState.toJson(),
      });
    } else {
      // Declined — game over.
      final room = await getRoom(gameId);
      if (room == null) return;

      // The player who offered the double wins.
      final winner = room.pendingDoubleFrom;
      await _rooms.doc(gameId).update({
        'pendingDoubleFrom': null,
        'status': GameRoomStatus.finished.name,
        'winner': winner,
      });
    }
  }

  /// End game with a winner.
  Future<void> endGame(String gameId, String winner) async {
    await _rooms.doc(gameId).update({
      'status': GameRoomStatus.finished.name,
      'winner': winner,
      'lastMoveAt': DateTime.now().toIso8601String(),
    });

    // Unsubscribe from game notifications.
    await NotificationService.instance.unsubscribeFromGame(gameId);
  }

  /// Send a quick chat message.
  Future<void> sendChat({
    required String gameId,
    required String senderUid,
    required String senderName,
    required int messageIndex,
  }) async {
    await _rooms.doc(gameId).collection('chat').add({
      'senderUid': senderUid,
      'senderName': senderName,
      'messageIndex': messageIndex,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Watch chat messages for a game room.
  Stream<List<ChatMessage>> watchChat(String gameId) {
    return _rooms
        .doc(gameId)
        .collection('chat')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromJson(doc.data()))
            .toList());
  }

  /// Update heartbeat for disconnect detection.
  Future<void> updateHeartbeat(String gameId, String playerKey) async {
    await _rooms.doc(gameId).update({
      'heartbeats.$playerKey': DateTime.now().toIso8601String(),
    });
  }

  /// Abandon a game (player disconnected too long).
  Future<void> abandonGame(String gameId, String abandonedByPlayer) async {
    final winner = abandonedByPlayer == 'player1' ? 'player2' : 'player1';
    await _rooms.doc(gameId).update({
      'status': GameRoomStatus.abandoned.name,
      'winner': winner,
    });

    // Unsubscribe from game notifications.
    await NotificationService.instance.unsubscribeFromGame(gameId);
  }

  Map<String, dynamic> _boardStateToJson(BoardState state) => {
        'points': state.points,
        'bar1': state.bar1,
        'bar2': state.bar2,
        'borneOff1': state.borneOff1,
        'borneOff2': state.borneOff2,
      };
}

/// Chat message from Firestore subcollection.
class ChatMessage {
  final String senderUid;
  final String senderName;
  final int messageIndex;
  final DateTime? timestamp;

  const ChatMessage({
    required this.senderUid,
    required this.senderName,
    required this.messageIndex,
    this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        senderUid: json['senderUid'] as String,
        senderName: json['senderName'] as String,
        messageIndex: json['messageIndex'] as int,
        timestamp: json['timestamp'] != null
            ? (json['timestamp'] as Timestamp).toDate()
            : null,
      );
}
