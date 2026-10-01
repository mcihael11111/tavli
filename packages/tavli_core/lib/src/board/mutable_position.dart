part of 'position.dart';

/// A mutable board for make/unmake in the play generator.
///
/// Mutators do no rule checking (that is `StepRules`' job); they only assert
/// that counts stay in range. [freeze] produces an immutable [Position].
final class MutablePosition with _PositionReads implements BoardView {
  @override
  final Direction direction;
  @override
  final Uint8List _counts;
  @override
  int _pinnedOne;
  @override
  int _pinnedTwo;
  int _zobristHash;

  MutablePosition._(
    this.direction,
    this._counts,
    this._pinnedOne,
    this._pinnedTwo,
    this._zobristHash,
  );

  /// A 30-bit Zobrist hash of the board, kept up to date by every
  /// mutator in O(1) (design spec §9); it equals the frozen position's
  /// [Position.hashCode]. Equal boards have equal hashes; unequal boards
  /// usually differ, so a match must still be confirmed with
  /// [sameBoardAs]. Web-safe.
  int get zobristHash => _zobristHash;

  @override
  int get _zobristHashOf => _zobristHash;

  /// Whether this board equals [p] (direction, counts and pinned bits),
  /// without freezing.
  bool sameBoardAs(Position p) {
    if (p.direction != direction ||
        p._pinnedOne != _pinnedOne ||
        p._pinnedTwo != _pinnedTwo) {
      return false;
    }
    final a = _counts, b = p._counts;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Adds one checker of [s] on its own [pip] (0..25).
  void add(Side s, int pip) {
    final i = _index(s, pip);
    final c = _counts[i];
    assert(c < _checkers, 'overflow at ${s.name}:$pip');
    _zobristHash ^= _zobrist[i * _zCounts + c] ^ _zobrist[i * _zCounts + c + 1];
    _counts[i] = c + 1;
  }

  /// Removes one checker of [s] from its own [pip] (0..25).
  void remove(Side s, int pip) {
    final i = _index(s, pip);
    final c = _counts[i];
    assert(c > 0, 'no ${s.name} checker on $pip');
    _zobristHash ^= _zobrist[i * _zCounts + c] ^ _zobrist[i * _zCounts + c - 1];
    _counts[i] = c - 1;
  }

  /// Moves one checker of [s] from own pip [from] to own pip [to].
  void move(Side s, int from, int to) {
    remove(s, from);
    add(s, to);
  }

  /// Sets or clears the pinned bit of [s] on its own [pip] (1..24).
  void setPinned(Side s, int pip, bool pinned) {
    assert(pip >= 1 && pip <= 24, 'pinned pip $pip outside 1..24');
    final bit = 1 << pip;
    if (((pinnedMask(s) & bit) != 0) != pinned) {
      _zobristHash ^= _zobrist[_zPinBase + s.index * 25 + pip];
    }
    if (s == Side.one) {
      _pinnedOne = pinned ? _pinnedOne | bit : _pinnedOne & ~bit;
    } else {
      _pinnedTwo = pinned ? _pinnedTwo | bit : _pinnedTwo & ~bit;
    }
  }

  /// An immutable snapshot; later mutations do not affect it.
  ///
  /// In debug builds (asserts on) the snapshot is fully validated and an
  /// invalid board throws [ArgumentError]; release builds skip the check.
  Position freeze() {
    final p = Position._(
      direction,
      Uint8List.fromList(_counts),
      _pinnedOne,
      _pinnedTwo,
      _zobristHash,
    );
    assert(() {
      _validateBoard(p);
      if (_zobristHash !=
          _zobristOf(direction, _counts, _pinnedOne, _pinnedTwo)) {
        throw StateError('stale Zobrist hash');
      }
      return true;
    }());
    return p;
  }

  static int _index(Side s, int pip) {
    if (pip < 0 || pip > 25) throw RangeError.range(pip, 0, 25, 'pip');
    return s.index * _stride + pip;
  }
}
