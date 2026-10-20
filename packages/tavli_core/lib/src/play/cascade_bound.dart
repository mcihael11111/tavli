part of 'play_generator.dart';

/// A cheap, sound upper bound on the queue entries a block-contact cascade
/// can still play from a state (SP3 design §5.4 (a)). [_Cascade] uses it
/// to cut subtrees that cannot beat the best found.
///
/// **Setting.** Block contact without pins (Gul Bara), with a
/// non-decreasing queue (every [cascadeQueue] and remainder is one). There
/// are no hits or pins, so the opponent never moves during the cascade and
/// the open points (those with no opposing checker) are fixed.
/// - Own checkers never block each other.
/// - A step of die d takes a checker from x to x - d if that point is
///   open (x = 25 is the bar). When x - d <= 0 it bears the checker off,
///   which needs all checkers home (G5).
/// - The validators only remove steps.
/// - A game-ending step (all borne off; there is no mother rule without
///   pins) counts as the rest of the queue (A4).
///
/// Write q for the queue, i for the state's index and P(t) for
/// `q[i] + ... + q[i+t-1]`. For a state, N is the checkers on the board,
/// pips their pip count, and H the sum of `max(0, x - 6)` over them (the
/// travel needed to bring all home). t* is the least t with P(t) >= H.
///
/// **Relaxation for k steps.** Any legal sequence of k steps from the
/// state uses only `q[i..i+k)`; let D be their value set. The closure C(x)
/// is every pip reachable from x by steps with values in D that land on
/// open points, x included. Every pip a checker on x visits during those
/// k steps is in C(x). Let m0(x) = min C(x).
/// - **canBear.** Bear-off can happen only if every checker has m0 <= 6;
///   otherwise one never gets home.
/// - **Floor.** m(x) = 0 when canBear holds and max D >= m0(x) (the
///   checker may be borne off); else m(x) = m0(x).
/// - **Budget.** Phi = sum of (x - m(x)) over the checkers. B counts the
///   checkers with m(x) = 0; only they can be borne off.
///
/// **Lemma 1 (budget).** Each step of die d lowers Phi by at least d for
/// a move and at least 1 for a bear-off. Later steps use values D' ⊆ D.
/// - Shrinking D only shrinks closures, so m0 can only rise, and canBear
///   can only turn false. A checker with m > 0 never gets m = 0 later.
/// - Moving x -> y = x - d: y is open and d ∈ D, so C(y) ⊆ C(x) and
///   m(y) >= m(x). Its term drops from x - m(x) to at most
///   y - m(y) <= x - m(x) - d.
/// - A bear-off from x removes the term x = x - m(x) >= 1, because a
///   bear-off from x means m(x) = 0.
/// - Every other term can only fall.
///
/// Bear-offs need all home first, i.e. moves (each travelling exactly its
/// die) of total >= H. So the first bear-off is at step t* or later.
/// Hence at most j = min(B, k - t*) bear-offs, or none when canBear fails
/// or k <= t*. The queue is non-decreasing, so the j largest discounted
/// entries are the last j. So k steps need
/// `cost(k) = P(k - j) + j <= Phi`; with no bear-off use Phi0 (Phi with
/// m = m0), which a move-only sequence also lowers by d per step.
///
/// **Lemma 2 (values).** Every step starts on a pip y in some C(x), x an
/// own checker's pip now. So value v can be stepped only if some such y
/// has y - v open (y - v >= 1), or y - v <= 0 when bear-off is possible.
/// So `q[i+k-1]` must be one of those values.
///
/// **Lemma 3 (game end at step j).** It needs N bear-offs, so canBear,
/// B = N and j >= t* + N. Each step lowers the pip count by at most its
/// die, so also P(j) >= pips. Lemmas 1-2 must also hold for j.
///
/// **Bound.** A sequence of k steps has legal prefixes of every length
/// < k. So for the least k (in ascending order) where Lemma 1 or 2 fails,
/// every legal sequence is shorter than k. The bound is the full rest of
/// the queue if Lemma 3 allows an end at some j < k; otherwise it is
/// k - 1. All three lemmas are necessary conditions, so the true maximum
/// never exceeds the bound. D, and so the tables, depend only on the value
/// set of `q[i..i+k)`, which takes at most six values as k grows (the
/// [_Group]s of index i).
final class _CascadeBound {
  _CascadeBound(Position start, this.side, this.queue)
      : _open = _openMask(start, side),
        _sum = List.filled(queue.length + 1, 0) {
    for (var i = 0; i < queue.length; i++) {
      _sum[i + 1] = _sum[i] + queue[i];
    }
  }

  final Side side;
  final List<int> queue;

  /// Bit p set => own pip p (1..24) has no opposing checker. Fixed for the
  /// whole cascade (block contact: the opponent never moves).
  final int _open;

  /// `_sum[i]` = q[0] + ... + q[i-1], so P(t) = `_sum[i+t] - _sum[i]`.
  final List<int> _sum;

  /// Per queue index: its groups, smallest k first.
  late final _groups = List<List<_Group>?>.filled(queue.length, null);
  final _byValues = <int, _Tables>{};

  /// Occupied pips and their counts, reused by [of].
  final _pips = List.filled(25, 0), _counts = List.filled(25, 0);

  static int _openMask(Position p, Side s) {
    final g = p.geometry, o = s.opponent;
    var mask = 0;
    for (var pip = 1; pip <= 24; pip++) {
      if (p.count(o, g.toOpponent(pip)) == 0) mask |= 1 << pip;
    }
    return mask;
  }

  /// An upper bound on `_Cascade._maxFrom` for the state of [p] at queue
  /// [index] (< queue.length).
  int of(BoardView p, int index) {
    final full = queue.length - index, base = _sum[index];
    var occupied = 0, n = 0, pips = 0, home = 0;
    for (var x = 1; x <= 25; x++) {
      final c = p.count(side, x);
      if (c == 0) continue;
      _pips[occupied] = x;
      _counts[occupied++] = c;
      n += c;
      pips += c * x;
      if (x > 6) home += c * (x - 6);
    }
    // t* (full + 1: never all home within the queue).
    var tStar = 0;
    while (tStar <= full && _sum[index + tStar] - base < home) {
      tStar++;
    }
    for (final g in _groups[index] ??= _groupsFor(index)) {
      final t = g.tables;
      var phi0 = 0, phi = 0, bear = 0, values0 = 0, values = 0;
      var canBear = true;
      for (var o = 0; o < occupied; o++) {
        final x = _pips[o], c = _counts[o], m = t.min[x];
        values0 |= t.values[x];
        phi0 += c * (x - m);
        if (m > 6) canBear = false;
      }
      if (canBear && tStar < g.kHi) {
        values = values0;
        for (var o = 0; o < occupied; o++) {
          final x = _pips[o], c = _counts[o], m = t.min[x];
          if (m <= t.maxValue) {
            // May be borne off: its whole pip, and every value >= m.
            phi += c * x;
            bear += c;
            values |= (0x7E >> m) << m;
          } else {
            phi += c * (x - m);
          }
        }
      } else {
        canBear = false;
      }
      for (var k = g.kLo; k <= g.kHi; k++) {
        final bears = canBear && k > tStar;
        final ok =
            (((bears ? values : values0) >> queue[index + k - 1]) & 1) == 1;
        final j = bears ? min(bear, k - tStar) : 0;
        if (!ok || _sum[index + k - j] - base + j > (bears ? phi : phi0)) {
          return k - 1;
        }
        // Lemma 3: an end at step k.
        if (bears &&
            bear == n &&
            k >= tStar + n &&
            _sum[index + k] - base >= pips) {
          return full;
        }
      }
    }
    return full;
  }

  /// The [_Group]s of [index], smallest k first.
  List<_Group> _groupsFor(int index) {
    final out = <_Group>[];
    var d = 0, kLo = 1;
    for (var k = 1; k <= queue.length - index; k++) {
      final next = d | 1 << queue[index + k - 1];
      if (next != d && k > 1) {
        out.add(_Group(_tablesFor(d), kLo, k - 1));
        kLo = k;
      }
      d = next;
    }
    out.add(_Group(_tablesFor(d), kLo, queue.length - index));
    return out;
  }

  _Tables _tablesFor(int d) => _byValues[d] ??= _Tables(d, _open);
}

/// The targets k in [kLo]..[kHi] of one queue index, which share the
/// value set of `q[i..i+k)` and so its [tables].
final class _Group {
  _Group(this.tables, this.kLo, this.kHi);

  final _Tables tables;
  final int kLo, kHi;
}

/// The closure tables of one value set D (see [_CascadeBound]).
final class _Tables {
  _Tables(int d, int open) : maxValue = d.bitLength - 1 {
    // Ascending x: every pip a step lands on is below x, so its entries
    // are already final.
    for (var x = 1; x <= 25; x++) {
      var m = x, v = 0;
      for (var die = 1; die <= 6; die++) {
        final y = x - die;
        if (y >= 1 && (open >> y) & 1 == 1) {
          v |= 1 << die;
          if ((d >> die) & 1 == 1) {
            if (min[y] < m) m = min[y];
            v |= values[y];
          }
        }
      }
      min[x] = m;
      values[x] = v;
    }
  }

  /// m0(x) = min C(x), x in 1..25.
  final min = List.filled(26, 0);

  /// The values with an open (non-bear-off) step from some pip of C(x).
  final values = List.filled(26, 0);

  /// The highest value in D.
  final int maxValue;
}
