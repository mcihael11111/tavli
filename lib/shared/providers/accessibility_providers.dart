import 'package:flutter/material.dart';

/// Check if reduced motion is enabled.
///
/// Usage: `final reduce = ReducedMotion.of(context);`
/// Then: `duration: reduce ? Duration.zero : Duration(milliseconds: 350)`
class ReducedMotion {
  const ReducedMotion._();

  /// Whether the system requests reduced motion.
  static bool of(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Get a duration that respects reduced motion preference.
  static Duration duration(BuildContext context, Duration normal) {
    return of(context) ? Duration.zero : normal;
  }
}
