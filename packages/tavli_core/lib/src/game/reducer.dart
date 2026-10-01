part of 'game_state.dart';

/// The side that must send [a] in [s], or null when either side (or the
/// system) may: the opening roll, or an action that fits no phase.
///
/// - `RollDice`, `StepAction`, `UndoStep`, `CommitPlay`, `OfferDouble`:
///   the side to move;
/// - `Take`, `Drop`: the side the double was offered to;
/// - `Resign`, `ClockTimeout`: the action's own side.
Side? actorOf(GameState s, GameAction a) => switch (a) {
      RollOpening() => null,
      RollDice() || StepAction() || UndoStep() || CommitPlay() => s.sideToMove,
      OfferDouble() => s.sideToMove,
      Take() || Drop() => s.cube.offeredBy?.opponent,
      Resign(:final side) || ClockTimeout(:final side) => side,
    };

/// Applies [a] to [s] (design spec §5.3; plan Task 10 phase machine).
///
/// With [by] (the authenticated sender, e.g. on the game server), an
/// action whose [actorOf] is another side is a `notYourAction` violation.
///
/// Never throws on bad input: a rejected action returns a [RuleViolation]
/// and leaves [s] as it was.
ReduceResult reduce(GameState s, GameAction a, {Side? by}) {
  if (s.phase == GamePhase.gameOver) {
    return const RuleViolation(ViolationCode.gameOver, 'the game is over');
  }
  if (by != null) {
    final actor = actorOf(s, a);
    if (actor != null && actor != by) {
      return RuleViolation(
        ViolationCode.notYourAction,
        '$a is for ${actor.name}, not ${by.name}',
      );
    }
  }
  final phase = s.phase;
  return switch (a) {
    Resign(:final side) => _forfeit(s, side, ResultKind.resign),
    ClockTimeout(:final side) => _forfeit(s, side, ResultKind.timeout),
    RollOpening() when phase == GamePhase.opening => _opening(s, a),
    RollDice() when phase == GamePhase.awaitingRoll => _roll(s, a),
    StepAction() when phase == GamePhase.moving => _step(s, a.step),
    UndoStep() when phase == GamePhase.moving => _undo(s),
    CommitPlay() when phase == GamePhase.moving => _commit(s),
    OfferDouble() when phase == GamePhase.awaitingRoll => _offer(s),
    Take() when phase == GamePhase.cubeOffered => _take(s),
    Drop() when phase == GamePhase.cubeOffered => _drop(s),
    _ => RuleViolation(ViolationCode.wrongPhase, '$a in ${phase.name}'),
  };
}

bool _isDie(int d) => d >= 1 && d <= 6;

RuleViolation _badDice(int a, int b) =>
    RuleViolation(ViolationCode.invalidDice, 'dice $a, $b not in 1..6');

/// G7 and D1: a tie stays in `opening`; otherwise the higher die starts.
ReduceResult _opening(GameState s, RollOpening a) {
  final one = a.dieOne, two = a.dieTwo;
  if (!_isDie(one) || !_isDie(two)) return _badDice(one, two);
  if (one == two) return GameUpdate(s, [OpeningRolled(one, two, null)]);
  final winner = one > two ? Side.one : Side.two;
  final events = <GameEvent>[OpeningRolled(one, two, winner)];
  switch (s.variant.rules.opening) {
    case OpeningProcedure.playOpeningDice:
      final hi = one > two ? one : two, lo = one > two ? two : one;
      return _beginMoving(s, winner, [hi, lo], [hi, lo],
          rollIndex: 1, events: events);
    case OpeningProcedure.winnerRerolls:
      return GameUpdate(
        s._copy(
          sideToMove: winner,
          phase: GamePhase.awaitingRoll,
          context: _startContext(winner, s.turnsTaken, const []),
        ),
        events,
      );
  }
}

/// Rolls the dice; doubles cascade in Gul Bara after its normal rolls
/// (D15).
ReduceResult _roll(GameState s, RollDice a) {
  final d1 = a.d1, d2 = a.d2;
  if (!_isDie(d1) || !_isDie(d2)) return _badDice(d1, d2);
  final side = s.sideToMove!;
  final rollIndex = s.rollIndex + 1;
  final cascade = s.variant.rules.cascade;
  final cascades =
      cascade != null && d1 == d2 && rollIndex > cascade.normalRolls;
  final dice = cascades
      ? cascadeQueue(d1)
      : d1 == d2
          ? [d1, d1, d1, d1]
          : [d1, d2];
  return _beginMoving(
    s,
    side,
    dice,
    [d1, d2],
    rollIndex: rollIndex,
    cascadeMode: cascades,
    events: [
      DiceRolled(side, [d1, d2]),
    ],
  );
}

/// Starts [side]'s moving phase with [dice] (from the two dice [rolled]);
/// with no legal play (G9) the turn passes at once.
ReduceResult _beginMoving(
  GameState s,
  Side side,
  List<int> dice,
  List<int> rolled, {
  required int rollIndex,
  bool cascadeMode = false,
  required List<GameEvent> events,
}) {
  final moving = s._copy(
    sideToMove: side,
    phase: GamePhase.moving,
    turnStart: s.position,
    dice: dice,
    cascadeMode: cascadeMode,
    steps: const [],
    context: _startContext(side, s.turnsTaken, dice),
    rollIndex: rollIndex,
  );
  if (moving.tree.hasPlay) return GameUpdate(moving, events);
  events.add(TurnPassed(side, rolled));
  return GameUpdate(_passTurn(moving), events);
}

/// The side to move has finished its turn: the opponent is to roll.
GameState _passTurn(GameState s) {
  final side = s.sideToMove!, next = side.opponent;
  final turns = {...s.turnsTaken, side: s.turnsTaken[side]! + 1};
  return s._copy(
    sideToMove: next,
    phase: GamePhase.awaitingRoll,
    turnStart: s.position,
    dice: const [],
    cascadeMode: false,
    steps: const [],
    context: _startContext(next, turns, const []),
    turnsTaken: turns,
  );
}

/// One step of the current play; then the game-end checks (Task 11).
ReduceResult _step(GameState s, Step step) {
  if (s.node.child(step) == null) {
    return RuleViolation(
      ViolationCode.illegalStep,
      '$step does not continue a legal play',
    );
  }
  final side = s.sideToMove!, rules = s.variant.rules;
  final m = s.position.toMutable();
  final applied = StepRules(rules).apply(m, side, step);
  final position = m.freeze();
  final next = s._copy(
    position: position,
    steps: [...s.steps, step],
    context: StepValidators(rules).next(s.context, applied),
    keepTree: true,
  );
  final events = <GameEvent>[CheckerMoved(side, applied)];
  final result = checkGameEnd(
    position,
    rules,
    justMoved: side,
    cubeValue: s.cube.value,
  );
  if (result == null) return GameUpdate(next, events);
  events.add(GameEnded(result));
  return GameUpdate(
    next._copy(phase: GamePhase.gameOver, result: result, keepTree: true),
    events,
  );
}

/// Takes back the last step: replays the others from the turn start.
ReduceResult _undo(GameState s) {
  if (s.steps.isEmpty) {
    return const RuleViolation(
      ViolationCode.nothingToUndo,
      'no step taken this play',
    );
  }
  final side = s.sideToMove!, rules = s.variant.rules;
  final stepRules = StepRules(rules), validators = StepValidators(rules);
  final kept = s.steps.sublist(0, s.steps.length - 1);
  final m = s.turnStart.toMutable();
  var ctx = _startContext(side, s.turnsTaken, s.dice);
  for (final step in kept) {
    ctx = validators.next(ctx, stepRules.apply(m, side, step));
  }
  final position = m.freeze();
  final undone = stepRules.apply(m, side, s.steps.last);
  return GameUpdate(
    s._copy(position: position, steps: kept, context: ctx, keepTree: true),
    [StepUndone(side, undone)],
  );
}

/// Ends the turn with a full legal play.
ReduceResult _commit(GameState s) {
  if (!s.node.isComplete) {
    return const RuleViolation(
      ViolationCode.incompletePlay,
      'the steps taken are not a full legal play',
    );
  }
  final side = s.sideToMove!;
  // A Gul Bara cascade that fell short leaves `tree.remainder` for the
  // opponent (D16-B). Handing it over is plan Task 12; until then the turn
  // passes normally and the remainder is dropped.
  return GameUpdate(_passTurn(s), [PlayCommitted(side, s.steps)]);
}
