import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Simplified backgammon board diagram for tutorial illustrations.
///
/// Draws a schematic board with optional highlighted points, checkers,
/// and movement arrows. Much lighter than the full Flame rendering.
class MiniBoardPainter extends CustomPainter {
  /// Points with checkers: {pointIndex: (count, isPlayer1)}
  final Map<int, (int, bool)> checkers;

  /// Points to highlight (e.g., to show where to move).
  final Set<int> highlightedPoints;

  /// Arrows showing movement: (fromPoint, toPoint)
  final List<(int, int)> arrows;

  /// Points on the bar: (player1Count, player2Count)
  final (int, int) barCheckers;

  /// Whether to show point numbers.
  final bool showNumbers;

  MiniBoardPainter({
    this.checkers = const {},
    this.highlightedPoints = const {},
    this.arrows = const [],
    this.barCheckers = (0, 0),
    this.showNumbers = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final frameW = w * 0.03;
    final barW = w * 0.04;

    // Board background.
    final boardRect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect, const Radius.circular(4)),
      Paint()..color = const Color(0xFF8B4513),
    );

    // Playing surface.
    final surfaceRect = Rect.fromLTWH(frameW, frameW, w - frameW * 2, h - frameW * 2);
    canvas.drawRect(surfaceRect, Paint()..color = const Color(0xFFD4C06A));

    // Bar.
    final barX = w / 2 - barW / 2;
    canvas.drawRect(
      Rect.fromLTWH(barX, 0, barW, h),
      Paint()..color = const Color(0xFF8B4513),
    );

    // Draw points (triangles).
    final playW = (w - frameW * 2 - barW) / 2;
    final pointW = playW / 6;
    final pointH = (h - frameW * 2) * 0.40;

    for (int i = 0; i < 24; i++) {
      _drawPoint(canvas, i, w, h, frameW, barW, pointW, pointH);
    }

    // Draw checkers.
    for (final entry in checkers.entries) {
      _drawCheckers(canvas, entry.key, entry.value.$1, entry.value.$2,
          w, h, frameW, barW, pointW, pointH);
    }

    // Draw arrows.
    for (final arrow in arrows) {
      _drawArrow(canvas, arrow.$1, arrow.$2, w, h, frameW, barW, pointW, pointH);
    }

    // Draw point numbers.
    if (showNumbers) {
      _drawNumbers(canvas, w, h, frameW, barW, pointW);
    }
  }

  Offset _pointCenter(int index, double w, double h, double frameW,
      double barW, double pointW) {
    final isTop = index >= 12;
    final displayIdx = isTop ? (23 - index) : index;
    final isRight = displayIdx < 6;
    final idxInHalf = isRight ? (5 - displayIdx) : (displayIdx - 6);

    double x;
    if (isRight) {
      x = w / 2 + barW / 2 + idxInHalf * pointW + pointW / 2;
    } else {
      x = frameW + (5 - idxInHalf) * pointW + pointW / 2;
    }

    final y = isTop ? frameW + (h - frameW * 2) * 0.2 : h - frameW - (h - frameW * 2) * 0.2;
    return Offset(x, y);
  }

  void _drawPoint(Canvas canvas, int i, double w, double h, double frameW,
      double barW, double pointW, double pointH) {
    final isTop = i >= 12;
    final displayIdx = isTop ? (23 - i) : i;
    final isRight = displayIdx < 6;
    final idxInHalf = isRight ? (5 - displayIdx) : (displayIdx - 6);

    double x;
    if (isRight) {
      x = w / 2 + barW / 2 + idxInHalf * pointW;
    } else {
      x = frameW + (5 - idxInHalf) * pointW;
    }

    final isHighlighted = highlightedPoints.contains(i);
    final isA = i % 2 == 0;
    var color = isA ? const Color(0xFFB86B3A) : const Color(0xFF7A6B2C);
    if (isHighlighted) {
      color = const Color(0xFF9C6644).withValues(alpha: 0.8);
    }

    final path = Path();
    if (isTop) {
      path.moveTo(x, frameW);
      path.lineTo(x + pointW, frameW);
      path.lineTo(x + pointW / 2, frameW + pointH);
      path.close();
    } else {
      path.moveTo(x, h - frameW);
      path.lineTo(x + pointW, h - frameW);
      path.lineTo(x + pointW / 2, h - frameW - pointH);
      path.close();
    }

    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    if (isHighlighted) {
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF9C6644)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _drawCheckers(Canvas canvas, int pointIndex, int count, bool isPlayer1,
      double w, double h, double frameW, double barW, double pointW, double pointH) {
    final isTop = pointIndex >= 12;
    final center = _pointCenter(pointIndex, w, h, frameW, barW, pointW);
    final r = pointW * 0.35;

    final color = isPlayer1 ? const Color(0xFFF5EBD0) : const Color(0xFF3A2015);
    final border = isPlayer1 ? const Color(0xFFCBB888) : const Color(0xFF1E100A);

    final displayCount = count > 5 ? 5 : count;
    for (int j = 0; j < displayCount; j++) {
      final offset = isTop ? j * r * 1.2 : -j * r * 1.2;
      final cy = center.dy + offset;

      canvas.drawCircle(
        Offset(center.dx, cy),
        r,
        Paint()..color = color,
      );
      canvas.drawCircle(
        Offset(center.dx, cy),
        r,
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Count badge for 6+.
    if (count > 5) {
      final badgeY = isTop
          ? center.dy + displayCount * r * 1.2 - r * 0.6
          : center.dy - displayCount * r * 1.2 + r * 0.6;
      final tp = TextPainter(
        text: TextSpan(
          text: '$count',
          style: TextStyle(
            color: isPlayer1 ? Colors.black : Colors.white,
            fontSize: r * 0.8,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(center.dx - tp.width / 2, badgeY - tp.height / 2));
    }
  }

  void _drawArrow(Canvas canvas, int from, int to, double w, double h,
      double frameW, double barW, double pointW, double pointH) {
    final start = _pointCenter(from, w, h, frameW, barW, pointW);
    final end = _pointCenter(to, w, h, frameW, barW, pointW);

    final arrowPaint = Paint()
      ..color = const Color(0xFF9C6644)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(start, end, arrowPaint);

    // Arrowhead.
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    const headLen = 8.0;
    final p1 = Offset(
      end.dx - headLen * math.cos(angle - 0.5),
      end.dy - headLen * math.sin(angle - 0.5),
    );
    final p2 = Offset(
      end.dx - headLen * math.cos(angle + 0.5),
      end.dy - headLen * math.sin(angle + 0.5),
    );
    final headPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    canvas.drawPath(headPath, Paint()..color = const Color(0xFF9C6644));
  }

  void _drawNumbers(Canvas canvas, double w, double h, double frameW,
      double barW, double pointW) {
    for (int i = 0; i < 24; i++) {
      final center = _pointCenter(i, w, h, frameW, barW, pointW);
      final isTop = i >= 12;
      final numY = isTop ? h - frameW + 2 : frameW - 12;

      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 8,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(center.dx - tp.width / 2, numY));
    }
  }

  @override
  bool shouldRepaint(covariant MiniBoardPainter oldDelegate) =>
      checkers != oldDelegate.checkers ||
      highlightedPoints != oldDelegate.highlightedPoints ||
      arrows != oldDelegate.arrows;
}
