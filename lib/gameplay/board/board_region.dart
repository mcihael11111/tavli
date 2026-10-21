/// Places on the drawn board, in view terms (not player-relative pips).
///
/// The `ViewTransform` maps a side's pip to one of these and back; the
/// `BoardLayout` maps them to screen geometry and hit-tests a touch to one.
library;

/// The half of the board as drawn: the local viewer always owns the
/// [bottom] bar pile and bear-off tray, the opponent the [top] ones.
enum ViewEdge { bottom, top }

/// A place on the drawn board.
sealed class BoardRegion {
  const BoardRegion();
}

/// A point column. [viewPoint] 0..23 runs the legacy board order:
/// 0 is bottom-right, 11 bottom-left, 12 top-left and 23 top-right.
final class PointRegion extends BoardRegion {
  const PointRegion(this.viewPoint)
      : assert(viewPoint >= 0 && viewPoint < 24, 'view point $viewPoint');
  final int viewPoint;

  /// The top row (12..23) hangs its triangles down from the top edge.
  bool get isTop => viewPoint >= 12;

  @override
  bool operator ==(Object other) =>
      other is PointRegion && other.viewPoint == viewPoint;

  @override
  int get hashCode => viewPoint.hashCode;

  @override
  String toString() => 'PointRegion($viewPoint)';
}

/// The bar pile of the side drawn at [edge].
final class BarRegion extends BoardRegion {
  const BarRegion(this.edge);
  final ViewEdge edge;

  @override
  bool operator ==(Object other) => other is BarRegion && other.edge == edge;

  @override
  int get hashCode => edge.hashCode;

  @override
  String toString() => 'BarRegion(${edge.name})';
}

/// The bear-off tray of the side drawn at [edge].
final class TrayRegion extends BoardRegion {
  const TrayRegion(this.edge);
  final ViewEdge edge;

  @override
  bool operator ==(Object other) => other is TrayRegion && other.edge == edge;

  @override
  int get hashCode => edge.hashCode;

  @override
  String toString() => 'TrayRegion(${edge.name})';
}

/// The dice area (tap swaps the active die).
final class DiceRegion extends BoardRegion {
  const DiceRegion();

  @override
  bool operator ==(Object other) => other is DiceRegion;

  @override
  int get hashCode => (DiceRegion).hashCode;

  @override
  String toString() => 'DiceRegion()';
}
