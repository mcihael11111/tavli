import 'dart:math' as math;
import 'dart:ui';

import 'board_calibration.dart';
import 'board_region.dart';

/// Screen geometry of the board for one game size (design §4.1): pure,
/// immutable, recomputed only on resize.
///
/// The board image is contain-fit and centred in [size]; every position is
/// derived from the measured paint in [BoardCalibration]. Points are
/// addressed by view point (see [PointRegion]); a `ViewTransform` maps a
/// side's pips to view points and edges.
class BoardLayout {
  /// [sliverAspect] is the width / height of the vertical (on-edge)
  /// checker's visible content in the asset atlas, so bear-off slivers
  /// keep their real aspect.
  factory BoardLayout(Size size, {required double sliverAspect}) {
    final fitWidth = size.width / size.height < BoardCalibration.aspect;
    final w = fitWidth ? size.width : size.height * BoardCalibration.aspect;
    final h = fitWidth ? size.width / BoardCalibration.aspect : size.height;
    final image =
        Rect.fromLTWH((size.width - w) / 2, (size.height - h) / 2, w, h);
    final sx = w / BoardCalibration.width, sy = h / BoardCalibration.height;
    final pointWidth = BoardCalibration.spacingLeft * sx;
    final radius = pointWidth * BoardCalibration.checkerRadiusPerPoint;
    final dieSize = radius * BoardCalibration.dieSizePerRadius;
    final sliverH =
        (BoardCalibration.topTrayBottom - BoardCalibration.topTrayTop) *
            sy *
            BoardCalibration.sliverHeightPerTray;
    final sliverSize = Size(sliverH * sliverAspect, sliverH);
    final trayWidth =
        (BoardCalibration.trayRight - BoardCalibration.trayLeft) * sx;
    return BoardLayout._(
      size: size,
      imageRect: image,
      sliverAspect: sliverAspect,
      sx: sx,
      sy: sy,
      pointWidth: pointWidth,
      pointHeight: BoardCalibration.triangleHeight * sy,
      checkerRadius: radius,
      stackStep: radius * 2 * BoardCalibration.stackOverlap,
      dieSize: dieSize,
      diceGap: dieSize * BoardCalibration.diceGapPerDie,
      sliverSize: sliverSize,
      sliverStep: math.min(
          sliverSize.width * BoardCalibration.sliverStepPerWidth,
          trayWidth / 15),
    );
  }

  BoardLayout._({
    required this.size,
    required this.imageRect,
    required this.sliverAspect,
    required double sx,
    required double sy,
    required this.pointWidth,
    required this.pointHeight,
    required this.checkerRadius,
    required this.stackStep,
    required this.dieSize,
    required this.diceGap,
    required this.sliverSize,
    required this.sliverStep,
  })  : _sx = sx,
        _sy = sy;

  /// Minimum width of the bar hit band, in logical pixels (a 48 dp
  /// touch target).
  static const double minBarHitWidth = 48;

  final Size size;

  /// Where the board image is drawn (contain-fit, centred).
  final Rect imageRect;

  /// Width / height of a bear-off sliver's visible content.
  final double sliverAspect;

  final double _sx, _sy;

  /// Point spacing used for disc sizing (the smaller, left-half spacing).
  final double pointWidth;

  /// Triangle length (base to tip).
  final double pointHeight;

  /// Visible checker disc radius.
  final double checkerRadius;

  /// Uncompressed centre-to-centre step of a stack.
  final double stackStep;

  /// Visible die face edge and the gap between dice.
  final double dieSize, diceGap;

  /// Visible size of one bear-off sliver and the step between slivers.
  final Size sliverSize;
  final double sliverStep;

  double _x(double px) => imageRect.left + px * _sx;
  double _y(double px) => imageRect.top + px * _sy;

  /// Playing region (frame included, tray strips excluded).
  Rect get boardRect => Rect.fromLTRB(
      imageRect.left,
      _y(BoardCalibration.boardTop),
      imageRect.right,
      _y(BoardCalibration.boardBottom));

  double get topBaseY => _y(BoardCalibration.topBaseY);
  double get bottomBaseY => _y(BoardCalibration.bottomBaseY);

  /// Midpoint of the painted triangle bases: the visual centre of the bar.
  double get barCenterY => (topBaseY + bottomBaseY) / 2;
  double get barX => imageRect.center.dx;

  /// The red tray strip at [edge].
  Rect trayRect(ViewEdge edge) => edge == ViewEdge.top
      ? Rect.fromLTRB(
          _x(BoardCalibration.trayLeft),
          _y(BoardCalibration.topTrayTop),
          _x(BoardCalibration.trayRight),
          _y(BoardCalibration.topTrayBottom))
      : Rect.fromLTRB(
          _x(BoardCalibration.trayLeft),
          _y(BoardCalibration.bottomTrayTop),
          _x(BoardCalibration.trayRight),
          _y(BoardCalibration.bottomTrayBottom));

  static bool _isTop(int viewPoint) => viewPoint >= 12;

  /// 0 = rightmost column of its row, 11 = leftmost.
  static int _column(int viewPoint) =>
      _isTop(viewPoint) ? 23 - viewPoint : viewPoint;

  double _centerX(int column) => column < 6
      ? _x(BoardCalibration.rightmostCenterX -
          column * BoardCalibration.spacingRight)
      : _x(BoardCalibration.leftmostCenterX +
          (11 - column) * BoardCalibration.spacingLeft);

  double _halfSpacing(int column) =>
      (column < 6
          ? BoardCalibration.spacingRight
          : BoardCalibration.spacingLeft) *
      _sx /
      2;

  /// Centre of [viewPoint]'s triangle base (where its stack starts).
  Offset pointBase(int viewPoint) {
    RangeError.checkValueInInterval(viewPoint, 0, 23, 'viewPoint');
    return Offset(_centerX(_column(viewPoint)),
        _isTop(viewPoint) ? topBaseY : bottomBaseY);
  }

  /// [viewPoint]'s triangle: base left, base right, tip.
  List<Offset> pointTriangle(int viewPoint) {
    final base = pointBase(viewPoint);
    final half = pointWidth / 2;
    final tipY =
        _isTop(viewPoint) ? base.dy + pointHeight : base.dy - pointHeight;
    return [
      Offset(base.dx - half, base.dy),
      Offset(base.dx + half, base.dy),
      Offset(base.dx, tipY),
    ];
  }

  /// The step between checkers in a pile of [total]. Above
  /// [BoardCalibration.maxUncompressed] the step shrinks so the pile keeps
  /// the span of a 7-pile: the top checker never moves further out (the
  /// legacy `step × 7 / total` still grew the pile to 15).
  double stackOffset(int total) {
    const n = BoardCalibration.maxUncompressed;
    return total <= n ? stackStep : stackStep * (n - 1) / (total - 1);
  }

  /// Centre of checker [index] (0 = on the base) of [total] on [viewPoint].
  Offset checkerCenter(int viewPoint, int index, int total) {
    _checkStack(index, total);
    final base = pointBase(viewPoint);
    final d = checkerRadius + index * stackOffset(total);
    return Offset(base.dx, _isTop(viewPoint) ? base.dy + d : base.dy - d);
  }

  /// Centre of bar checker [index] of [total] on [edge]'s pile: it starts a
  /// diameter from [barCenterY] (the inlay and the cube stay visible) and
  /// grows towards [edge].
  Offset barSlot(ViewEdge edge, int index, int total) {
    _checkStack(index, total);
    final d = checkerRadius * 2 + index * stackOffset(total);
    return Offset(
        barX, edge == ViewEdge.bottom ? barCenterY + d : barCenterY - d);
  }

  /// Visible rect of borne-off sliver [index] (0..14) in [edge]'s tray:
  /// a 15-slot row centred on the tray.
  Rect traySlot(ViewEdge edge, int index) {
    RangeError.checkValueInInterval(index, 0, 14, 'index');
    final tray = trayRect(edge);
    final c = Offset(tray.center.dx + (index - 7) * sliverStep, tray.center.dy);
    return Rect.fromCenter(
        center: c, width: sliverSize.width, height: sliverSize.height);
  }

  /// Centre of the dice area.
  Offset get diceAreaCenter => Offset(
      imageRect.left + imageRect.width * BoardCalibration.diceCenterXFrac,
      boardRect.center.dy);

  /// Centre of die [index] of [count] (1..4) laid in a row.
  Offset diceCenter(int index, int count) {
    RangeError.checkValueInInterval(count, 1, 4, 'count');
    RangeError.checkValueInInterval(index, 0, count - 1, 'index');
    final step = dieSize + diceGap;
    return diceAreaCenter.translate((index - (count - 1) / 2) * step, 0);
  }

  /// Hit area of the dice (room for four dice).
  Rect get diceRect => Rect.fromCenter(
      center: diceAreaCenter,
      width: 4 * dieSize + 4 * diceGap,
      height: dieSize + diceGap);

  /// The doubling cube's spot: the bar centre-line, between the piles.
  Offset get cubeSpot => Offset(barX, barCenterY);

  /// The whole column of [viewPoint] for hit-testing: half a spacing either
  /// side of its centre (outer columns reach the image edge), from the board
  /// edge to [barCenterY], so the triangle and its tip are inside.
  Rect columnRect(int viewPoint) {
    RangeError.checkValueInInterval(viewPoint, 0, 23, 'viewPoint');
    final col = _column(viewPoint);
    final cx = _centerX(col);
    final half = _halfSpacing(col);
    final left = col == 11 ? imageRect.left : cx - half;
    final right = col == 0 ? imageRect.right : cx + half;
    return _isTop(viewPoint)
        ? Rect.fromLTRB(left, boardRect.top, right, barCenterY)
        : Rect.fromLTRB(left, barCenterY, right, boardRect.bottom);
  }

  /// The bar hit band, split at [barCenterY]: the painted gap between the
  /// halves, widened about [barX] to at least a checker diameter, and to
  /// [minBarHitWidth] where that still leaves the innermost columns' stack
  /// centre lines (with half a radius of margin) to the columns. On phone
  /// widths the 48 px floor would swallow view point 6's stack (its centre
  /// is only ~0.057 × image width from the bar), so it is capped there.
  /// The band overlaps the inner columns' edges and is tested before them.
  Rect barRect(ViewEdge edge) {
    final painted =
        (_centerX(5) - _halfSpacing(5)) - (_centerX(6) + _halfSpacing(6));
    final nearest = math.min(_centerX(5) - barX, barX - _centerX(6));
    final room = 2 * (nearest - checkerRadius / 2);
    final width = math.max(
        math.max(painted, checkerRadius * 2), math.min(minBarHitWidth, room));
    final left = barX - width / 2, right = barX + width / 2;
    return edge == ViewEdge.top
        ? Rect.fromLTRB(left, boardRect.top, right, barCenterY)
        : Rect.fromLTRB(left, barCenterY, right, boardRect.bottom);
  }

  /// The tray strip hit area: the full image width above / below the board.
  Rect trayHitRect(ViewEdge edge) => edge == ViewEdge.top
      ? Rect.fromLTRB(
          imageRect.left, imageRect.top, imageRect.right, boardRect.top)
      : Rect.fromLTRB(
          imageRect.left, boardRect.bottom, imageRect.right, imageRect.bottom);

  /// The region under [p], or null off the board image. Precedence: dice
  /// (it lies between the tips), trays, bar band, then point columns.
  BoardRegion? columnAt(Offset p) {
    if (!imageRect.contains(p)) return null;
    if (diceRect.contains(p)) return const DiceRegion();
    for (final e in ViewEdge.values) {
      if (trayHitRect(e).contains(p)) return TrayRegion(e);
    }
    final top = p.dy < barCenterY;
    final edge = top ? ViewEdge.top : ViewEdge.bottom;
    if (barRect(edge).contains(p)) return BarRegion(edge);
    final right = p.dx >= barX;
    for (var col = 0; col < 12; col++) {
      if ((col < 6) != right) continue;
      final vp = top ? 23 - col : col;
      final r = columnRect(vp);
      if (p.dx >= r.left && p.dx < r.right) return PointRegion(vp);
    }
    return null;
  }

  static void _checkStack(int index, int total) {
    RangeError.checkValueInInterval(total, 1, 15, 'total');
    RangeError.checkValueInInterval(index, 0, total - 1, 'index');
  }
}
