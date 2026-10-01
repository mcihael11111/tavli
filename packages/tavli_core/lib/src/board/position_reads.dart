part of 'position.dart';

/// The [BoardView] implementation shared by [Position] and [MutablePosition].
mixin _PositionReads implements BoardView {
  Uint8List get _counts;
  int get _pinnedOne;
  int get _pinnedTwo;

  @override
  Geometry get geometry => Geometry.of(direction);

  @override
  int count(Side s, int pip) {
    if (pip < 0 || pip > 25) throw RangeError.range(pip, 0, 25, 'pip');
    return _counts[s.index * _stride + pip];
  }

  @override
  bool isPinned(Side s, int pip) =>
      pip >= 1 && pip <= 24 && (pinnedMask(s) >> pip) & 1 == 1;

  @override
  int pinnedMask(Side s) => s == Side.one ? _pinnedOne : _pinnedTwo;

  @override
  int borneOff(Side s) => _counts[s.index * _stride];

  @override
  int onBar(Side s) => _counts[s.index * _stride + 25];

  @override
  int pipCount(Side s) {
    final base = s.index * _stride;
    var sum = 0;
    for (var pip = 1; pip <= 25; pip++) {
      sum += pip * _counts[base + pip];
    }
    return sum;
  }

  @override
  bool allHome(Side s) {
    final base = s.index * _stride;
    for (var pip = 7; pip <= 25; pip++) {
      if (_counts[base + pip] != 0) return false;
    }
    return true;
  }

  @override
  int checkersOnBoard(Side s) => _checkers - borneOff(s);

  @override
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

  /// The board's Zobrist hash (cached by [Position], maintained by
  /// [MutablePosition]).
  int get _zobristHashOf;

  /// A mutable copy for make/unmake.
  MutablePosition toMutable() => MutablePosition._(
        direction,
        Uint8List.fromList(_counts),
        _pinnedOne,
        _pinnedTwo,
        _zobristHashOf,
      );
}
