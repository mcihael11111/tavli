import 'package:cloud_firestore/cloud_firestore.dart';
import '../../multiplayer/data/game_room.dart';

/// Service for spectating live online games.
///
/// Spectators connect to a game room in read-only mode.
/// They receive real-time board updates via Firestore listeners
/// but cannot submit moves, offer doubles, or send chat.
class SpectateService {
  final FirebaseFirestore _firestore;

  SpectateService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection('gameRooms');

  /// Watch a game room in spectator mode (read-only stream).
  Stream<GameRoom> watchGame(String gameId) {
    return _rooms.doc(gameId).snapshots().where((s) => s.exists).map(
          (snapshot) => GameRoom.fromJson(snapshot.data()!),
        );
  }

  /// Get current state of a game room.
  Future<GameRoom?> getGame(String gameId) async {
    final doc = await _rooms.doc(gameId).get();
    if (!doc.exists) return null;
    return GameRoom.fromJson(doc.data()!);
  }

  /// Get list of active (in-progress) games available to spectate.
  Future<List<GameRoom>> getActiveGames({int limit = 20}) async {
    final snapshot = await _rooms
        .where('status', isEqualTo: GameRoomStatus.inProgress.name)
        .orderBy('lastMoveAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => GameRoom.fromJson(doc.data()))
        .toList();
  }

  /// Increment spectator count for a game (stored in game room metadata).
  Future<void> joinAsSpectator(String gameId, String spectatorUid) async {
    await _rooms.doc(gameId).update({
      'spectators': FieldValue.arrayUnion([spectatorUid]),
    });
  }

  /// Decrement spectator count.
  Future<void> leaveAsSpectator(String gameId, String spectatorUid) async {
    await _rooms.doc(gameId).update({
      'spectators': FieldValue.arrayRemove([spectatorUid]),
    });
  }
}
