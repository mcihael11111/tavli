/// What the reducers return: `reduce` a [GameUpdate] or a
/// [RuleViolation]; `reduceMatch` a [MatchUpdate] or a [RuleViolation].
library;

import '../match/match.dart';
import '../match/match_event.dart';
import 'game_event.dart';
import 'game_state.dart';

/// The result of `reduce`; `switch` over [GameUpdate] and [RuleViolation].
sealed class ReduceResult {
  const ReduceResult();
}

/// The result of `reduceMatch`; `switch` over [MatchUpdate] and
/// [RuleViolation].
sealed class MatchReduceResult {
  const MatchReduceResult();
}

/// A match action was accepted: the new [state] and what happened, in
/// order: the game's events as [InGame], [GameStarted] for `NextGame`,
/// and [MatchEnded] once the match is decided.
final class MatchUpdate extends MatchReduceResult {
  final MatchState state;

  /// Unmodifiable.
  final List<MatchEvent> events;
  MatchUpdate(this.state, List<MatchEvent> events)
      : events = List.unmodifiable(events);
}

/// The action was accepted: the new [state] and what happened, in order.
final class GameUpdate extends ReduceResult {
  final GameState state;

  /// Unmodifiable.
  final List<GameEvent> events;
  GameUpdate(this.state, List<GameEvent> events)
      : events = List.unmodifiable(events);
}

/// Why an action was rejected.
enum ViolationCode {
  /// The action does not fit the current phase.
  wrongPhase,

  /// A die outside 1..6.
  invalidDice,

  /// The step does not continue any legal play.
  illegalStep,

  /// Commit before the steps form a full legal play.
  incompletePlay,

  /// Undo with no step taken this play.
  nothingToUndo,

  /// `SubmitPlay` after steps were already taken this play (undo them
  /// first, or keep playing step by step).
  stepsAlreadyTaken,

  /// The variant or this game has no cube.
  cubeUnavailable,

  /// The cube exists but this side may not double now.
  cannotDouble,

  /// The game (or, for `NextGame`, the match) is over.
  gameOver,

  /// The authenticated sender is not the side this action belongs to
  /// (`reduce(..., by:)`).
  notYourAction,
}

/// The action was rejected; the state is unchanged.
final class RuleViolation extends ReduceResult implements MatchReduceResult {
  final ViolationCode code;
  final String message;
  const RuleViolation(this.code, this.message);

  @override
  bool operator ==(Object other) =>
      other is RuleViolation && other.code == code && other.message == message;

  @override
  int get hashCode => Object.hash(code, message);

  @override
  String toString() => 'RuleViolation(${code.name}: $message)';
}
