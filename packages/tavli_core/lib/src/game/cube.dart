/// The doubling cube (D7).
library;

import '../board/side.dart';

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
