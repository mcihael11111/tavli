/// Match actions (plan Task 14) and their JSON (Task 15).
library;

import '../game/game_action.dart';
import '../serial/json_read.dart';

/// An input to `reduceMatch`.
///
/// JSON: `{"type": "gameMove", "action": {...}}` or `{"type": "nextGame"}`.
sealed class MatchAction {
  const MatchAction();

  Map<String, Object?> toJson();

  /// Parses [toJson] output from any decoded JSON. Throws only
  /// [FormatException].
  static MatchAction fromJson(Object? json) {
    final r = JsonReader(json, 'MatchAction');
    return switch (r.raw('type')) {
      'gameMove' => GameMove(GameAction.fromJson(r.raw('action'))),
      'nextGame' => const NextGame(),
      _ => r.fail('type', 'gameMove or nextGame'),
    };
  }
}

/// An action for the current game.
final class GameMove extends MatchAction {
  final GameAction action;
  const GameMove(this.action);

  @override
  Map<String, Object?> toJson() =>
      {'type': 'gameMove', 'action': action.toJson()};

  @override
  bool operator ==(Object other) => other is GameMove && other.action == action;

  @override
  int get hashCode => Object.hash('move', action);

  @override
  String toString() => 'GameMove($action)';
}

/// Starts the next game of the cycle once the current one is over.
final class NextGame extends MatchAction {
  const NextGame();

  @override
  Map<String, Object?> toJson() => {'type': 'nextGame'};

  @override
  bool operator ==(Object other) => other is NextGame;

  @override
  int get hashCode => 'nextGame'.hashCode;

  @override
  String toString() => 'NextGame()';
}
