import 'dart:ui';

import 'lighting.dart';

/// Utilities for rendering consistent shadows across 3D components.
class ShadowRenderer {
  const ShadowRenderer._();

  /// Draw a contact shadow beneath a checker stack.
  /// [stackHeight] increases shadow offset for taller stacks.
  static void drawCheckerShadow(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double ellipseHeight,
    int stackHeight = 0,
  }) {
    final offsetY = 2.0 + stackHeight * 0.8;
    const offsetX = 1.5;
    final spread = 1.0 + stackHeight * 0.15;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + offsetX, center.dy + offsetY),
        width: radius * 2 * spread,
        height: ellipseHeight * 2 * spread,
      ),
      LightingSystem.dropShadowPaint(
        opacity: 0.3 - stackHeight * 0.02,
        blur: 4 + stackHeight * 0.5,
      ),
    );
  }

  /// Draw an ambient occlusion shadow where board meets frame.
  static void drawRecessShadow(Canvas canvas, Rect recessRect) {
    // Top edge (shadow from frame above).
    final topGradient = Paint()
      ..shader = Gradient.linear(
        Offset(recessRect.left, recessRect.top),
        Offset(recessRect.left, recessRect.top + 6),
        [
          const Color(0x40000000),
          const Color(0x00000000),
        ],
      );
    canvas.drawRect(
      Rect.fromLTWH(recessRect.left, recessRect.top, recessRect.width, 6),
      topGradient,
    );

    // Left edge.
    final leftGradient = Paint()
      ..shader = Gradient.linear(
        Offset(recessRect.left, recessRect.top),
        Offset(recessRect.left + 4, recessRect.top),
        [
          const Color(0x30000000),
          const Color(0x00000000),
        ],
      );
    canvas.drawRect(
      Rect.fromLTWH(recessRect.left, recessRect.top, 4, recessRect.height),
      leftGradient,
    );
  }
}
