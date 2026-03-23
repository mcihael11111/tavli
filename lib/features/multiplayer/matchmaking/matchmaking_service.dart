import 'dart:async';

/// Rating-based matchmaking service.
///
/// Algorithm per spec:
/// 1. Search for opponents within ±200 rating
/// 2. Expand range by 50 every 10 seconds (up to ±500)
/// 3. After 60s, match with any available player
class MatchmakingService {
  final List<_QueueEntry> _queue = [];
  Timer? _matchTimer;

  /// Enter the matchmaking queue.
  /// Returns a Future that completes when a match is found.
  Future<MatchResult> findMatch({
    required String playerUid,
    required String playerName,
    required int rating,
  }) async {
    final completer = Completer<MatchResult>();
    final entry = _QueueEntry(
      uid: playerUid,
      name: playerName,
      rating: rating,
      joinedAt: DateTime.now(),
      completer: completer,
    );

    _queue.add(entry);
    _tryMatch();

    // Periodic matching attempts with expanding range.
    _matchTimer?.cancel();
    _matchTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _tryMatch();
    });

    return completer.future;
  }

  /// Cancel matchmaking.
  void cancelMatchmaking(String playerUid) {
    _queue.removeWhere((e) {
      if (e.uid == playerUid) {
        if (!e.completer.isCompleted) {
          e.completer.completeError('Cancelled');
        }
        return true;
      }
      return false;
    });
  }

  void _tryMatch() {
    if (_queue.length < 2) return;

    final now = DateTime.now();

    for (int i = 0; i < _queue.length; i++) {
      for (int j = i + 1; j < _queue.length; j++) {
        final a = _queue[i];
        final b = _queue[j];

        final waitTime = now.difference(a.joinedAt).inSeconds;
        final maxRange = _rangeForWaitTime(waitTime);

        final ratingDiff = (a.rating - b.rating).abs();
        if (ratingDiff <= maxRange) {
          // Match found!
          _queue.removeAt(j);
          _queue.removeAt(i);

          final result = MatchResult(
            player1Uid: a.uid,
            player1Name: a.name,
            player2Uid: b.uid,
            player2Name: b.name,
          );

          if (!a.completer.isCompleted) a.completer.complete(result);
          if (!b.completer.isCompleted) b.completer.complete(result);
          return;
        }
      }
    }
  }

  int _rangeForWaitTime(int seconds) {
    if (seconds < 10) return 200;
    if (seconds < 20) return 250;
    if (seconds < 30) return 300;
    if (seconds < 40) return 350;
    if (seconds < 50) return 400;
    if (seconds < 60) return 500;
    return 99999; // match with anyone
  }

  void dispose() {
    _matchTimer?.cancel();
    for (final entry in _queue) {
      if (!entry.completer.isCompleted) {
        entry.completer.completeError('Service disposed');
      }
    }
    _queue.clear();
  }
}

class _QueueEntry {
  final String uid;
  final String name;
  final int rating;
  final DateTime joinedAt;
  final Completer<MatchResult> completer;

  _QueueEntry({
    required this.uid,
    required this.name,
    required this.rating,
    required this.joinedAt,
    required this.completer,
  });
}

class MatchResult {
  final String player1Uid;
  final String player1Name;
  final String player2Uid;
  final String player2Name;
  final String? gameRoomId;

  const MatchResult({
    required this.player1Uid,
    required this.player1Name,
    required this.player2Uid,
    required this.player2Name,
    this.gameRoomId,
  });
}
