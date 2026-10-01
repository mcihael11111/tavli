/// The doubling cube (D7).
library;

import '../board/side.dart';
import '../serial/json_read.dart';

/// The doubling cube of one game.
final class CubeState {
  /// 1..64.
  final int value;

  /// The side that may double next; null = centered (either may).
  final Side? owner;

  /// The side whose double awaits an answer, if any.
  final Side? offeredBy;

  /// Whether this game uses the cube at all.
  final bool enabled;

  const CubeState({
    this.value = 1,
    this.owner,
    this.offeredBy,
    required this.enabled,
  });

  /// A copy with the given fields replaced (use [clearOffer] to clear
  /// [offeredBy]).
  CubeState copyWith({int? value, Side? owner, Side? offeredBy}) => CubeState(
        value: value ?? this.value,
        owner: owner ?? this.owner,
        offeredBy: offeredBy ?? this.offeredBy,
        enabled: enabled,
      );

  /// A copy with no pending offer.
  CubeState clearOffer() =>
      CubeState(value: value, owner: owner, enabled: enabled);

  /// `{"value": int, "owner": side|null, "offeredBy": side|null,
  /// "enabled": bool}`.
  Map<String, Object?> toJson() => {
        'value': value,
        'owner': owner?.toJson(),
        'offeredBy': offeredBy?.toJson(),
        'enabled': enabled,
      };

  /// Parses [toJson] output. Throws only [FormatException]: the value must
  /// be a power of two in 1..64, and a disabled cube must be untouched.
  static CubeState fromJson(Object? json) {
    final r = JsonReader(json, 'CubeState');
    final value = r.integer('value', min: 1, max: 64);
    if (value & (value - 1) != 0) r.fail('value', 'a power of two');
    final c = CubeState(
      value: value,
      owner: r.nullableSide('owner'),
      offeredBy: r.nullableSide('offeredBy'),
      enabled: r.boolean('enabled'),
    );
    if (!c.enabled && c != const CubeState(enabled: false)) {
      r.fail('enabled', 'true for a cube in use');
    }
    return c;
  }

  @override
  bool operator ==(Object other) =>
      other is CubeState &&
      other.value == value &&
      other.owner == owner &&
      other.offeredBy == offeredBy &&
      other.enabled == enabled;

  @override
  int get hashCode => Object.hash(value, owner, offeredBy, enabled);

  @override
  String toString() => 'CubeState($value, owner: ${owner?.name}, '
      'offeredBy: ${offeredBy?.name}, enabled: $enabled)';
}
