import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle, TextDirection, FontWeight;
import '../../core/constants/colors.dart';
import '../rendering/lighting.dart';
import '../sprite_manager.dart';
import 'board_layout.dart';

/// 3D-rendered dice with visible cube faces, drilled pips, and shadows.
class DiceComponent extends PositionComponent with TapCallbacks {
  final int die1;
  final int die2;
  final List<int> remaining;
  final BoardLayout boardLayout;
  final void Function()? onTap;
  final int diceSet;

  /// Sprite-based rendering (null = use procedural fallback).
  DiceSprites? _sprites;

  /// Set sprite assets for this dice component.
  set sprites(DiceSprites? value) => _sprites = value;

  static const double _dieSize = 38;
  static const double _gap = 14;
  static const double _depth = 8; // visible 3D depth
  static const double _pipRadius = 3.2;
  static const double _cornerRadius = 5;

  /// Per-set color palettes: (topFace, topFaceUsed, rightFace, rightFaceUsed, pipActive, pipUsed).
  static const _palettes = <int, _DicePalette>{
    1: _DicePalette(
      topActive: Color(0xFFFAF6EE),
      topUsed: Color(0xFFD4CDB8),
      sideActive: Color(0xFFD8D0C0),
      sideUsed: Color(0xFFB0A890),
      pipActive: Color(0xFF2C1810),
      pipUsed: Color(0xFF8C7C60),
    ),
    2: _DicePalette(
      topActive: Color(0xFFFAF8F0),
      topUsed: Color(0xFFD4CDB8),
      sideActive: Color(0xFFD8D0C0),
      sideUsed: Color(0xFFB0A890),
      pipActive: Color(0xFF8B1A1A),
      pipUsed: Color(0xFF8C6060),
    ),
    3: _DicePalette(
      topActive: Color(0xFFF0EDE0),
      topUsed: Color(0xFFD0CCBC),
      sideActive: Color(0xFFCCC8B8),
      sideUsed: Color(0xFFACA890),
      pipActive: Color(0xFF4A4A4A),
      pipUsed: Color(0xFF8A8A7A),
    ),
  };

  _DicePalette get _palette => _palettes[diceSet] ?? _palettes[1]!;

  DiceComponent({
    required this.die1,
    required this.die2,
    required this.remaining,
    required this.boardLayout,
    this.onTap,
    this.diceSet = 1,
  }) : super(
          position: boardLayout.diceAreaCenter - Vector2(_dieSize + _gap / 2, _dieSize / 2),
          size: Vector2(_dieSize * 2 + _gap + _depth, _dieSize + _depth),
          anchor: Anchor.topLeft,
        );

  bool get _isPrompt => die1 == 0 && die2 == 0;

  @override
  void render(Canvas canvas) {
    if (_isPrompt) {
      _drawRollPrompt(canvas);
      return;
    }

    final die1Available = remaining.contains(die1);
    // For die2: count how many of die2's value remain. If doubles, die1
    // already claims one, so die2 needs at least 2 remaining.
    final die2Count = remaining.where((d) => d == die2).length;
    final die2Available = die1 == die2 ? die2Count >= 2 : die2Count >= 1;

    if (_sprites != null) {
      _drawSpriteDie(canvas, const Offset(0, 0), die1, die1Available);
      _drawSpriteDie(canvas, const Offset(_dieSize + _gap, 0), die2, die2Available);
      return;
    }

    _draw3DDie(canvas, const Offset(0, 0), die1, die1Available);
    _draw3DDie(canvas, const Offset(_dieSize + _gap, 0), die2, die2Available);
  }

  void _drawSpriteDie(Canvas canvas, Offset offset, int value, bool isAvailable) {
    final sprite = _sprites!.getFace(value);
    if (sprite == null) {
      _draw3DDie(canvas, offset, value, isAvailable);
      return;
    }

    final paint = Paint();
    if (!isAvailable) {
      paint.colorFilter = const ColorFilter.matrix(<double>[
        0.299, 0.587, 0.114, 0, 0,
        0.299, 0.587, 0.114, 0, 0,
        0.299, 0.587, 0.114, 0, 0,
        0, 0, 0, 0.55, 0,
      ]);
    }

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    sprite.render(
      canvas,
      position: Vector2.zero(),
      size: Vector2.all(_dieSize),
      overridePaint: paint,
    );
    canvas.restore();
  }

  void _draw3DDie(Canvas canvas, Offset offset, int value, bool isAvailable) {
    final x = offset.dx;
    final y = offset.dy;

    final opacity = isAvailable ? 1.0 : 0.55;

    // ── Drop shadow ────────────────────────────────────────
    final shadowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x + 3, y + 4, _dieSize, _dieSize),
      const Radius.circular(_cornerRadius),
    );
    canvas.drawRRect(shadowRect, LightingSystem.dropShadowPaint(opacity: 0.4, blur: 6));

    // ── Right face (3D depth) ──────────────────────────────
    final pal = _palette;
    final rightFacePath = Path()
      ..moveTo(x + _dieSize, y + _cornerRadius)
      ..lineTo(x + _dieSize + _depth * 0.7, y + _cornerRadius - _depth * 0.3)
      ..lineTo(x + _dieSize + _depth * 0.7, y + _dieSize - _cornerRadius - _depth * 0.3)
      ..lineTo(x + _dieSize, y + _dieSize - _cornerRadius)
      ..close();
    final rightColor = isAvailable ? pal.sideActive : pal.sideUsed;
    canvas.drawPath(rightFacePath, Paint()..color = LightingSystem.applyShadow(rightColor, 0.2));

    // ── Bottom face (3D depth) ─────────────────────────────
    final bottomFacePath = Path()
      ..moveTo(x + _cornerRadius, y + _dieSize)
      ..lineTo(x + _dieSize - _cornerRadius, y + _dieSize)
      ..lineTo(x + _dieSize - _cornerRadius + _depth * 0.7, y + _dieSize + _depth * 0.5)
      ..lineTo(x + _cornerRadius + _depth * 0.7, y + _dieSize + _depth * 0.5)
      ..close();
    canvas.drawPath(bottomFacePath, Paint()
      ..color = LightingSystem.applyShadow(rightColor, 0.35));

    // ── Top face (main visible face) ───────────────────────
    final topRect = Rect.fromLTWH(x, y, _dieSize, _dieSize);
    final topRRect = RRect.fromRectAndRadius(topRect, const Radius.circular(_cornerRadius));

    // Gradient: lighter top-left (toward light), darker bottom-right.
    final topColor = isAvailable ? pal.topActive : pal.topUsed;
    final topGradient = Paint()
      ..shader = Gradient.linear(
        Offset(x, y),
        Offset(x + _dieSize, y + _dieSize),
        [
          LightingSystem.applyLight(topColor, 1.05),
          topColor,
          LightingSystem.applyShadow(topColor, 0.1),
        ],
        [0.0, 0.4, 1.0],
      );
    canvas.drawRRect(topRRect, topGradient);

    // Subtle border.
    canvas.drawRRect(topRRect, Paint()
      ..color = Colors.black.withValues(alpha: isAvailable ? 0.12 : 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);

    // Top edge highlight.
    canvas.drawLine(
      Offset(x + _cornerRadius, y + 0.5),
      Offset(x + _dieSize - _cornerRadius, y + 0.5),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..strokeWidth = 0.8,
    );

    // ── Pips (drilled into surface) ────────────────────────
    final pipColor = isAvailable ? pal.pipActive : pal.pipUsed;
    _drawPips(canvas, x, y, value, pipColor, opacity);
  }

  void _drawPips(Canvas canvas, double x, double y, int value, Color pipColor, double opacity) {
    final cx = x + _dieSize / 2;
    final cy = y + _dieSize / 2;
    const d = _dieSize * 0.24;

    final positions = _pipPositions(value, cx, cy, d);

    for (final p in positions) {
      // Pip shadow (drilled indent).
      canvas.drawCircle(
        Offset(p.dx + 0.5, p.dy + 0.5),
        _pipRadius + 0.5,
        Paint()..color = Colors.black.withValues(alpha: 0.15 * opacity),
      );

      // Pip fill.
      canvas.drawCircle(
        p,
        _pipRadius,
        Paint()..color = pipColor.withValues(alpha: opacity),
      );

      // Pip inner highlight (concave).
      canvas.drawCircle(
        Offset(p.dx - 0.5, p.dy - 0.5),
        _pipRadius * 0.4,
        Paint()..color = Colors.white.withValues(alpha: 0.08 * opacity),
      );
    }
  }

  List<Offset> _pipPositions(int value, double cx, double cy, double d) {
    return switch (value) {
      1 => [Offset(cx, cy)],
      2 => [Offset(cx - d, cy - d), Offset(cx + d, cy + d)],
      3 => [Offset(cx - d, cy - d), Offset(cx, cy), Offset(cx + d, cy + d)],
      4 => [
          Offset(cx - d, cy - d), Offset(cx + d, cy - d),
          Offset(cx - d, cy + d), Offset(cx + d, cy + d),
        ],
      5 => [
          Offset(cx - d, cy - d), Offset(cx + d, cy - d),
          Offset(cx, cy),
          Offset(cx - d, cy + d), Offset(cx + d, cy + d),
        ],
      6 => [
          Offset(cx - d, cy - d), Offset(cx + d, cy - d),
          Offset(cx - d, cy), Offset(cx + d, cy),
          Offset(cx - d, cy + d), Offset(cx + d, cy + d),
        ],
      _ => [],
    };
  }

  void _drawRollPrompt(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x - _depth, size.y - _depth);

    // Background with warm glow.
    final bgPaint = Paint()
      ..shader = Gradient.radial(
        rect.center,
        rect.width / 2,
        [
          TavliColors.surface.withValues(alpha: 0.35),
          TavliColors.surface.withValues(alpha: 0.15),
        ],
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      bgPaint,
    );

    // Border.
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..color = TavliColors.surface
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'TAP TO ROLL',
        style: TextStyle(
          color: TavliColors.light,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        (rect.width - textPainter.width) / 2,
        (rect.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    onTap?.call();
  }
}

class _DicePalette {
  final Color topActive;
  final Color topUsed;
  final Color sideActive;
  final Color sideUsed;
  final Color pipActive;
  final Color pipUsed;

  const _DicePalette({
    required this.topActive,
    required this.topUsed,
    required this.sideActive,
    required this.sideUsed,
    required this.pipActive,
    required this.pipUsed,
  });
}
