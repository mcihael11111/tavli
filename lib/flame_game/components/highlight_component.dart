import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle, TextDirection, FontWeight;
import '../../core/constants/colors.dart';
import '../../core/constants/game_constants.dart';
import '../../features/game/domain/engine/move_quality.dart';
import 'board_layout.dart';

/// Re-export for convenience.
export '../../features/game/domain/engine/move_quality.dart';

/// Move destination highlight using filled triangles (matching the board points).
///
/// For standard points (0-23), fills the triangle with bright green.
/// For bear-off (-2), falls back to a glowing oval.
/// In teaching mode, the border color reflects move quality:
/// gold = best, silver = good, bronze = acceptable, dim = poor.
class HighlightComponent extends PositionComponent with TapCallbacks {
  final int pointIndex;
  final int dieValue;
  final bool isHit;
  final BoardLayout boardLayout;
  final MoveQuality? quality;
  final void Function()? onTap;

  /// Triangle vertices in local coordinates (set in onLoad).
  late final List<Offset> _localVerts;
  late final Path _trianglePath;
  late final bool _isBearOff;

  /// Badge position (tip of triangle for standard points, center for bear-off).
  late final Offset _badgeCenter;

  HighlightComponent({
    required this.pointIndex,
    required this.dieValue,
    this.isHit = false,
    required this.boardLayout,
    this.quality,
    this.onTap,
  }) : super();

  @override
  Future<void> onLoad() async {
    _isBearOff = pointIndex == GameConstants.bearOffIndex;

    if (_isBearOff) {
      // Bear-off: position as an oval at the bear-off tray.
      final pos = boardLayout.checkerPosition(-2, 0, 1);
      final r = boardLayout.checkerRadius * 0.85;
      position = Vector2(pos.x - r, pos.y - r);
      size = Vector2(r * 2, r * 2);
      _localVerts = [];
      _trianglePath = Path();
      _badgeCenter = Offset(r, r);
    } else {
      // Standard point: compute triangle from board layout.
      final verts = boardLayout.pointTriangle(pointIndex);

      // Compute bounding box.
      double minX = verts[0].x, maxX = verts[0].x;
      double minY = verts[0].y, maxY = verts[0].y;
      for (final v in verts) {
        if (v.x < minX) minX = v.x;
        if (v.x > maxX) maxX = v.x;
        if (v.y < minY) minY = v.y;
        if (v.y > maxY) maxY = v.y;
      }

      // Add padding for the glow effect.
      const pad = 4.0;
      position = Vector2(minX - pad, minY - pad);
      size = Vector2(maxX - minX + pad * 2, maxY - minY + pad * 2);

      // Convert to local coordinates.
      _localVerts = verts
          .map((v) => Offset(v.x - minX + pad, v.y - minY + pad))
          .toList();

      _trianglePath = Path()
        ..moveTo(_localVerts[0].dx, _localVerts[0].dy)
        ..lineTo(_localVerts[1].dx, _localVerts[1].dy)
        ..lineTo(_localVerts[2].dx, _localVerts[2].dy)
        ..close();

      // Badge at the tip (third vertex = the point of the triangle).
      _badgeCenter = _localVerts[2];
    }

    // Pulsing effect.
    add(OpacityEffect.to(
      0.5,
      EffectController(
        duration: 0.9,
        reverseDuration: 0.9,
        infinite: true,
      ),
    ));
  }

  /// Fill color — green for normal moves, red-tinted for hits.
  Color get _fillColor {
    if (isHit) return TavliColors.moveHighlightHit;
    return TavliColors.moveHighlight;
  }

  /// Border color — quality-coded in teaching mode.
  Color get _borderColor {
    if (isHit) return TavliColors.moveHighlightHit;
    if (quality == null) return _fillColor;
    return switch (quality!) {
      MoveQuality.best => TavliColors.surface,              // Gold
      MoveQuality.good => const Color(0xFFA8A8A8),          // Silver
      MoveQuality.acceptable => const Color(0xFFCD7F32),    // Bronze
      MoveQuality.poor => const Color(0xFF808080),           // Dim grey
    };
  }

  @override
  void render(Canvas canvas) {
    if (_isBearOff) {
      _renderBearOffHighlight(canvas);
      return;
    }

    // ── Filled triangle ────────────────────────────────────────
    canvas.drawPath(
      _trianglePath,
      Paint()..color = _fillColor.withValues(alpha: 0.45),
    );

    // ── Soft glow behind triangle ──────────────────────────────
    canvas.drawPath(
      _trianglePath,
      Paint()
        ..color = _fillColor.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // ── Border stroke (quality-coded) ──────────────────────────
    canvas.drawPath(
      _trianglePath,
      Paint()
        ..color = _borderColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // ── Die value badge near the tip ───────────────────────────
    if (dieValue > 0) {
      _drawDieBadge(canvas, _badgeCenter);
    }

    // ── Hit marker ─────────────────────────────────────────────
    if (isHit) {
      // Center of the triangle.
      final cx = (_localVerts[0].dx + _localVerts[1].dx + _localVerts[2].dx) / 3;
      final cy = (_localVerts[0].dy + _localVerts[1].dy + _localVerts[2].dy) / 3;
      final xPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      const s = 6.0;
      canvas.drawLine(Offset(cx - s, cy - s), Offset(cx + s, cy + s), xPaint);
      canvas.drawLine(Offset(cx + s, cy - s), Offset(cx - s, cy + s), xPaint);
    }
  }

  void _renderBearOffHighlight(Canvas canvas) {
    final r = size.x / 2;
    final cx = r;
    final cy = r;
    final eh = r * 0.35;

    final color = _fillColor;

    // Soft glow.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: r * 2.2, height: eh * 2.2),
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Solid indicator.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: r * 1.4, height: eh * 1.4),
      Paint()..color = color.withValues(alpha: 0.5),
    );

    // Ring.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: r * 1.6, height: eh * 1.6),
      Paint()
        ..color = _borderColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Die badge.
    if (dieValue > 0) {
      _drawDieBadge(canvas, Offset(cx, cy));
    }
  }

  void _drawDieBadge(Canvas canvas, Offset center) {
    const badgeR = 10.0;
    final badgeColor = isHit ? TavliColors.moveHighlightHit : _fillColor;

    // Badge background.
    canvas.drawCircle(center, badgeR, Paint()..color = badgeColor);
    canvas.drawCircle(
      center,
      badgeR,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Die value text.
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$dieValue',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool containsPoint(Vector2 point) {
    if (_isBearOff) {
      // Use simple circular hit test for bear-off.
      final r = size.x / 2;
      final local = point - position;
      return (local - Vector2(r, r)).length <= r;
    }

    // Point-in-triangle test for standard points.
    final local = point - position;
    return _trianglePath.contains(Offset(local.x, local.y));
  }

  @override
  void onTapUp(TapUpEvent event) {
    onTap?.call();
  }
}
