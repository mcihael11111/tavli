part of 'game_state.dart';

/// Resign or clock timeout by [loser], in any phase but `gameOver`: the
/// opponent wins what the board threatens, times the cube, as [kind]
/// (matrix A9, [forfeitResult]). A pending cube offer lapses.
ReduceResult _forfeit(GameState s, Side loser, ResultKind kind) {
  final result = forfeitResult(
    s.position,
    s.variant.rules,
    loser,
    kind,
    s.cube.value,
  );
  return GameUpdate(
    s._copy(
      phase: GamePhase.gameOver,
      cube: s.cube.clearOffer(),
      result: result,
      keepTree: true,
    ),
    [GameEnded(result)],
  );
}
