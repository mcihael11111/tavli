import 'dart:ui';

/// Simulated directional light for 3D board rendering.
///
/// Models a warm overhead light slightly offset to the upper-left,
/// like a kafeneio lamp hanging above the table.
class LightingSystem {
  /// Light direction (normalized). Upper-left, slightly forward.
  static const double lightDirX = -0.35;
  static const double lightDirY = -0.55;
  static const double lightDirZ = 0.75;

  /// Ambient light intensity (base illumination even in shadow).
  static const double ambientIntensity = 0.35;

  /// Warm light color temperature.
  static const Color lightColor = Color(0xFFFFF5E0);
  static const Color shadowColor = Color(0xFF1A0E05);

  /// Calculate diffuse lighting for a surface with given normal.
  /// Returns 0.0 (full shadow) to 1.0 (full light).
  static double diffuse(double nx, double ny, double nz) {
    final dot = nx * lightDirX + ny * lightDirY + nz * lightDirZ;
    return (ambientIntensity + (1 - ambientIntensity) * dot.clamp(0, 1));
  }

  /// Top-facing surface (board, top of checker).
  static double get topFaceLighting => diffuse(0, 0, 1);

  /// Left-facing edge.
  static double get leftEdgeLighting => diffuse(-1, 0, 0);

  /// Right-facing edge.
  static double get rightEdgeLighting => diffuse(1, 0, 0);

  /// Front-facing edge (toward viewer).
  static double get frontEdgeLighting => diffuse(0, 1, 0);

  /// Bottom-facing edge (away from viewer / underside).
  static double get bottomEdgeLighting => diffuse(0, -1, 0);

  /// Apply lighting to a base color.
  static Color applyLight(Color base, double intensity) {
    final r = (base.r * intensity + lightColor.r * intensity * 0.1).round().clamp(0, 255);
    final g = (base.g * intensity + lightColor.g * intensity * 0.08).round().clamp(0, 255);
    final b = (base.b * intensity + lightColor.b * intensity * 0.05).round().clamp(0, 255);
    return Color.fromARGB(base.a.toInt(), r, g, b);
  }

  /// Darken a color for shadow areas.
  static Color applyShadow(Color base, double shadowAmount) {
    final factor = 1.0 - shadowAmount * 0.6;
    return Color.fromARGB(
      base.a.toInt(),
      (base.r * factor).round().clamp(0, 255),
      (base.g * factor).round().clamp(0, 255),
      (base.b * factor).round().clamp(0, 255),
    );
  }

  /// Create a drop shadow paint.
  static Paint dropShadowPaint({
    double opacity = 0.35,
    double blur = 6,
  }) {
    return Paint()
      ..color = shadowColor.withValues(alpha: opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
  }
}
