/// Match actions (plan Task 14) and their JSON (Task 15).
library;

import '../board/side.dart';
import '../game/game_action.dart';
import '../serial/json_read.dart';

/// An input to `reduceMatch`.
///
/// JSON: `{"type": "gameMove", "action": {...}}`, `{"type": "nextGame"}`
/// or `{"type": "forfeitMatch", "side": "one"|"two"}`.
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
      'forfeitMatch' => ForfeitMatch(r.side('side')),
      _ => r.fail('type', 'gameMove, nextGame or forfeitMatch'),
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

/// [side] forfeits the whole match (e.g. leaves an online match): the
/// current game, if not over, is resigned (A9 scoring), and the opponent
/// wins the match whatever the scores.
final class ForfeitMatch extends MatchAction {
  final Side side;
  const ForfeitMatch(this.side);

  @override
  Map<String, Object?> toJson() =>
      {'type': 'forfeitMatch', 'side': side.toJson()};

  @override
  bool operator ==(Object other) => other is ForfeitMatch && other.side == side;

  @override
  int get hashCode => Object.hash('forfeitMatch', side);

  @override
  String toString() => 'ForfeitMatch(${side.name})';
}
