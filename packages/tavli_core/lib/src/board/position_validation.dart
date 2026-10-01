part of 'position.dart';

/// Checks every invariant of §3.2 and throws [ArgumentError] on the first
/// violation:
/// - each side totals exactly 15 checkers (off + board + bar);
/// - pinned bits only on pips 1..24;
/// - a pinned pip holds exactly one owner checker under at least one pinner,
///   and a point is never pinned both ways;
/// - a physical point holds both sides only as a pinned pair.
///
/// Used by `fromPips`, `fromJson` and (in debug builds) `freeze`.
void _validateBoard(_PositionReads b) {
  final counts = b._counts;
  for (final s in Side.values) {
    var total = 0;
    for (var pip = 0; pip < _stride; pip++) {
      total += counts[s.index * _stride + pip];
    }
    if (total != _checkers) {
      throw ArgumentError.value(total, s.name, 'side must total $_checkers');
    }
  }
  const invalidBits = ~0x1FFFFFE; // anything outside bits 1..24
  if (b._pinnedOne & invalidBits != 0 || b._pinnedTwo & invalidBits != 0) {
    throw ArgumentError('pinned bits outside pips 1..24');
  }
  final g = Geometry.of(b.direction);
  for (var p = 1; p <= 24; p++) {
    final q = g.toOpponent(p);
    final m = counts[p], o = counts[_stride + q];
    final pinnedMine = (b._pinnedOne >> p) & 1 == 1;
    final pinnedTheirs = (b._pinnedTwo >> q) & 1 == 1;
    if (pinnedMine && pinnedTheirs) {
      throw ArgumentError('point one:$p/two:$q is pinned both ways');
    }
    if (pinnedMine && (m != 1 || o < 1)) {
      throw ArgumentError('one pinned on $p needs 1 checker under a pinner');
    }
    if (pinnedTheirs && (o != 1 || m < 1)) {
      throw ArgumentError('two pinned on $q needs 1 checker under a pinner');
    }
    if (m > 0 && o > 0 && !pinnedMine && !pinnedTheirs) {
      throw ArgumentError('point one:$p/two:$q holds both sides unpinned');
    }
  }
}

/// Writes one side's counts from an own-pip map; derives borne-off.
void _fillSide(
  Uint8List counts,
  int base,
  Map<int, int> pips,
  int bar,
  String name,
) {
  if (bar < 0 || bar > _checkers) {
    throw ArgumentError.value(bar, 'bar ($name)', 'must be 0..$_checkers');
  }
  var total = bar;
  for (final MapEntry(key: pip, value: n) in pips.entries) {
    if (pip < 1 || pip > 24) {
      throw ArgumentError.value(pip, name, 'pip keys must be 1..24');
    }
    if (n < 0 || n > _checkers) {
      throw ArgumentError.value(n, '$name[$pip]', 'must be 0..$_checkers');
    }
    counts[base + pip] = n;
    total += n;
  }
  if (total > _checkers) {
    throw ArgumentError.value(total, name, 'more than $_checkers checkers');
  }
  counts[base + 25] = bar;
  counts[base] = _checkers - total;
}

/// Bitmask of [pips] (each in 1..24).
int _maskOf(Iterable<int> pips, String name) {
  var mask = 0;
  for (final p in pips) {
    if (p < 1 || p > 24) {
      throw ArgumentError.value(p, name, 'pinned pips must be 1..24');
    }
    mask |= 1 << p;
  }
  return mask;
}
