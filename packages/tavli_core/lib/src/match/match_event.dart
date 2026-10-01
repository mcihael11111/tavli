/// What `reduceMatch` reports happened (plan Task 14): the game's events,
/// plus the match's own. Immutable values with value equality.
library;

import '../board/side.dart';
import '../game/game_event.dart';
import '../variant/variant.dart';

sealed class MatchEvent {
  const MatchEvent();
}

/// [event] happened in the current game.
final class InGame extends MatchEvent {
  final GameEvent event;
  const InGame(this.event);

  @override
  bool operator ==(Object other) => other is InGame && other.event == event;

  @override
  int get hashCode => Object.hash('inGame', event);

  @override
  String toString() => 'InGame($event)';
}

/// Game [index] (0-based in the match) of [variant] started: [starter]
/// rolls first, or null for an opening roll; [crawford] marks the
/// Crawford game.
///
/// Emitted only by `NextGame`, so never for game 0: that game exists from
/// `MatchState.initial` on, and its variant, starter and Crawford flag
/// are read from `MatchState.initial(config).game`.
final class GameStarted extends MatchEvent {
  final int index;
  final Variant variant;
  final Side? starter;
  final bool crawford;
  const GameStarted(this.index, this.variant, this.starter, this.crawford);

  @override
  bool operator ==(Object other) =>
      other is GameStarted &&
      other.index == index &&
      other.variant == variant &&
      other.starter == starter &&
      other.crawford == crawford;

  @override
  int get hashCode => Object.hash('started', index, variant, starter, crawford);

  @override
  String toString() => 'GameStarted($index, ${variant.name}, '
      '${starter?.name}, crawford: $crawford)';
}

/// The match is over: [winner] (null for a drawn single game) with the
/// final [scores].
final class MatchEnded extends MatchEvent {
  final Side? winner;

  /// Unmodifiable.
  final Map<Side, int> scores;
  MatchEnded(this.winner, Map<Side, int> scores)
      : scores = Map.unmodifiable(scores);

  @override
  bool operator ==(Object other) =>
      other is MatchEnded &&
      other.winner == winner &&
      Side.values.every((s) => other.scores[s] == scores[s]) &&
      other.scores.length == scores.length;

  @override
  int get hashCode => Object.hash(
      'matchEnded', winner, Object.hashAll(Side.values.map((s) => scores[s])));

  @override
  String toString() => 'MatchEnded(${winner?.name}, $scores)';
}
