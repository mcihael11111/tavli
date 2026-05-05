import '../../domain/engine/move_quality.dart';

/// In-memory cache of teaching-mode move-quality evaluations.
///
/// Keyed by (boardHash, selectedPoint, sortedDice) so that:
/// - Tapping the same checker repeatedly never re-evaluates.
/// - Dice ordering (e.g. [3,5] vs [5,3]) hits the same entry.
/// - Any move that mutates the board invalidates relevant entries on the
///   next read because boardHash will differ.
class MoveQualityCache {
  final Map<String, Map<int, MoveQuality>> _store = {};

  String _key({
    required int boardHash,
    required int selectedPoint,
    required List<int> dice,
  }) {
    final sorted = List<int>.of(dice)..sort();
    return '$boardHash:$selectedPoint:${sorted.join(',')}';
  }

  /// Returns the cached qualities or null on miss.
  Map<int, MoveQuality>? read({
    required int boardHash,
    required int selectedPoint,
    required List<int> dice,
  }) {
    return _store[_key(
      boardHash: boardHash,
      selectedPoint: selectedPoint,
      dice: dice,
    )];
  }

  /// Stores qualities for the given key.
  void write({
    required int boardHash,
    required int selectedPoint,
    required List<int> dice,
    required Map<int, MoveQuality> qualities,
  }) {
    _store[_key(
      boardHash: boardHash,
      selectedPoint: selectedPoint,
      dice: dice,
    )] = qualities;
  }

  /// Drop all entries — call on turn end if you want to bound memory.
  void invalidate() => _store.clear();
}
