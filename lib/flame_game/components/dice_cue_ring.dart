import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';

/// Pulsing ring drawn around the dice cup region while the player is the
/// active roller and no roll has happened yet. Acts as a visual cue that the
/// dice are tappable. Disappears the moment the rattle starts.
class DiceCueRing extends PositionComponent {
  double _t = 0;
  bool visible = false;

  DiceCueRing({required Vector2 position, required double radius})
      : super(position: position, size: Vector2.all(radius * 2));

  static const double _periodSeconds = 1.4;

  double get _opacity {
    final phase = (_t / _periodSeconds) * 2 * math.pi;
    final sinNorm = (math.sin(phase) + 1) / 2; // 0..1
    return 0.35 + 0.30 * sinNorm; // 0.35..0.65
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (visible) {
      _t = (_t + dt) % _periodSeconds;
    }
  }

  @override
  void render(Canvas canvas) {
    if (!visible) return;
    final paint = Paint()
      ..color = TavliColors.primary.withValues(alpha: _opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2 - 1,
      paint,
    );
  }
}
