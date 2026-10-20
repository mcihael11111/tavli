/// The gameplay view of the persisted settings (design §3 autoplay, §5).
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tavli/shared/services/settings_service.dart';

/// Checker animation speed; [durationFactor] scales every tween.
enum AnimSpeed {
  slow(1.5),
  normal(1.0),
  fast(0.6);

  final double durationFactor;
  const AnimSpeed(this.durationFactor);

  /// The stored [name], or [normal] for a missing or unknown value.
  static AnimSpeed fromStorage(String? name) =>
      values.where((v) => v.name == name).firstOrNull ?? normal;
}

/// Reads and writes the gameplay settings through [SettingsService], so
/// they persist with every other setting. Values are read live, so a change
/// in the settings screen applies to the next decision.
class GameplaySettings {
  final SettingsService _s;

  GameplaySettings(this._s);

  AnimSpeed get animSpeed => AnimSpeed.fromStorage(_s.animSpeed);
  set animSpeed(AnimSpeed v) => _s.animSpeed = v.name;

  bool get haptics => _s.haptics;
  set haptics(bool v) => _s.haptics = v;

  /// Play a forced move's single play automatically.
  bool get autoplayForced => _s.autoplayForced;
  set autoplayForced(bool v) => _s.autoplayForced = v;

  /// Move on from a passed turn without input.
  bool get autoPass => _s.autoPass;
  set autoPass(bool v) => _s.autoPass = v;

  /// Roll at turn start when no cube decision is possible (default off).
  bool get autoRoll => _s.autoRoll;
  set autoRoll(bool v) => _s.autoRoll = v;

  /// The existing move-confirmation setting: when on, a complete play waits
  /// for Confirm instead of committing.
  bool get moveConfirmation => _s.moveConfirmation;

  /// Commit a complete play without a Confirm button.
  bool get autoCommit => !moveConfirmation;

  bool get showPipCount => _s.showPipCount;

  /// SFX volume, 0..1.
  double get sfxVolume => _s.sfxVolume;

  /// Whether the platform asks for reduced motion.
  static bool reducedMotion(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// The factor for animation durations: 0 (instant) under reduced motion,
  /// else the [animSpeed] factor.
  double durationFactor(BuildContext context) =>
      reducedMotion(context) ? 0 : animSpeed.durationFactor;
}

final gameplaySettingsProvider = Provider<GameplaySettings>(
  (ref) => GameplaySettings(ref.watch(settingsServiceProvider)),
);
