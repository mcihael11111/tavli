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

  MutablePosition._(
    this.direction,
    this._counts,
    this._pinnedOne,
    this._pinnedTwo,
  );

  /// Adds one checker of [s] on its own [pip] (0..25).
  void add(Side s, int pip) {
    final i = _index(s, pip);
    assert(_counts[i] < _checkers, 'overflow at ${s.name}:$pip');
    _counts[i]++;
  }

  /// Removes one checker of [s] from its own [pip] (0..25).
  void remove(Side s, int pip) {
    final i = _index(s, pip);
    assert(_counts[i] > 0, 'no ${s.name} checker on $pip');
    _counts[i]--;
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
    );
    assert(() {
      _validateBoard(p);
      return true;
    }());
    return p;
  }

  static int _index(Side s, int pip) {
    if (pip < 0 || pip > 25) throw RangeError.range(pip, 0, 25, 'pip');
    return s.index * _stride + pip;
  }
}
