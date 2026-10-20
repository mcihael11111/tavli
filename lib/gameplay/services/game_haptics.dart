/// One haptic per gameplay event (design §5.3).
library;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'gameplay_settings.dart';

/// The gameplay events that buzz.
enum GameHapticEvent {
  select,
  place,
  hit,
  bearOff,
  diceRoll,
  doubles,
  cubeOffer,
  cubeAnswer,
  gameWon,
  gameLost,
  illegal,
}

/// The strength of one haptic.
enum HapticKind { selection, light, medium, heavy }

/// Delivers one haptic of the given kind.
typedef HapticSink = void Function(HapticKind kind);

/// Fires exactly one haptic per [fire] call (the legacy path fired one from
/// the audio service and another from the screen), and none when the
/// haptics setting is off.
class GameHaptics {
  final bool Function() _enabled;
  final HapticSink _sink;

  GameHaptics({required bool Function() enabled, HapticSink? sink})
      : _enabled = enabled,
        _sink = sink ?? _platformSink;

  /// The haptic kind for [e].
  static HapticKind kindOf(GameHapticEvent e) => switch (e) {
        GameHapticEvent.select => HapticKind.selection,
        GameHapticEvent.illegal => HapticKind.selection,
        GameHapticEvent.place => HapticKind.light,
        GameHapticEvent.bearOff => HapticKind.light,
        GameHapticEvent.diceRoll => HapticKind.medium,
        GameHapticEvent.cubeOffer => HapticKind.medium,
        GameHapticEvent.cubeAnswer => HapticKind.medium,
        GameHapticEvent.hit => HapticKind.heavy,
        GameHapticEvent.doubles => HapticKind.heavy,
        GameHapticEvent.gameWon => HapticKind.heavy,
        GameHapticEvent.gameLost => HapticKind.heavy,
      };

  void fire(GameHapticEvent e) {
    if (!_enabled()) return;
    _sink(kindOf(e));
  }

  static void _platformSink(HapticKind k) {
    switch (k) {
      case HapticKind.selection:
        HapticFeedback.selectionClick();
      case HapticKind.light:
        HapticFeedback.lightImpact();
      case HapticKind.medium:
        HapticFeedback.mediumImpact();
      case HapticKind.heavy:
        HapticFeedback.heavyImpact();
    }
  }
}

final gameHapticsProvider = Provider<GameHaptics>((ref) {
  final settings = ref.watch(gameplaySettingsProvider);
  return GameHaptics(enabled: () => settings.haptics);
});
