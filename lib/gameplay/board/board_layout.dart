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
    return BoardLayout._(size, image, sliverAspect);
  }

  BoardLayout._(this.size, this.imageRect, this.sliverAspect)
      : _sx = imageRect.width / BoardCalibration.width,
        _sy = imageRect.height / BoardCalibration.height {
    pointWidth = BoardCalibration.spacingLeft * _sx;
    pointHeight = BoardCalibration.triangleHeight * _sy;
    checkerRadius = pointWidth * BoardCalibration.checkerRadiusPerPoint;
    stackStep = checkerRadius * 2 * BoardCalibration.stackOverlap;
    dieSize = checkerRadius * BoardCalibration.dieSizePerRadius;
    diceGap = dieSize * BoardCalibration.diceGapPerDie;
    final sliverH = _trayHeight * BoardCalibration.sliverHeightPerTray;
    sliverSize = Size(sliverH * sliverAspect, sliverH);
    sliverStep = math.min(
        sliverSize.width * BoardCalibration.sliverStepPerWidth,
        _trayWidth / 15);
  }

  final Size size;

  /// Where the board image is drawn (contain-fit, centred).
  final Rect imageRect;

  /// Width / height of a bear-off sliver's visible content.
  final double sliverAspect;

  final double _sx, _sy;

  /// Point spacing used for disc sizing (the smaller, left-half spacing).
  late final double pointWidth;

  /// Triangle length (base to tip).
  late final double pointHeight;

  /// Visible checker disc radius.
  late final double checkerRadius;

  /// Uncompressed centre-to-centre step of a stack.
  late final double stackStep;

  /// Visible die face edge and the gap between dice.
  late final double dieSize, diceGap;

  /// Visible size of one bear-off sliver and the step between slivers.
  late final Size sliverSize;
  late final double sliverStep;

  double _x(double px) => imageRect.left + px * _sx;
  double _y(double px) => imageRect.top + px * _sy;

  double get _trayHeight =>
      (BoardCalibration.topTrayBottom - BoardCalibration.topTrayTop) * _sy;
  double get _trayWidth =>
      (BoardCalibration.trayRight - BoardCalibration.trayLeft) * _sx;

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

  /// The bar band between the halves, split at [barCenterY].
  Rect barRect(ViewEdge edge) {
    final left = _centerX(6) + _halfSpacing(6);
    final right = _centerX(5) - _halfSpacing(5);
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

  /// The region under [p], or null off the board image. The dice area
  /// wins over the columns it overlaps (it lies between the tips).
  BoardRegion? columnAt(Offset p) {
    if (!imageRect.contains(p)) return null;
    if (diceRect.contains(p)) return const DiceRegion();
    if (p.dy < boardRect.top) return const TrayRegion(ViewEdge.top);
    if (p.dy >= boardRect.bottom) return const TrayRegion(ViewEdge.bottom);
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
