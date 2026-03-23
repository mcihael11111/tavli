import 'package:equatable/equatable.dart';
import '../../../../core/constants/game_constants.dart';

/// A single checker move using one die value.
class Move extends Equatable {
  /// Source point index (0-23), or [GameConstants.barIndex] for bar entry.
  final int fromPoint;

  /// Destination point index (0-23), or [GameConstants.bearOffIndex] for bear-off.
  final int toPoint;

  /// The die value used for this move.
  final int dieUsed;

  /// Whether this move hits an opponent's blot.
  final bool isHit;

  const Move({
    required this.fromPoint,
    required this.toPoint,
    required this.dieUsed,
    this.isHit = false,
  });

  /// Whether this move enters a checker from the bar.
  bool get isBarEntry => fromPoint == GameConstants.barIndex;

  /// Whether this move bears off a checker.
  bool get isBearOff => toPoint == GameConstants.bearOffIndex;

  Move copyWith({
    int? fromPoint,
    int? toPoint,
    int? dieUsed,
    bool? isHit,
  }) {
    return Move(
      fromPoint: fromPoint ?? this.fromPoint,
      toPoint: toPoint ?? this.toPoint,
      dieUsed: dieUsed ?? this.dieUsed,
      isHit: isHit ?? this.isHit,
    );
  }

  @override
  List<Object?> get props => [fromPoint, toPoint, dieUsed, isHit];

  @override
  String toString() =>
      'Move($fromPoint→$toPoint, die=$dieUsed${isHit ? ', HIT' : ''})';
}
