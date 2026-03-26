import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/tradition.dart';
import '../../game/domain/engine/variants/game_variant.dart';
import '../data/firestore_multiplayer_service.dart';

/// Firestore-backed matchmaking service.
///
/// Client-side matching for MVP: when entering the queue, also scan for
/// compatible opponents. Race conditions handled by Firestore transactions.
///
/// Supports two pool types:
/// - **Tradition pool**: matches within the same tradition + variant.
/// - **International pool**: matches across traditions by mechanic family.
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
    required Tradition tradition,
    required GameVariant variant,
    PoolType poolType = PoolType.tradition,
    MechanicFamily? mechanicFamily,
  }) async* {
    // Write to queue with tradition/pool context.
    await _queue.doc(playerUid).set({
      'uid': playerUid,
      'name': playerName,
      'rating': rating,
      'tradition': tradition.name,
      'variant': variant.name,
      'poolType': poolType.name,
      'mechanicFamily': mechanicFamily?.name ?? variant.mechanicFamily.name,
      'joinedAt': FieldValue.serverTimestamp(),
      'status': 'waiting',
      'gameRoomId': null,
    });

    yield MatchmakingStatus.searching();

    // Try to match immediately.
    final matched = await _tryMatchClient(
      playerUid, playerName, rating,
      tradition: tradition,
      variant: variant,
      poolType: poolType,
      mechanicFamily: mechanicFamily ?? variant.mechanicFamily,
    );
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
    int rating, {
    required Tradition tradition,
    required GameVariant variant,
    required PoolType poolType,
    required MechanicFamily mechanicFamily,
  }) async {
    // Build query based on pool type.
    Query<Map<String, dynamic>> query = _queue
        .where('status', isEqualTo: 'waiting');

    if (poolType == PoolType.tradition) {
      // Tradition pool: match same tradition + variant.
      query = query
          .where('poolType', isEqualTo: 'tradition')
          .where('tradition', isEqualTo: tradition.name)
          .where('variant', isEqualTo: variant.name);
    } else {
      // International pool: match same mechanic family.
      query = query
          .where('poolType', isEqualTo: 'international')
          .where('mechanicFamily', isEqualTo: mechanicFamily.name);
    }

    final snapshot = await query.get();

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

          // Create room with variant-aware initial state.
          final roomId = await _multiplayerService.createRoom(
            playerUid: playerUid,
            playerName: playerName,
            playerRating: rating,
            variant: variant.name,
            tradition: tradition.name,
            poolType: poolType.name,
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
