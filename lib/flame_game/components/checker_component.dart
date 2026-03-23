import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/material.dart' show Colors;
import '../../core/constants/colors.dart';
import '../rendering/lighting.dart';
import 'board_layout.dart';

/// 3D-rendered checker piece — cylindrical with visible thickness,
/// rim lighting, concentric rings, and stacking shadows.
///
/// Renders as an oblique-view cylinder: elliptical top face + side band + shadow.
class CheckerComponent extends CircleComponent with TapCallbacks {
  final int pointIndex;
  final int stackPosition;
  final int player;
  final BoardLayout boardLayout;
  final void Function()? onTap;
  final int checkerSet;

  bool _isSelected = false;

  /// Cylinder thickness as fraction of radius.
  static const double _thicknessRatio = 0.32;

  /// Ellipse squash for top face (oblique top-down perspective ~75 degrees).
  /// Higher value = rounder looking. 0.55 gives a nice "thick coin" look.
  static const double _perspectiveSquash = 0.55;

  CheckerComponent({
    required this.pointIndex,
    required this.stackPosition,
    required this.player,
    required this.boardLayout,
    this.onTap,
    this.checkerSet = 1,
  }) : super(
          radius: boardLayout.checkerRadius,
          anchor: Anchor.center,
          position: boardLayout.checkerPosition(pointIndex, stackPosition, player),
        );

  // ── Material colors ────────────────────────────────────────
  // Checker set color palettes.
  static const _palettes = {
    // Set 1: Classic (cream/walnut)
    1: {
      'light': (Color(0xFFF5EBD0), Color(0xFFFFFCF0), Color(0xFFDDCEA8), Color(0xFFCBB888)),
      'dark': (Color(0xFF3A2015), Color(0xFF5C3D2A), Color(0xFF241008), Color(0xFF4A2E1C)),
    },
    // Set 2: Ruby (ivory/deep red)
    2: {
      'light': (Color(0xFFF0E8DC), Color(0xFFFFF8F0), Color(0xFFD8CCBA), Color(0xFFC8B89A)),
      'dark': (Color(0xFF6B1A1A), Color(0xFF8C2E2E), Color(0xFF4A0E0E), Color(0xFF7A2222)),
    },
    // Set 3: Olive (warm gray/olive green)
    3: {
      'light': (Color(0xFFE8E0D0), Color(0xFFF5F0E8), Color(0xFFCCC4B0), Color(0xFFB8AE98)),
      'dark': (Color(0xFF3A4A2A), Color(0xFF506038), Color(0xFF243018), Color(0xFF445530)),
    },
  };

  Color get _baseColor {
    final p = _palettes[checkerSet] ?? _palettes[1]!;
    final colors = player == 1 ? p['light']! : p['dark']!;
    return colors.$1;
  }

  Color get _highlightColor {
    final p = _palettes[checkerSet] ?? _palettes[1]!;
    final colors = player == 1 ? p['light']! : p['dark']!;
    return colors.$2;
  }

  Color get _sideColor {
    final p = _palettes[checkerSet] ?? _palettes[1]!;
    final colors = player == 1 ? p['light']! : p['dark']!;
    return colors.$3;
  }

  Color get _ringColor {
    final p = _palettes[checkerSet] ?? _palettes[1]!;
    final colors = player == 1 ? p['light']! : p['dark']!;
    return colors.$4;
  }

  double get _thickness => radius * _thicknessRatio;
  double get _ellipseH => radius * _perspectiveSquash;

  bool get isSelected => _isSelected;

  set isSelected(bool value) {
    _isSelected = value;
    if (value) {
      add(ScaleEffect.to(
        Vector2.all(1.1),
        EffectController(duration: 0.15),
      ));
    } else {
      add(ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(duration: 0.15),
      ));
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = radius;
    final cy = radius;

    // ── Drop shadow on board surface ─────────────────────────
    final shadowOffsetY = 4.0 + stackPosition * 0.5;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + 3, cy + shadowOffsetY + _thickness),
        width: radius * 2.15,
        height: _ellipseH * 2.15,
      ),
      LightingSystem.dropShadowPaint(opacity: 0.45, blur: 6),
    );

    // ── Side band (cylinder body) ────────────────────────────
    _drawCylinderSide(canvas, cx, cy);

    // ── Bottom edge of top face (thin dark line) ─────────────
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: radius * 2,
        height: _ellipseH * 2,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // ── Top face ─────────────────────────────────────────────
    _drawTopFace(canvas, cx, cy);

    // ── Concentric rings (carved groove detail) ──────────────
    _drawRings(canvas, cx, cy);

    // ── Rim lighting (specular highlight) ────────────────────
    _drawRimLight(canvas, cx, cy);

    // ── Selection glow ───────────────────────────────────────
    if (_isSelected) {
      _drawSelectionGlow(canvas, cx, cy);
    }
  }

  void _drawCylinderSide(Canvas canvas, double cx, double cy) {
    // Side band: area between bottom ellipse and top ellipse.
    final topEllipseY = cy;
    final bottomEllipseY = cy + _thickness;

    // Gradient from left (shadow) to right (light) for cylinder curvature.
    final sidePath = Path();

    // Bottom half of the bottom ellipse.
    sidePath.addArc(
      Rect.fromCenter(
        center: Offset(cx, bottomEllipseY),
        width: radius * 2,
        height: _ellipseH * 2,
      ),
      0, math.pi,
    );
    // Top half of the top ellipse (reversed).
    sidePath.addArc(
      Rect.fromCenter(
        center: Offset(cx, topEllipseY),
        width: radius * 2,
        height: _ellipseH * 2,
      ),
      math.pi, -math.pi,
    );
    sidePath.close();

    // Side gradient (3D cylinder shading).
    final sideGradient = Paint()
      ..shader = Gradient.linear(
        Offset(cx - radius, cy),
        Offset(cx + radius, cy),
        [
          LightingSystem.applyShadow(_sideColor, 0.3),
          LightingSystem.applyLight(_sideColor, LightingSystem.topFaceLighting),
          LightingSystem.applyShadow(_sideColor, 0.15),
        ],
        [0.0, 0.45, 1.0],
      );
    canvas.drawPath(sidePath, sideGradient);

    // Bottom rim (thin highlight line).
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, bottomEllipseY),
        width: radius * 2,
        height: _ellipseH * 2,
      ),
      0.2, math.pi - 0.4,
      false,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  void _drawTopFace(Canvas canvas, double cx, double cy) {
    final topRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: radius * 2,
      height: _ellipseH * 2,
    );

    // Radial gradient for top face (center lighter, edge darker).
    final topGradient = Paint()
      ..shader = Gradient.radial(
        Offset(cx - radius * 0.2, cy - _ellipseH * 0.3), // offset toward light
        radius,
        [
          _highlightColor,
          LightingSystem.applyLight(_baseColor, LightingSystem.topFaceLighting),
          LightingSystem.applyShadow(_baseColor, 0.15),
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawOval(topRect, topGradient);
  }

  void _drawRings(Canvas canvas, double cx, double cy) {
    // Outer ring groove.
    final ringPaint = Paint()
      ..color = _ringColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.08;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: radius * 1.4,
        height: _ellipseH * 1.4,
      ),
      ringPaint,
    );

    // Inner ring.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: radius * 0.8,
        height: _ellipseH * 0.8,
      ),
      Paint()
        ..color = _ringColor.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.05,
    );
  }

  void _drawRimLight(Canvas canvas, double cx, double cy) {
    // Specular highlight arc on upper-left rim.
    final rimPaint = Paint()
      ..color = _highlightColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.1
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: radius * 1.8,
        height: _ellipseH * 1.8,
      ),
      -2.8, // upper-left
      1.0,
      false,
      rimPaint,
    );

    // Subtle secondary highlight on side.
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, cy + _thickness * 0.5),
        width: radius * 1.9,
        height: _ellipseH * 1.2,
      ),
      -2.5,
      0.6,
      false,
      Paint()
        ..color = _highlightColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.06
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawSelectionGlow(Canvas canvas, double cx, double cy) {
    // Green glow around the checker (matching reference app).
    final glowPaint = Paint()
      ..color = TavliColors.selectionGreen.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: radius * 2.3,
        height: _ellipseH * 2.3 + _thickness,
      ),
      glowPaint,
    );

    // Bright green ring.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: radius * 2.15,
        height: _ellipseH * 2.15,
      ),
      Paint()
        ..color = TavliColors.selectionGreen.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    onTap?.call();
  }

  void animateMoveTo(Vector2 target, {double duration = 0.35}) {
    add(MoveEffect.to(
      target,
      EffectController(duration: duration, curve: Curves.easeInOutCubic),
    ));
  }
}
