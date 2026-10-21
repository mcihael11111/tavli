import 'package:tavli_core/tavli_core.dart';

import 'board_region.dart';

/// Maps a side's player-relative pip (matrix §1: 24..1 on the board,
/// 25 the bar, 0 borne off) to where it is drawn, and back.
///
/// The local [viewer] is drawn as the legacy board drew player 1: their
/// home (pips 1..6) is the bottom-right quarter (view points 0..5), their
/// pip 24 is top-right (view point 23), and their bar pile and tray are on
/// the [ViewEdge.bottom]. The opponent's pips are placed through the
/// variant's [Geometry] ([Direction.opposing]: home top-right;
/// [Direction.same]: home top-left, start bottom-left). Pass & play flips
/// the view by making [Side.two] the viewer.
class ViewTransform {
  const ViewTransform({required this.direction, this.viewer = Side.one});

  final Direction direction;

  /// The side whose home is drawn bottom-right.
  final Side viewer;

  /// Whether the board is drawn from side two's seat (pass & play).
  bool get flipped => viewer == Side.two;

  Geometry get geometry => Geometry.of(direction);

  /// The same board drawn from [viewer]'s seat.
  ViewTransform withViewer(Side viewer) =>
      ViewTransform(direction: direction, viewer: viewer);

  /// The view point 0..23 of [side]'s [pip] (1..24).
  int viewPoint(Side side, int pip) {
    RangeError.checkValueInInterval(pip, 1, 24, 'pip');
    final viewerPip = side == viewer ? pip : geometry.toOpponent(pip);
    return viewerPip - 1;
  }

  /// [side]'s pip (1..24) at [viewPoint] (0..23); inverse of [viewPoint].
  int pipAt(Side side, int viewPoint) {
    RangeError.checkValueInInterval(viewPoint, 0, 23, 'viewPoint');
    final viewerPip = viewPoint + 1;
    // Geometry.toOpponent is an involution, so it is its own inverse.
    return side == viewer ? viewerPip : geometry.toOpponent(viewerPip);
  }

  /// The edge holding [side]'s bar pile and bear-off tray.
  ViewEdge edgeOf(Side side) => side == viewer ? ViewEdge.bottom : ViewEdge.top;

  /// The side whose bar pile and tray are drawn at [edge].
  Side sideAt(ViewEdge edge) =>
      edge == ViewEdge.bottom ? viewer : viewer.opponent;

  /// Where [side]'s checkers on [pip] (0..25) are drawn.
  BoardRegion locate(Side side, int pip) {
    RangeError.checkValueInInterval(pip, 0, 25, 'pip');
    if (pip == 0) return TrayRegion(edgeOf(side));
    if (pip == 25) return BarRegion(edgeOf(side));
    return PointRegion(viewPoint(side, pip));
  }

  /// [side]'s pip for a touched [region]: 1..24 for a point, 25 for its
  /// own bar, 0 for its own tray; null for the dice or the opponent's
  /// bar or tray. Inverse of [locate].
  int? pipOf(Side side, BoardRegion region) => switch (region) {
        PointRegion(:final viewPoint) => pipAt(side, viewPoint),
        BarRegion(:final edge) => edge == edgeOf(side) ? 25 : null,
        TrayRegion(:final edge) => edge == edgeOf(side) ? 0 : null,
        DiceRegion() => null,
      };

  @override
  bool operator ==(Object other) =>
      other is ViewTransform &&
      other.direction == direction &&
      other.viewer == viewer;

  @override
  int get hashCode => Object.hash(direction, viewer);

  @override
  String toString() => 'ViewTransform(${direction.name}, ${viewer.name})';
}
