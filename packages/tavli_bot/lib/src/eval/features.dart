/// Feature extraction shared by the evaluators (design spec SP2 §4), over
/// player-relative pips: each side moves from its pip 24 towards 1, then
/// off (0); 25 is the bar.
library;

import 'package:tavli_core/tavli_core.dart';

/// Board features from `me`'s perspective, computed once per evaluation.
///
/// Terms:
/// - a *point* of a side is a pip (1..24) the opponent cannot land on:
///   2+ checkers, or 1 under block contact, or (pin contact) a single
///   checker pinning an opposing one. A pinned checker holds nothing.
/// - a *blot* is a checker the opponent could hit or pin: alone, unpinned
///   and not pinning (never under block contact).
/// - *shots* at a side's blots count (blot, opposing source) pairs: a
///   source is a pip (or the bar) holding movable opposing checkers,
///   1..6 pips behind the blot along the opponent's path (direct) or 7..12
///   (indirect).
final class Features {
  final int pipMe, pipOpp;
  final int offMe, offOpp;
  final int barMe, barOpp;

  /// Points on own pips 1..6.
  final int homePointsMe, homePointsOpp;

  /// Points on own pips 1..24.
  final int madePointsMe, madePointsOpp;

  final int blotsMe, blotsOpp;

  /// Direct / indirect shots at my blots (`...Me`) and at the opponent's
  /// blots (`...Opp`).
  final int directShotsMe, directShotsOpp;
  final int indirectShotsMe, indirectShotsOpp;

  /// The longest run of consecutive own points.
  final int primeLenMe, primeLenOpp;

  /// Own points in the opponent's home (its pips 1..6).
  final int anchorsMe, anchorsOpp;

  /// Own checkers pinned.
  final int pinnedMe, pinnedOpp;

  /// The checker on the own start point (pip 24, the "mother") is pinned.
  final bool motherPinnedMe, motherPinnedOpp;

  /// Checkers on the own pip 24 (the head in Long Nard).
  final int headCountMe, headCountOpp;

  const Features({
    required this.pipMe,
    required this.pipOpp,
    required this.offMe,
    required this.offOpp,
    required this.barMe,
    required this.barOpp,
    required this.homePointsMe,
    required this.homePointsOpp,
    required this.madePointsMe,
    required this.madePointsOpp,
    required this.blotsMe,
    required this.blotsOpp,
    required this.directShotsMe,
    required this.directShotsOpp,
    required this.indirectShotsMe,
    required this.indirectShotsOpp,
    required this.primeLenMe,
    required this.primeLenOpp,
    required this.anchorsMe,
    required this.anchorsOpp,
    required this.pinnedMe,
    required this.pinnedOpp,
    required this.motherPinnedMe,
    required this.motherPinnedOpp,
    required this.headCountMe,
    required this.headCountOpp,
  });
}

/// The [Features] of [p] for [me] under [r].
Features extractFeatures(BoardView p, Side me, VariantRules r) {
  final opp = me.opponent;
  final a = _SideScan(p, me, r.contact), b = _SideScan(p, opp, r.contact);
  final g = p.geometry;
  return Features(
    pipMe: p.pipCount(me),
    pipOpp: p.pipCount(opp),
    offMe: p.borneOff(me),
    offOpp: p.borneOff(opp),
    barMe: p.onBar(me),
    barOpp: p.onBar(opp),
    homePointsMe: a.homePoints,
    homePointsOpp: b.homePoints,
    madePointsMe: a.points,
    madePointsOpp: b.points,
    blotsMe: a.blots,
    blotsOpp: b.blots,
    directShotsMe: _shots(g, a.blotMask, b.sourceMask, 1),
    directShotsOpp: _shots(g, b.blotMask, a.sourceMask, 1),
    indirectShotsMe: _shots(g, a.blotMask, b.sourceMask, 7),
    indirectShotsOpp: _shots(g, b.blotMask, a.sourceMask, 7),
    primeLenMe: a.prime,
    primeLenOpp: b.prime,
    anchorsMe: a.anchors,
    anchorsOpp: b.anchors,
    pinnedMe: _bits(p.pinnedMask(me)),
    pinnedOpp: _bits(p.pinnedMask(opp)),
    motherPinnedMe: p.isPinned(me, 24),
    motherPinnedOpp: p.isPinned(opp, 24),
    headCountMe: p.count(me, 24),
    headCountOpp: p.count(opp, 24),
  );
}

/// Whether neither side can ever touch the other again: no checker on a
/// bar, none pinned, and every own checker past every opposing one along
/// the movement paths. Then only the race is left.
///
/// - Opposing directions: my rearmost pip + the opponent's rearmost pip
///   must be at most 24 (the two groups have passed each other).
/// - Same direction: both sides must have every checker on own pips
///   1..12; any checker still on its first half crosses the other side's
///   path.
bool isRace(BoardView p, VariantRules r) {
  const one = Side.one, two = Side.two;
  if (p.onBar(one) > 0 || p.onBar(two) > 0) return false;
  if (p.pinnedMask(one) != 0 || p.pinnedMask(two) != 0) return false;
  final backOne = _rearmost(p, one), backTwo = _rearmost(p, two);
  if (p.direction == Direction.opposing) return backOne + backTwo <= 24;
  return backOne <= 12 && backTwo <= 12;
}

/// The highest own pip (1..24) holding a checker of [s]; 0 if none.
int _rearmost(BoardView p, Side s) {
  for (var pip = 24; pip >= 1; pip--) {
    if (p.count(s, pip) > 0) return pip;
  }
  return 0;
}

/// Shots at the blots in [blotMask] (own pips of the blots' side) from the
/// opposing sources in [sourceMask] (their own pips, 25 = bar) that sit
/// [from]..[from]+5 pips behind each blot along the source side's path.
int _shots(Geometry g, int blotMask, int sourceMask, int from) {
  var n = 0;
  for (var pip = 1; blotMask >> pip != 0; pip++) {
    if ((blotMask >> pip) & 1 == 0) continue;
    final q = g.toOpponent(pip);
    n += _bits6[(sourceMask >> (q + from)) & 63];
  }
  return n;
}

int _bits(int mask) {
  var n = 0;
  for (var m = mask; m != 0; m &= m - 1) {
    n++;
  }
  return n;
}

/// Popcount of 0..63.
final _bits6 = [for (var i = 0; i < 64; i++) _bits(i)];

/// One side's board scan: points, blots and where its movable checkers
/// are.
final class _SideScan {
  _SideScan(BoardView p, Side s, Contact contact) {
    final opp = s.opponent;
    final g = p.geometry;
    final minPoint = contact == Contact.block ? 1 : 2;
    var run = 0;
    if (p.onBar(s) > 0) sourceMask |= 1 << 25;
    for (var pip = 1; pip <= 24; pip++) {
      final c = p.count(s, pip);
      final pinned = p.isPinned(s, pip);
      final q = g.toOpponent(pip);
      final pinning = c > 0 && !pinned && p.isPinned(opp, q);
      final point = !pinned && (c >= minPoint || pinning);
      if (c > 0 && !pinned) sourceMask |= 1 << pip;
      if (point) {
        points++;
        if (pip <= 6) homePoints++;
        if (q <= 6) anchors++;
        if (++run > prime) prime = run;
      } else {
        run = 0;
      }
      if (c == 1 && !pinned && !pinning && contact != Contact.block) {
        blots++;
        blotMask |= 1 << pip;
      }
    }
  }

  int points = 0, homePoints = 0, anchors = 0, prime = 0, blots = 0;

  /// Bit p => a blot on own pip p.
  int blotMask = 0;

  /// Bit p => movable own checkers on pip p (25 = bar).
  int sourceMask = 0;
}
