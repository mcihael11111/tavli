part of 'position.dart';

/// Read helpers shared by [Position] and [MutablePosition].
mixin _PositionReads {
  Direction get direction;
  Uint8List get _counts;
  int get _pinnedOne;
  int get _pinnedTwo;

  Geometry get geometry => Geometry.of(direction);

  /// Checkers of [s] on its own [pip] (0 = off, 25 = bar).
  int count(Side s, int pip) {
    if (pip < 0 || pip > 25) throw RangeError.range(pip, 0, 25, 'pip');
    return _counts[s.index * _stride + pip];
  }

  /// Whether the checker of [s] on its own [pip] is pinned.
  bool isPinned(Side s, int pip) => (pinnedMask(s) >> pip) & 1 == 1;

  /// Bit p set => the checker of [s] on its pip p is pinned (p in 1..24).
  int pinnedMask(Side s) => s == Side.one ? _pinnedOne : _pinnedTwo;

  int borneOff(Side s) => _counts[s.index * _stride];

  int onBar(Side s) => _counts[s.index * _stride + 25];

  /// Sum of pip * count over pips 1..25 (the bar counts 25).
  int pipCount(Side s) {
    final base = s.index * _stride;
    var sum = 0;
    for (var pip = 1; pip <= 25; pip++) {
      sum += pip * _counts[base + pip];
    }
    return sum;
  }

  /// G5: no checker of [s] on pips 7..25. Pinned checkers count as home;
  /// the D11 bear-off gate is separate.
  bool allHome(Side s) {
    final base = s.index * _stride;
    for (var pip = 7; pip <= 25; pip++) {
      if (_counts[base + pip] != 0) return false;
    }
    return true;
  }

  /// Checkers not yet borne off (board + bar).
  int checkersOnBoard(Side s) => _checkers - borneOff(s);

  /// The side holding the physical point at [me]'s [myPip] (1..24), or null
  /// if it is empty. For a pinned pair this is the pinner.
  Side? controller(Side me, int myPip) {
    if (myPip < 1 || myPip > 24) throw RangeError.range(myPip, 1, 24, 'myPip');
    final them = me.opponent;
    final theirPip = geometry.toOpponent(myPip);
    final mine = count(me, myPip), theirs = count(them, theirPip);
    if (mine > 0 && theirs > 0) return isPinned(me, myPip) ? them : me;
    if (mine > 0) return me;
    if (theirs > 0) return them;
    return null;
  }

  /// A mutable copy for make/unmake.
  MutablePosition toMutable() => MutablePosition._(
        direction,
        Uint8List.fromList(_counts),
        _pinnedOne,
        _pinnedTwo,
      );
}
