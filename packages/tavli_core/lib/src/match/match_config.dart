/// Match configuration (plan Task 14).
library;

import '../serial/json_read.dart';
import '../variant/variant.dart';

/// What is played: the variant cycle, the target and the cube.
final class MatchConfig {
  /// The variants in order, repeating: `[v]` for one variant,
  /// [tavliMarathon] for Tavli. Unmodifiable, never empty.
  final List<Variant> cycle;

  /// Points to win; null for a single game.
  final int? target;

  /// Whether games use the cube (only where the variant has one).
  final bool cubeEnabled;

  /// The Greek Tavli marathon: Portes, Plakoto, Fevga in turn.
  static const tavliMarathon = [Variant.portes, Variant.plakoto, Variant.fevga];

  MatchConfig._(List<Variant> cycle, this.target, this.cubeEnabled)
      : cycle = List.unmodifiable(cycle);

  /// One game of [v]. A variant with a fixed target (Tawla 31, D21) is
  /// always a match to that target.
  factory MatchConfig.single(Variant v, {bool? cubeEnabled}) =>
      MatchConfig._build(null, [v], cubeEnabled);

  /// A match to [target] over [cycle]. A cycle with a fixed-target variant
  /// (Tawla 31) plays to that target instead. Throws [ArgumentError] for
  /// an empty cycle or a target below 1.
  factory MatchConfig.to(int target, List<Variant> cycle, {bool? cubeEnabled}) {
    if (target < 1) throw ArgumentError.value(target, 'target', 'below 1');
    return MatchConfig._build(target, cycle, cubeEnabled);
  }

  factory MatchConfig._build(int? target, List<Variant> cycle, bool? cube) {
    if (cycle.isEmpty) throw ArgumentError.value(cycle, 'cycle', 'empty');
    for (final v in cycle) {
      target = v.rules.match.fixedTarget ?? target;
    }
    return MatchConfig._(
      cycle,
      target,
      cube ?? cycle.any((v) => v.rules.cube.enabledByDefault),
    );
  }

  /// `{"cycle": [variant names], "target": int|null, "cubeEnabled": bool}`.
  Map<String, Object?> toJson() => {
        'cycle': [for (final v in cycle) v.name],
        'target': target,
        'cubeEnabled': cubeEnabled,
      };

  /// Parses [toJson] output. Throws only [FormatException]: the cycle must
  /// be non-empty, the target null or at least 1, and a fixed-target
  /// variant (Tawla 31) must come with its target.
  static MatchConfig fromJson(Object? json) {
    final r = JsonReader(json, 'MatchConfig');
    final cycle = [
      for (final name in r.list('cycle'))
        Variant.values.firstWhere(
          (v) => v.name == name,
          orElse: () => r.fail('cycle', 'a list of variant names'),
        ),
    ];
    if (cycle.isEmpty) r.fail('cycle', 'non-empty');
    final target = r.nullableInt('target', min: 1);
    for (final v in cycle) {
      final fixed = v.rules.match.fixedTarget;
      if (fixed != null && target != fixed) r.fail('target', '$fixed');
    }
    return MatchConfig._(cycle, target, r.boolean('cubeEnabled'));
  }

  @override
  bool operator ==(Object other) =>
      other is MatchConfig &&
      other.target == target &&
      other.cubeEnabled == cubeEnabled &&
      _listEq(other.cycle, cycle);

  @override
  int get hashCode => Object.hash(Object.hashAll(cycle), target, cubeEnabled);

  @override
  String toString() =>
      'MatchConfig(${cycle.map((v) => v.name).join(', ')}, to $target, '
      'cube $cubeEnabled)';
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
