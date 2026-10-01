part of 'game_state.dart';

// Cube transitions of the reducer (D7; plan Task 13).

/// D7: the side to move offers to double before rolling.
ReduceResult _offer(GameState s) {
  final side = s.sideToMove!, cube = s.cube;
  if (!s.variant.rules.cube.available || !cube.enabled) {
    return const RuleViolation(
      ViolationCode.cubeUnavailable,
      'this game has no doubling cube',
    );
  }
  if (s.crawfordGame || cube.value >= 64) {
    return RuleViolation(
      ViolationCode.cannotDouble,
      s.crawfordGame ? 'no doubling in the Crawford game' : 'cube at 64',
    );
  }
  if (cube.owner != null && cube.owner != side) {
    return const RuleViolation(
      ViolationCode.cannotDouble,
      'the opponent owns the cube',
    );
  }
  return GameUpdate(
    s._copy(
      phase: GamePhase.cubeOffered,
      cube: cube.copyWith(offeredBy: side),
    ),
    [CubeOffered(side, cube.value * 2)],
  );
}

/// The opponent takes: the cube doubles and passes to the taker; the
/// offerer goes on to roll.
ReduceResult _take(GameState s) {
  final taker = s.cube.offeredBy!.opponent;
  final value = s.cube.value * 2;
  return GameUpdate(
    s._copy(
      phase: GamePhase.awaitingRoll,
      cube: s.cube.copyWith(value: value, owner: taker).clearOffer(),
    ),
    [CubeTaken(taker, value)],
  );
}

/// The opponent drops: the offerer wins a single game at the current
/// value.
ReduceResult _drop(GameState s) {
  final offerer = s.cube.offeredBy!;
  final value = s.cube.value;
  final result = GameResult(
    winner: offerer,
    kind: ResultKind.single,
    points: value,
    cubeValue: value,
  );
  return GameUpdate(
    s._copy(
      phase: GamePhase.gameOver,
      cube: s.cube.clearOffer(),
      result: result,
    ),
    [CubeDropped(offerer.opponent), GameEnded(result)],
  );
}
