import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart' show Curve, Curves;
import 'package:flutter/material.dart' show Colors;
import '../../core/constants/colors.dart';
import '../rendering/lighting.dart';
import '../sprite_manager.dart';
import 'board_layout.dart';

/// 3D-rendered checker piece — cylindrical with visible thickness,
/// rim lighting, concentric rings, and stacking shadows.
///
/// Renders as an oblique-view cylinder: elliptical top face + side band + shadow.
class CheckerComponent extends CircleComponent with TapCallbacks {
  int pointIndex;
  int stackPosition;
  int player;
  final BoardLayout boardLayout;
  void Function()? onTap;
  final int checkerSet;

  /// Unique ID for tracking this checker through board state diffs.
  final int checkerId;

  /// Sprite-based rendering (null = use procedural fallback).
  CheckerSprites? _sprites;
  CheckerShadowSprites? _shadowSprites;
  CheckerVerticalSprites? _verticalSprites;

  bool _isSelected = false;

  // ── Selection tween (Spec §6.1) ──────────────────────────
  // Drives the 80ms scale + ring-opacity animation kicked off in onTapUp.
  // Uses an update()-driven tween (not a Flame Effect) so the first frame of
  // feedback can land synchronously with the tap, and so cancellation when
  // the player rapid-taps a different checker is just a state reset.
  double _ringOpacity = 0.0;
  double _selectionScale = 1.0;
  static const double _selectionTweenDuration = 0.080;
  double _selectionTweenT = 0;
  double _selectionStartScale = 1.0;
  double _selectionTargetScale = 1.0;
  double _selectionStartOpacity = 0.0;
  double _selectionTargetOpacity = 0.0;
  bool _selectionTweenActive = false;

  /// Cylinder thickness as fraction of radius.
  static const double _thicknessRatio = 0.32;

  /// Ellipse squash for top face (oblique top-down perspective ~75 degrees).
  /// Higher value = rounder looking. 0.55 gives a nice "thick coin" look.
  static const double _perspectiveSquash = 0.55;

  /// Counter for generating unique checker IDs.
  static int _nextId = 0;

  CheckerComponent({
    required this.pointIndex,
    required this.stackPosition,
    required this.player,
    required this.boardLayout,
    this.onTap,
    this.checkerSet = 1,
  })  : checkerId = _nextId++,
        super(
          radius: boardLayout.checkerRadius,
          anchor: Anchor.center,
          position: boardLayout.checkerPosition(pointIndex, stackPosition, player),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Tap target: at least 44pt diameter (Material a11y floor) regardless of
    // how cramped the board gets on small phones.
    final hitR = radius < BoardLayout.minTapRadius ? BoardLayout.minTapRadius : radius;
    add(CircleHitbox(
      radius: hitR,
      position: Vector2(radius - hitR, radius - hitR),
      anchor: Anchor.topLeft,
    ));
  }

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

  /// Set sprite assets for this checker. Pass null to use procedural rendering.
  set sprites(CheckerSprites? value) => _sprites = value;

  /// Set drop-shadow sprite. Rendered under the checker when sprite mode is on.
  set shadowSprites(CheckerShadowSprites? value) => _shadowSprites = value;

  /// Side-on sprite used when this checker is borne off (lives in the tray).
  set verticalSprites(CheckerVerticalSprites? value) => _verticalSprites = value;

  double get _thickness => radius * _thicknessRatio;
  double get _ellipseH => radius * _perspectiveSquash;

  bool get isSelected => _isSelected;

  /// Toggle the tap-selection visual (scale 1.00 → 1.06 + ring fade-in over
  /// 80ms ease-out). Idempotent on the same value. Called synchronously from
  /// onTapUp so the first frame of feedback lands in the same frame as the
  /// tap commit (Spec §6.1).
  void setSelected(bool value) {
    if (_isSelected == value) return;
    _isSelected = value;
    _selectionStartScale = _selectionScale;
    _selectionStartOpacity = _ringOpacity;
    _selectionTargetScale = value ? 1.06 : 1.0;
    _selectionTargetOpacity = value ? 0.85 : 0.0;
    _selectionTweenT = 0;
    _selectionTweenActive = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_selectionTweenActive) {
      _selectionTweenT += dt;
      final p = (_selectionTweenT / _selectionTweenDuration).clamp(0.0, 1.0);
      // Ease-out (quadratic): fast at start, settles smoothly.
      final eased = 1 - (1 - p) * (1 - p);
      _selectionScale = _selectionStartScale +
          (_selectionTargetScale - _selectionStartScale) * eased;
      _ringOpacity = _selectionStartOpacity +
          (_selectionTargetOpacity - _selectionStartOpacity) * eased;
      if (p >= 1.0) {
        _selectionTweenActive = false;
        _selectionScale = _selectionTargetScale;
        _ringOpacity = _selectionTargetOpacity;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Apply tap-selection scale around the checker center. The scale is
    // tweened (Spec §6.1, 80ms ease-out) so any non-1.0 value means we're
    // mid- or post- selection animation.
    final scaling = _selectionScale != 1.0;
    if (scaling) {
      canvas.save();
      canvas.translate(radius, radius);
      canvas.scale(_selectionScale);
      canvas.translate(-radius, -radius);
    }

    if (_sprites != null) {
      _renderWithSprite(canvas);
    } else {
      _renderProcedural(canvas);
    }

    if (scaling) {
      canvas.restore();
    }

    // Selection ring (Spec §6.1) — drawn in unscaled space so the 2px stroke
    // remains 2px regardless of the scale tween. Sits just outside the
    // checker disc.
    if (_ringOpacity > 0.001) {
      final ring = Paint()
        ..color = TavliColors.primary.withValues(alpha: _ringOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(
        Offset(radius, radius),
        radius + 3,
        ring,
      );
    }
  }

  /// Procedural (non-sprite) cylinder rendering.
  void _renderProcedural(Canvas canvas) {
    final cx = radius;
    final cy = radius;

    // ── Drop shadow on board surface ─────────────────────────
    // Fade shadow for stacked checkers to avoid dark accumulation.
    final shadowOpacity = stackPosition == 0 ? 0.45 : (0.15 / (stackPosition + 1));
    if (shadowOpacity > 0.02) {
      final shadowOffsetY = 4.0 + stackPosition * 0.5;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + 3, cy + shadowOffsetY + _thickness),
          width: radius * 2.15,
          height: _ellipseH * 2.15,
        ),
        LightingSystem.dropShadowPaint(opacity: shadowOpacity, blur: 6),
      );
    }

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
  }

  /// Render using designer-provided sprite assets.
  ///
  /// The sprite PNG has transparent padding around the visible disc (for the
  /// baked shadow). We scale the bbox up by 1/visibleRatio so the visible disc
  /// matches the logical [radius], then offset to keep the disc centered.
  void _renderWithSprite(Canvas canvas) {
    // Borne-off checkers render as on-edge slivers in the bear-off tray.
    if (pointIndex == -2 && _verticalSprites != null) {
      _renderVerticalSprite(canvas);
      return;
    }

    final visibleDiameter = radius * 2;
    final spriteSize = visibleDiameter / BoardLayout.checkerVisibleRatio;
    final spriteOrigin = radius - spriteSize / 2;

    // Stack-aware shadow opacity matches the procedural renderer so a tall
    // pile doesn't accumulate dark layers underneath each disc.
    final shadowOpacity = stackPosition == 0 ? 1.0 : (0.45 / (stackPosition + 1));
    if (_shadowSprites != null && shadowOpacity > 0.04) {
      final shadowPaint = Paint()
        ..colorFilter = ColorFilter.mode(
          Color.fromRGBO(0, 0, 0, shadowOpacity),
          BlendMode.modulate,
        );
      _shadowSprites!.forPlayer(player).render(
            canvas,
            position: Vector2(spriteOrigin, spriteOrigin),
            size: Vector2(spriteSize, spriteSize),
            overridePaint: shadowPaint,
          );
    }

    final sprite = _sprites!.getSprite(player, _isSelected);
    sprite.render(
      canvas,
      position: Vector2(spriteOrigin, spriteOrigin),
      size: Vector2(spriteSize, spriteSize),
    );
  }

  /// Render a borne-off checker as an on-edge sliver inside the bear-off tray.
  /// The sprite PNG aspect is 77 × 202 ≈ 0.381. We size the sliver to match
  /// the tray's inner height and use the natural aspect for width.
  void _renderVerticalSprite(Canvas canvas) {
    const aspect = 77.0 / 202.0;
    final h = boardLayout.trayInnerHeight * 0.92; // small breathing room
    final w = h * aspect;
    final origin = Vector2(radius - w / 2, radius - h / 2);
    _verticalSprites!.forPlayer(player).render(
          canvas,
          position: origin,
          size: Vector2(w, h),
        );
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

  @override
  void onTapUp(TapUpEvent event) {
    onTap?.call();
  }

  /// Active move effect — tracked so we can cancel if a new move starts.
  MoveEffect? _activeMoveEffect;

  /// Animate this checker to [target] position.
  /// Returns a Future that completes when the animation finishes.
  /// Cancels any in-progress animation first.
  Future<void> animateMoveTo(Vector2 target, {
    double duration = 0.13,
    Curve curve = Curves.easeOutCubic,
  }) {
    // Cancel any existing animation. Snap the position to the previous target
    // before removing the old effect so the next animation interpolates from
    // a stable point — without this, mid-flight cancellation in 4-move doubles
    // turns produced visible jank as the new effect started from wherever the
    // checker happened to be that frame (QA H4).
    if (_activeMoveEffect != null) {
      position = _pendingTarget ?? position;
      _activeMoveEffect!.removeFromParent();
      _activeMoveEffect = null;
    }
    _pendingTarget = target;

    final completer = Completer<void>();
    final effect = MoveEffect.to(
      target,
      EffectController(duration: duration, curve: curve),
      onComplete: () {
        _activeMoveEffect = null;
        _pendingTarget = null;
        if (!completer.isCompleted) completer.complete();
      },
    );
    _activeMoveEffect = effect;
    add(effect);
    return completer.future;
  }

  /// Where the active move effect is heading. Used so a cancellation snaps to
  /// the in-flight target before the next effect kicks in.
  Vector2? _pendingTarget;

  /// Update this checker's logical position without changing its visual position.
  /// Used by the differ to update identity before animating.
  void updateLogicalPosition({
    required int newPointIndex,
    required int newStackPosition,
    required int newPlayer,
  }) {
    pointIndex = newPointIndex;
    stackPosition = newStackPosition;
    player = newPlayer;
  }
}
