import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/firestore_multiplayer_service.dart';

/// Firestore-backed matchmaking service.
///
/// Client-side matching for MVP: when entering the queue, also scan for
/// compatible opponents. Race conditions handled by Firestore transactions.
class FirestoreMatchmakingService {
  final FirebaseFirestore _firestore;
  final FirestoreMultiplayerService _multiplayerService;

  FirestoreMatchmakingService({
    FirebaseFirestore? firestore,
    required FirestoreMultiplayerService multiplayerService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _multiplayerService = multiplayerService;

  CollectionReference<Map<String, dynamic>> get _queue =>
      _firestore.collection('matchmakingQueue');

  /// Enter the matchmaking queue and try to find a match.
  ///
  /// Returns a stream of [MatchmakingStatus] updates. When a match is found,
  /// emits [MatchmakingStatus.matched] with the game room ID.
  Stream<MatchmakingStatus> findMatch({
    required String playerUid,
    required String playerName,
    required int rating,
  }) async* {
    // Write to queue.
    await _queue.doc(playerUid).set({
      'uid': playerUid,
      'name': playerName,
      'rating': rating,
      'joinedAt': FieldValue.serverTimestamp(),
      'status': 'waiting',
      'gameRoomId': null,
    });

    yield MatchmakingStatus.searching();

    // Try to match immediately.
    final matched = await _tryMatchClient(playerUid, playerName, rating);
    if (matched != null) {
      yield MatchmakingStatus.matched(matched);
      return;
    }

    // Watch own queue entry for external match (another client matched us).
    yield* _queue
        .doc(playerUid)
        .snapshots()
        .where((s) => s.exists)
        .map((snapshot) {
      final data = snapshot.data()!;
      final status = data['status'] as String;
      if (status == 'matched') {
        return MatchmakingStatus.matched(data['gameRoomId'] as String);
      }
      return MatchmakingStatus.searching();
    }).takeWhile((s) => !s.isMatched);
  }

  /// Client-side matching: scan queue for compatible opponents.
  Future<String?> _tryMatchClient(
    String playerUid,
    String playerName,
    int rating,
  ) async {
    // Query for waiting players within initial range.
    final snapshot = await _queue
        .where('status', isEqualTo: 'waiting')
        .get();

    for (final doc in snapshot.docs) {
      if (doc.id == playerUid) continue;

      final data = doc.data();
      final opponentRating = data['rating'] as int;
      final ratingDiff = (rating - opponentRating).abs();

      // Start with tight range — expand in periodic retries.
      if (ratingDiff > 300) continue;

      // Try to claim this match via transaction.
      try {
        final gameRoomId = await _firestore.runTransaction((tx) async {
          final myDoc = await tx.get(_queue.doc(playerUid));
          final oppDoc = await tx.get(_queue.doc(doc.id));

          if (!myDoc.exists || !oppDoc.exists) return null;
          if (myDoc.data()!['status'] != 'waiting') return null;
          if (oppDoc.data()!['status'] != 'waiting') return null;

          // Create room.
          final roomId = await _multiplayerService.createRoom(
            playerUid: playerUid,
            playerName: playerName,
            playerRating: rating,
          );

          // Join as player 2.
          await _multiplayerService.joinRoom(
            gameId: roomId,
            playerUid: doc.id,
            playerName: data['name'] as String,
            playerRating: opponentRating,
          );

          // Update both queue entries.
          tx.update(_queue.doc(playerUid), {
            'status': 'matched',
            'gameRoomId': roomId,
          });
          tx.update(_queue.doc(doc.id), {
            'status': 'matched',
            'gameRoomId': roomId,
          });

          return roomId;
        });

        if (gameRoomId != null) return gameRoomId;
      } catch (_) {
        // Transaction failed (race condition) — try next opponent.
        continue;
      }
    }

    return null;
  }

  /// Cancel matchmaking — remove from queue.
  Future<void> cancelMatchmaking(String playerUid) async {
    await _queue.doc(playerUid).delete();
  }

  void dispose() {
    // Nothing to clean up for now.
  }
}

/// Status of the matchmaking process.
class MatchmakingStatus {
  final bool isSearching;
  final bool isMatched;
  final String? gameRoomId;

  const MatchmakingStatus._({
    this.isSearching = false,
    this.isMatched = false,
    this.gameRoomId,
  });

  factory MatchmakingStatus.searching() =>
      const MatchmakingStatus._(isSearching: true);

  factory MatchmakingStatus.matched(String gameRoomId) =>
      MatchmakingStatus._(isMatched: true, gameRoomId: gameRoomId);
}
