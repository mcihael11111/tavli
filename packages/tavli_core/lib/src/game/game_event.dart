/// What the reducer reports happened (design spec §5.5). These are the
/// only things the board animates.
library;

import '../board/side.dart';
import '../play/step.dart';
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
  String toString() => 'OpeningRolled($dieOne, $dieTwo, ${starter?.name})';
}

/// [side] rolled [dice] (the two dice as rolled).
final class DiceRolled extends GameEvent {
  final Side side;
  final List<int> dice;
  const DiceRolled(this.side, this.dice);

  @override
  String toString() => 'DiceRolled(${side.name}, $dice)';
}

/// [side] played [step] (with its hit, pin and bear-off effects).
final class CheckerMoved extends GameEvent {
  final Side side;
  final AppliedStep step;
  const CheckerMoved(this.side, this.step);

  @override
  String toString() => 'CheckerMoved(${side.name}, $step)';
}

/// [side] took back [step]; its effects were reversed.
final class StepUndone extends GameEvent {
  final Side side;
  final AppliedStep step;
  const StepUndone(this.side, this.step);

  @override
  String toString() => 'StepUndone(${side.name}, $step)';
}

/// [side] committed the play [steps].
final class PlayCommitted extends GameEvent {
  final Side side;
  final List<Step> steps;
  const PlayCommitted(this.side, this.steps);

  @override
  String toString() => 'PlayCommitted(${side.name}, $steps)';
}

/// [side] had no legal play with [dice] (the two dice as rolled; G9);
/// the turn passed.
final class TurnPassed extends GameEvent {
  final Side side;
  final List<int> dice;
  const TurnPassed(this.side, this.dice);

  @override
  String toString() => 'TurnPassed(${side.name}, $dice)';
}

/// Gul Bara D16-B: [to] must now play the cascade remainder [dice].
final class RemainderPassed extends GameEvent {
  final Side to;
  final List<int> dice;
  const RemainderPassed(this.to, this.dice);

  @override
  String toString() => 'RemainderPassed(${to.name}, $dice)';
}

/// [by] offered to double the cube to [value].
final class CubeOffered extends GameEvent {
  final Side by;
  final int value;
  const CubeOffered(this.by, this.value);

  @override
  String toString() => 'CubeOffered(${by.name}, $value)';
}

/// [by] took the double; the cube is now [newValue], owned by [by].
final class CubeTaken extends GameEvent {
  final Side by;
  final int newValue;
  const CubeTaken(this.by, this.newValue);

  @override
  String toString() => 'CubeTaken(${by.name}, $newValue)';
}

/// [by] dropped the double and lost.
final class CubeDropped extends GameEvent {
  final Side by;
  const CubeDropped(this.by);

  @override
  String toString() => 'CubeDropped(${by.name})';
}

/// The game is over with [result].
final class GameEnded extends GameEvent {
  final GameResult result;
  const GameEnded(this.result);

  @override
  String toString() => 'GameEnded($result)';
}
