/// What the reducer reports happened (design spec §5.5). These are the
/// only things the board animates.
///
/// Events are immutable values: lists are unmodifiable and every event has
/// value equality.
library;

import '../board/side.dart';
import '../play/step.dart';
import '../util/list_eq.dart';
import 'game_result.dart';

sealed class GameEvent {
  const GameEvent();
}

/// The opening roll: [dieOne] is side one's die, [dieTwo] side two's.
/// [starter] is null on a tie (G7: roll again).
final class OpeningRolled extends GameEvent {
  final int dieOne, dieTwo;
  final Side? starter;
  const OpeningRolled(this.dieOne, this.dieTwo, this.starter);

  @override
  bool operator ==(Object other) =>
      other is OpeningRolled &&
      other.dieOne == dieOne &&
      other.dieTwo == dieTwo &&
      other.starter == starter;

  @override
  int get hashCode => Object.hash('opening', dieOne, dieTwo, starter);

  @override
  String toString() => 'OpeningRolled($dieOne, $dieTwo, ${starter?.name})';
}

/// [side] rolled [dice]: the two dice as rolled, e.g. `[5, 5]`. The dice
/// to play (`[5, 5, 5, 5]`, or a Gul Bara cascade queue) are in the new
/// state's `dice`.
final class DiceRolled extends GameEvent {
  final Side side;
  final List<int> dice;
  DiceRolled(this.side, List<int> dice) : dice = List.unmodifiable(dice);

  @override
  bool operator ==(Object other) =>
      other is DiceRolled && other.side == side && listEq(other.dice, dice);

  @override
  int get hashCode => Object.hash('rolled', side, Object.hashAll(dice));

  @override
  String toString() => 'DiceRolled(${side.name}, $dice)';
}

/// [side] played [step] (with its hit, pin and bear-off effects).
final class CheckerMoved extends GameEvent {
  final Side side;
  final AppliedStep step;
  const CheckerMoved(this.side, this.step);

  @override
  bool operator ==(Object other) =>
      other is CheckerMoved && other.side == side && other.step == step;

  @override
  int get hashCode => Object.hash('moved', side, step);

  @override
  String toString() => 'CheckerMoved(${side.name}, $step)';
}

/// [side] took back [step]; its effects were reversed.
final class StepUndone extends GameEvent {
  final Side side;
  final AppliedStep step;
  const StepUndone(this.side, this.step);

  @override
  bool operator ==(Object other) =>
      other is StepUndone && other.side == side && other.step == step;

  @override
  int get hashCode => Object.hash('undone', side, step);

  @override
  String toString() => 'StepUndone(${side.name}, $step)';
}

/// [side] committed the play [steps].
final class PlayCommitted extends GameEvent {
  final Side side;
  final List<Step> steps;
  PlayCommitted(this.side, List<Step> steps) : steps = List.unmodifiable(steps);

  @override
  bool operator ==(Object other) =>
      other is PlayCommitted &&
      other.side == side &&
      listEq(other.steps, steps);

  @override
  int get hashCode => Object.hash('committed', side, Object.hashAll(steps));

  @override
  String toString() => 'PlayCommitted(${side.name}, $steps)';
}

/// [side] had no legal play with [dice] (the two dice as rolled; G9);
/// the turn passed.
final class TurnPassed extends GameEvent {
  final Side side;
  final List<int> dice;
  TurnPassed(this.side, List<int> dice) : dice = List.unmodifiable(dice);

  @override
  bool operator ==(Object other) =>
      other is TurnPassed && other.side == side && listEq(other.dice, dice);

  @override
  int get hashCode => Object.hash('passed', side, Object.hashAll(dice));

  @override
  String toString() => 'TurnPassed(${side.name}, $dice)';
}

/// Gul Bara D16-B: [to] must now play the cascade remainder [dice]. If
/// [to] cannot play any of it, no other event follows: the new state has
/// [to] about to roll its own turn.
final class RemainderPassed extends GameEvent {
  final Side to;
  final List<int> dice;
  RemainderPassed(this.to, List<int> dice) : dice = List.unmodifiable(dice);

  @override
  bool operator ==(Object other) =>
      other is RemainderPassed && other.to == to && listEq(other.dice, dice);

  @override
  int get hashCode => Object.hash('remainder', to, Object.hashAll(dice));

  @override
  String toString() => 'RemainderPassed(${to.name}, $dice)';
}

/// [by] offered to double the cube to [value].
final class CubeOffered extends GameEvent {
  final Side by;
  final int value;
  const CubeOffered(this.by, this.value);

  @override
  bool operator ==(Object other) =>
      other is CubeOffered && other.by == by && other.value == value;

  @override
  int get hashCode => Object.hash('offered', by, value);

  @override
  String toString() => 'CubeOffered(${by.name}, $value)';
}

/// [by] took the double; the cube is now [newValue], owned by [by].
final class CubeTaken extends GameEvent {
  final Side by;
  final int newValue;
  const CubeTaken(this.by, this.newValue);

  @override
  bool operator ==(Object other) =>
      other is CubeTaken && other.by == by && other.newValue == newValue;

  @override
  int get hashCode => Object.hash('taken', by, newValue);

  @override
  String toString() => 'CubeTaken(${by.name}, $newValue)';
}

/// [by] dropped the double and lost.
final class CubeDropped extends GameEvent {
  final Side by;
  const CubeDropped(this.by);

  @override
  bool operator ==(Object other) => other is CubeDropped && other.by == by;

  @override
  int get hashCode => Object.hash('dropped', by);

  @override
  String toString() => 'CubeDropped(${by.name})';
}

/// The game is over with [result].
final class GameEnded extends GameEvent {
  final GameResult result;
  const GameEnded(this.result);

  @override
  bool operator ==(Object other) =>
      other is GameEnded && other.result == result;

  @override
  int get hashCode => Object.hash('ended', result);

  @override
  String toString() => 'GameEnded($result)';
}
