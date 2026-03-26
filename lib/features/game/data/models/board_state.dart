import 'package:equatable/equatable.dart';
import '../../../../core/constants/game_constants.dart';
import '../../../../core/constants/variants/variant_rules.dart';
import '../../domain/engine/variants/game_variant.dart';

/// Immutable representation of the backgammon board.
///
/// Points are indexed 0-23.
/// - Positive values in [points] = player 1's checkers on that point.
/// - Negative values = player 2's checkers on that point.
///
/// Player 1 moves from high indices (23) toward low indices (0) and bears off from 0-5.
/// Player 2 moves from low indices (0) toward high indices (23) and bears off from 18-23.
class BoardState extends Equatable {
  /// 24 points. Positive = player 1 count, negative = player 2 count.
  final List<int> points;

  /// Player 1 checkers on the bar.
  final int bar1;

  /// Player 2 checkers on the bar.
  final int bar2;

  /// Player 1 checkers borne off.
  final int borneOff1;

  /// Player 2 checkers borne off.
  final int borneOff2;

  /// Current doubling cube value (1, 2, 4, 8, 16, 32, 64).
  final int doublingCubeValue;

  /// Owner of the doubling cube: 1, 2, or null (center/available to both).
  final int? cubeOwner;

  /// Whose turn it is: 1 or 2.
  final int activePlayer;

  /// Pinned point indices for Plakoto variant.
  /// Each entry maps a point index to the player number whose checker is pinned there.
  /// E.g., {5: 2} means player 2 has a pinned checker on point 5.
  final Map<int, int> pins;

  const BoardState({
    required this.points,
    this.bar1 = 0,
    this.bar2 = 0,
    this.borneOff1 = 0,
    this.borneOff2 = 0,
    this.doublingCubeValue = GameConstants.initialCubeValue,
    this.cubeOwner,
    this.activePlayer = 1,
    this.pins = const {},
  })  : assert(points.length == GameConstants.totalPoints),
        assert(bar1 >= 0),
        assert(bar2 >= 0),
        assert(borneOff1 >= 0),
        assert(borneOff2 >= 0);

  /// Standard initial board setup.
  factory BoardState.initial({int activePlayer = 1}) {
    final pts = List<int>.filled(24, 0);

    // Player 1 (positive): moves 23→0
    pts[23] = 2;
    pts[12] = 5;
    pts[7] = 3;
    pts[5] = 5;

    // Player 2 (negative): moves 0→23
    pts[0] = -2;
    pts[11] = -5;
    pts[16] = -3;
    pts[18] = -5;

    return BoardState(points: pts, activePlayer: activePlayer);
  }

  /// Empty board (for testing).
  factory BoardState.empty({int activePlayer = 1}) {
    return BoardState(
      points: List<int>.filled(24, 0),
      activePlayer: activePlayer,
    );
  }

  /// Create the correct initial board for any game variant.
  factory BoardState.forVariant(GameVariant variant, {int activePlayer = 1}) {
    final rules = variant.rules;
    switch (rules.startingPosition) {
      case StartingPosition.standard:
        return BoardState.initial(activePlayer: activePlayer);

      case StartingPosition.allOnOneOpposing:
        // Plakoto/Tapa/Mahbusa: all 15 on one point, opposing directions.
        final pts = List<int>.filled(24, 0);
        pts[rules.p1StartPoint] = 15;
        pts[rules.p2StartPoint] = -15;
        return BoardState(points: pts, activePlayer: activePlayer);

      case StartingPosition.allOnOneSameDirection:
        // Fevga/Nard/Moultezim: all 15 on one point, same direction.
        final pts = List<int>.filled(24, 0);
        pts[rules.p1StartPoint] = 15;
        pts[rules.p2StartPoint] = -15;
        return BoardState(points: pts, activePlayer: activePlayer);
    }
  }

  // ── Queries ────────────────────────────────────────────────────

  /// Number of checkers on the bar for [player] (1 or 2).
  int barCount(int player) => player == 1 ? bar1 : bar2;

  /// Number of checkers borne off for [player].
  int borneOffCount(int player) => player == 1 ? borneOff1 : borneOff2;

  /// How many of [player]'s checkers occupy [pointIndex].
  /// Returns a positive number or 0.
  int checkerCount(int pointIndex, int player) {
    final val = points[pointIndex];
    if (player == 1) return val > 0 ? val : 0;
    return val < 0 ? -val : 0;
  }

  /// Whether [pointIndex] is open for [player] to land on.
  /// A point is open if it has fewer than 2 of the opponent's checkers.
  bool isPointOpen(int pointIndex, int player) {
    final val = points[pointIndex];
    if (player == 1) return val >= -1; // at most 1 opponent checker
    return val <= 1;
  }

  /// Whether [pointIndex] has a blot (single opponent checker) for [player].
  bool isBlot(int pointIndex, int player) {
    final val = points[pointIndex];
    if (player == 1) return val == -1;
    return val == 1;
  }

  /// Whether all of [player]'s checkers are in their home board (or borne off).
  bool allInHome(int player) {
    if (barCount(player) > 0) return false;

    if (player == 1) {
      // Player 1 home = points 0-5. No checkers should be on 6-23.
      for (int i = 6; i < 24; i++) {
        if (points[i] > 0) return false;
      }
    } else {
      // Player 2 home = points 18-23. No checkers should be on 0-17.
      for (int i = 0; i < 18; i++) {
        if (points[i] < 0) return false;
      }
    }
    return true;
  }

  /// Total pip count for [player].
  int pipCount(int player) {
    int count = 0;
    if (player == 1) {
      count += bar1 * 25; // bar is effectively 25 pips away
      for (int i = 0; i < 24; i++) {
        if (points[i] > 0) count += points[i] * (i + 1);
      }
    } else {
      count += bar2 * 25;
      for (int i = 0; i < 24; i++) {
        if (points[i] < 0) count += (-points[i]) * (24 - i);
      }
    }
    return count;
  }

  // ── Mutation (returns new state) ───────────────────────────────

  /// Whether a checker is pinned at [pointIndex].
  bool isPinned(int pointIndex) => pins.containsKey(pointIndex);

  /// Which player's checker is pinned at [pointIndex], or null.
  int? pinnedPlayer(int pointIndex) => pins[pointIndex];

  BoardState copyWith({
    List<int>? points,
    int? bar1,
    int? bar2,
    int? borneOff1,
    int? borneOff2,
    int? doublingCubeValue,
    int? cubeOwner,
    int? activePlayer,
    Map<int, int>? pins,
  }) {
    return BoardState(
      points: points ?? List.of(this.points),
      bar1: bar1 ?? this.bar1,
      bar2: bar2 ?? this.bar2,
      borneOff1: borneOff1 ?? this.borneOff1,
      borneOff2: borneOff2 ?? this.borneOff2,
      doublingCubeValue: doublingCubeValue ?? this.doublingCubeValue,
      cubeOwner: cubeOwner,
      activePlayer: activePlayer ?? this.activePlayer,
      pins: pins ?? Map.of(this.pins),
    );
  }

  @override
  List<Object?> get props => [
        points,
        bar1,
        bar2,
        borneOff1,
        borneOff2,
        doublingCubeValue,
        cubeOwner,
        activePlayer,
        pins,
      ];

  @override
  String toString() {
    final buf = StringBuffer('BoardState(player=$activePlayer, ');
    buf.write('bar1=$bar1, bar2=$bar2, ');
    buf.write('off1=$borneOff1, off2=$borneOff2, ');
    buf.write('cube=$doublingCubeValue');
    if (cubeOwner != null) buf.write(' owner=$cubeOwner');
    buf.write(')');
    return buf.toString();
  }
}
