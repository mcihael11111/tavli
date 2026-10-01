/// Immutable board position in player-relative pips (design spec §3.2).
library;

import 'dart:typed_data';

import '../variant/variant_rules.dart';
import 'board_view.dart';
import 'geometry.dart';
import 'side.dart';

part 'mutable_position.dart';
part 'position_json.dart';
part 'position_reads.dart';
part 'position_validation.dart';

const int _stride = 26; // pips 0..25 per side
const int _checkers = 15;

/// An immutable position: per side, checker counts on own pips 0..25
/// (0 = borne off, 25 = bar) plus a pinned bitmask over pips 1..24
/// (bit p set => this side's checker on its pip p is pinned).
///
/// Equality is structural; [hashCode] is cached and web-safe (< 2^30).
final class Position with _PositionReads implements BoardView {
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
    _validateBoard(p);
    return p;
  }

  /// The start position for [layout] (both sides alike).
  ///
  /// Asserts that [layout] fits [direction]: `stackDiagonal` is the only
  /// same-direction layout (matrix §1).
  factory Position.start(Layout layout, Direction direction) {
    assert(
      (layout == Layout.stackDiagonal) == (direction == Direction.same),
      '$layout does not fit $direction',
    );
    final side = layout == Layout.standard2535
        ? const {24: 2, 13: 5, 8: 3, 6: 5}
        : const {24: 15};
    return Position.fromPips(one: side, two: side, direction: direction);
  }

  /// The start position for a variant's [rules].
  factory Position.forRules(VariantRules rules) =>
      Position.start(rules.layout, rules.direction);

  /// Parses [toJson] output (schema v1). Throws only [FormatException] for
  /// any bad payload, including a well-formed but invalid position.
  static Position fromJson(Map<String, Object?> j) => _positionFromJson(j);

  /// Schema v1 (see `tavliCoreSchemaVersion`). All keys are required:
  /// - `direction`: `"opposing"` or `"same"`;
  /// - `one`, `two`: 26 ints each, counts by own pip 0..25 (0 = off,
  ///   25 = bar), each side totalling 15;
  /// - `pinnedOne`, `pinnedTwo`: ascending distinct pinned pips in 1..24.
  Map<String, Object?> toJson() => {
        'direction': direction.name,
        'one': List<int>.generate(_stride, (i) => _counts[i]),
        'two': List<int>.generate(_stride, (i) => _counts[_stride + i]),
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
}
