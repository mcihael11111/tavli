import 'dart:math' as math;
import 'dart:ui';

import 'lighting.dart';

/// Procedural wood grain texture generator.
///
/// Creates realistic wood grain patterns for mahogany, olive wood,
/// walnut, etc. by layering noise-based grain lines with color variation.
class WoodTextureRenderer {
  /// Paint a wood-textured rectangle onto the canvas.
  static void paintWoodRect(
    Canvas canvas,
    Rect rect, {
    required Color baseColor,
    required Color grainColor,
    double grainDensity = 12,
    double grainAngle = 0.05, // slight angle for realism
    double lightIntensity = 1.0,
    bool isVertical = false,
  }) {
    // Base fill with lighting.
    final litBase = LightingSystem.applyLight(baseColor, lightIntensity);
    canvas.drawRect(rect, Paint()..color = litBase);

    // Grain lines.
    final grainPaint = Paint()
      ..color = grainColor.withValues(alpha: 0.2)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final rng = math.Random(baseColor.toARGB32());
    final step = rect.height / grainDensity;

    if (isVertical) {
      for (double x = rect.left; x < rect.right; x += step) {
        final wobble = rng.nextDouble() * 3 - 1.5;
        final path = Path();
        path.moveTo(x + wobble, rect.top);

        for (double y = rect.top; y < rect.bottom; y += 8) {
          final dx = (rng.nextDouble() - 0.5) * 2.5;
          path.lineTo(x + wobble + dx, y);
        }
        canvas.drawPath(path, grainPaint);
      }
    } else {
      for (double y = rect.top; y < rect.bottom; y += step) {
        final wobble = rng.nextDouble() * 3 - 1.5;
        final path = Path();
        path.moveTo(rect.left, y + wobble);

        for (double x = rect.left; x < rect.right; x += 8) {
          final dy = (rng.nextDouble() - 0.5) * 2.5 + grainAngle * (x - rect.left);
          path.lineTo(x, y + wobble + dy);
        }
        canvas.drawPath(path, grainPaint);
      }
    }

    // Subtle knots (occasional).
    if (rng.nextDouble() > 0.5) {
      final knotX = rect.left + rng.nextDouble() * rect.width;
      final knotY = rect.top + rng.nextDouble() * rect.height;
      final knotR = 3 + rng.nextDouble() * 5;
      final knotPaint = Paint()
        ..color = grainColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6;
      for (int i = 0; i < 3; i++) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(knotX, knotY),
            width: knotR * (1 + i * 0.6),
            height: knotR * (0.6 + i * 0.3),
          ),
          knotPaint,
        );
      }
    }
  }

  /// Paint a felt/leather surface (for the playing area).
  static void paintFeltRect(
    Canvas canvas,
    Rect rect, {
    required Color baseColor,
    double lightIntensity = 1.0,
  }) {
    final litBase = LightingSystem.applyLight(baseColor, lightIntensity);
    canvas.drawRect(rect, Paint()..color = litBase);

    // Subtle texture noise.
    final noisePaint = Paint()
      ..color = baseColor.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;

    final rng = math.Random(baseColor.toARGB32() + 99);
    for (int i = 0; i < 200; i++) {
      final x = rect.left + rng.nextDouble() * rect.width;
      final y = rect.top + rng.nextDouble() * rect.height;
      canvas.drawCircle(Offset(x, y), 0.5 + rng.nextDouble(), noisePaint);
    }
  }

  /// Draw a 3D beveled edge (frame thickness visible from perspective).
  static void paintBeveledEdge(
    Canvas canvas, {
    required Rect outerRect,
    required double thickness,
    required Color color,
    required double depth,
  }) {
    // Front edge (bottom of frame — closest to viewer).
    final frontColor = LightingSystem.applyLight(color, LightingSystem.frontEdgeLighting);
    final frontPath = Path()
      ..moveTo(outerRect.left, outerRect.bottom)
      ..lineTo(outerRect.right, outerRect.bottom)
      ..lineTo(outerRect.right - depth * 0.3, outerRect.bottom + depth)
      ..lineTo(outerRect.left + depth * 0.3, outerRect.bottom + depth)
      ..close();
    canvas.drawPath(frontPath, Paint()..color = frontColor);

    // Right edge.
    final rightColor = LightingSystem.applyLight(color, LightingSystem.rightEdgeLighting);
    final rightPath = Path()
      ..moveTo(outerRect.right, outerRect.top)
      ..lineTo(outerRect.right, outerRect.bottom)
      ..lineTo(outerRect.right + depth * 0.5, outerRect.bottom - depth * 0.3)
      ..lineTo(outerRect.right + depth * 0.5, outerRect.top + depth * 0.3)
      ..close();
    canvas.drawPath(rightPath, Paint()..color = rightColor);

    // Left edge (in shadow).
    final leftColor = LightingSystem.applyShadow(color, 0.3);
    final leftPath = Path()
      ..moveTo(outerRect.left, outerRect.top)
      ..lineTo(outerRect.left, outerRect.bottom)
      ..lineTo(outerRect.left - depth * 0.5, outerRect.bottom - depth * 0.3)
      ..lineTo(outerRect.left - depth * 0.5, outerRect.top + depth * 0.3)
      ..close();
    canvas.drawPath(leftPath, Paint()..color = leftColor);
  }
}
