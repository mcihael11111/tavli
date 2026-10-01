/// Immutable board position in player-relative pips (design spec §3.2).
library;

import 'dart:typed_data';

import '../variant/variant_rules.dart';
import 'geometry.dart';
import 'side.dart';

part 'mutable_position.dart';
part 'position_reads.dart';

const int _stride = 26; // pips 0..25 per side
const int _checkers = 15;

/// An immutable position: per side, checker counts on own pips 0..25
/// (0 = borne off, 25 = bar) plus a pinned bitmask over pips 1..24
/// (bit p set => this side's checker on its pip p is pinned).
///
/// Equality is structural; [hashCode] is cached and web-safe (< 2^30).
final class Position with _PositionReads {
  @override
  final Direction direction;
  @override
  final Uint8List _counts;
  @override
  final int _pinnedOne;
  @override
  final int _pinnedTwo;
  int? _hash;

  Position._(this.direction, this._counts, this._pinnedOne, this._pinnedTwo);

  /// Builds a validated position from own-pip maps (keys 1..24 only).
  ///
  /// Borne-off counts are derived: `15 - (sum + bar)`. Throws [ArgumentError]
  /// if a side exceeds 15 checkers, a count is negative, a key is outside
  /// 1..24, a physical point holds both sides without a pin, or a pinned pip
  /// does not hold exactly one owner checker under at least one pinner.
  factory Position.fromPips({
    required Map<int, int> one,
    required Map<int, int> two,
    int barOne = 0,
    int barTwo = 0,
    Set<int> pinnedOne = const {},
    Set<int> pinnedTwo = const {},
    required Direction direction,
  }) {
    final counts = Uint8List(2 * _stride);
    _fillSide(counts, 0, one, barOne, 'one');
    _fillSide(counts, _stride, two, barTwo, 'two');
    final p = Position._(
      direction,
      counts,
      _maskOf(pinnedOne, 'pinnedOne'),
      _maskOf(pinnedTwo, 'pinnedTwo'),
    );
    p._validate();
    return p;
  }

  /// The start position for [layout] (both sides alike).
  factory Position.start(Layout layout, Direction direction) {
    final side = layout == Layout.standard2535
        ? const {24: 2, 13: 5, 8: 3, 6: 5}
        : const {24: 15};
    return Position.fromPips(one: side, two: side, direction: direction);
  }

  /// Parses [toJson] output. Throws [FormatException] on a malformed shape
  /// and [ArgumentError] on an invalid position.
  static Position fromJson(Map<String, Object?> j) {
    final dirName = j['direction'];
    final direction = Direction.values.where((d) => d.name == dirName);
    if (direction.isEmpty) {
      throw FormatException('Position: bad direction', dirName);
    }
    final counts = Uint8List(2 * _stride);
    for (final (i, key) in const ['one', 'two'].indexed) {
      final list = j[key];
      if (list is! List<Object?> || list.length != _stride) {
        throw FormatException('Position: "$key" must be $_stride counts', list);
      }
      var total = 0;
      for (var pip = 0; pip < _stride; pip++) {
        final c = list[pip];
        if (c is! int || c < 0 || c > _checkers) {
          throw FormatException('Position: bad count in "$key"', c);
        }
        counts[i * _stride + pip] = c;
        total += c;
      }
      if (total != _checkers) {
        throw ArgumentError.value(total, key, 'side must total $_checkers');
      }
    }
    final p = Position._(
      direction.first,
      counts,
      _maskOf(_pipList(j['pinnedOne'], 'pinnedOne'), 'pinnedOne'),
      _maskOf(_pipList(j['pinnedTwo'], 'pinnedTwo'), 'pinnedTwo'),
    );
    p._validate();
    return p;
  }

  Map<String, Object?> toJson() => {
        'direction': direction.name,
        'one': List<int>.of(_counts.sublist(0, _stride)),
        'two': List<int>.of(_counts.sublist(_stride)),
        'pinnedOne': _pipsOf(_pinnedOne),
        'pinnedTwo': _pipsOf(_pinnedTwo),
      };

  @override
  int get hashCode => _hash ??= _computeHash();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Position ||
        other.direction != direction ||
        other._pinnedOne != _pinnedOne ||
        other._pinnedTwo != _pinnedTwo ||
        other.hashCode != hashCode) {
      return false;
    }
    final a = _counts, b = other._counts;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    String side(Side s) {
      final parts = [
        for (var pip = 25; pip >= 0; pip--)
          if (count(s, pip) > 0)
            '${pip == 25 ? 'bar' : pip == 0 ? 'off' : pip}:${count(s, pip)}'
                '${isPinned(s, pip) ? '*' : ''}',
      ];
      return '{${parts.join(', ')}}';
    }

    return 'Position(${direction.name}, one: ${side(Side.one)}, '
        'two: ${side(Side.two)})';
  }

  // Jenkins one-at-a-time mixing with every intermediate kept < 2^30 so the
  // result is identical on the VM and on the web.
  int _computeHash() {
    var h = direction.index;
    for (var i = 0; i < _counts.length; i++) {
      h = _combine(h, _counts[i]);
    }
    h = _combine(h, _pinnedOne);
    h = _combine(h, _pinnedTwo);
    h = 0x1fffffff & (h + ((0x03ffffff & h) << 3));
    h ^= h >> 11;
    return 0x1fffffff & (h + ((0x00003fff & h) << 15));
  }

  static int _combine(int h, int v) {
    h = 0x1fffffff & (h + v);
    h = 0x1fffffff & (h + ((0x0007ffff & h) << 10));
    return h ^ (h >> 6);
  }

  /// Checks the cross-side invariants (§3.2). Totals are checked by callers.
  void _validate() {
    final g = Geometry.of(direction);
    for (var p = 1; p <= 24; p++) {
      final q = g.toOpponent(p);
      final m = _counts[p], o = _counts[_stride + q];
      final pinnedMine = (_pinnedOne >> p) & 1 == 1;
      final pinnedTheirs = (_pinnedTwo >> q) & 1 == 1;
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

  static void _fillSide(
    Uint8List counts,
    int base,
    Map<int, int> pips,
    int bar,
    String name,
  ) {
    var total = bar;
    if (bar < 0 || bar > _checkers) {
      throw ArgumentError.value(bar, 'bar ($name)', 'must be 0..$_checkers');
    }
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

  static int _maskOf(Iterable<int> pips, String name) {
    var mask = 0;
    for (final p in pips) {
      if (p < 1 || p > 24) {
        throw ArgumentError.value(p, name, 'pinned pips must be 1..24');
      }
      mask |= 1 << p;
    }
    return mask;
  }

  static List<int> _pipsOf(int mask) => [
        for (var p = 1; p <= 24; p++)
          if ((mask >> p) & 1 == 1) p,
      ];

  static List<int> _pipList(Object? v, String name) {
    if (v is! List<Object?> || v.any((e) => e is! int)) {
      throw FormatException('Position: "$name" must be a list of pips', v);
    }
    return v.cast<int>();
  }
}
