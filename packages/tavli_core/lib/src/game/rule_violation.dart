/// What `reduce` returns: a [GameUpdate] or a [RuleViolation].
library;

import 'game_event.dart';
import 'game_state.dart';

/// The result of `reduce`; `switch` over [GameUpdate] and [RuleViolation].
sealed class ReduceResult {
  const ReduceResult();
}

/// The action was accepted: the new [state] and what happened, in order.
final class GameUpdate extends ReduceResult {
  final GameState state;
  final List<GameEvent> events;
  const GameUpdate(this.state, this.events);
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

  /// The variant or this game has no cube.
  cubeUnavailable,

  /// The cube exists but this side may not double now.
  cannotDouble,

  /// The game is over.
  gameOver,
}

/// The action was rejected; the state is unchanged.
final class RuleViolation extends ReduceResult {
  final ViolationCode code;
  final String message;
  const RuleViolation(this.code, this.message);

  @override
  String toString() => 'RuleViolation(${code.name}: $message)';
}
