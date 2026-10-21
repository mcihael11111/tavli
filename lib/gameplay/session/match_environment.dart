/// The controller's injectable environment: pacing waits, the recorder
/// and the dice source.
library;

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game_recorder.dart';

/// What a controller needs besides the bot and the settings; tests
/// override [matchEnvironmentProvider] for instant pacing and a fake
/// recorder.
class MatchEnvironment {
  const MatchEnvironment({
    this.delay = _realDelay,
    this.recorder = const ServiceGameRecorder(),
    this.random = _defaultRandom,
  });

  /// Waits a pacing beat.
  final Future<void> Function(Duration) delay;
  final GameRecorder recorder;

  /// The dice source for a setup seed: `Random(seed)`, else
  /// `Random.secure()`.
  final Random Function(int? seed) random;

  static Future<void> _realDelay(Duration d) => Future.delayed(d);
  static Random _defaultRandom(int? seed) =>
      seed == null ? Random.secure() : Random(seed);
}

final matchEnvironmentProvider =
    Provider<MatchEnvironment>((ref) => const MatchEnvironment());
