part of 'game_state.dart';

// Gul Bara remainder turns (D16-B; plan Task 12).

/// The remainder [s]'s player must hand over after this play: the cascade
/// entries no legal play reaches, under D16-B, outside a remainder turn.
List<int> _pendingRemainder(GameState s) {
  final failure = s.variant.rules.cascade?.onFailure;
  if (!s.cascadeMode ||
      s.remainderTurn ||
      failure != CascadeFailure.opponentPlaysRemainder) {
    return const [];
  }
  return s.tree.remainder;
}

/// [s]'s player has finished its turn leaving [remainder]: the opponent
/// plays it now, as a cascade that stops at its own first failure, then
/// takes its own turn. With no play at all it goes straight to rolling.
ReduceResult _handOver(
  GameState s,
  List<int> remainder,
  List<GameEvent> events,
) {
  final side = s.sideToMove!, to = side.opponent;
  final turns = {...s.turnsTaken, side: s.turnsTaken[side]! + 1};
  events.add(RemainderPassed(to, remainder));
  final turn = s._copy(
    sideToMove: to,
    phase: GamePhase.moving,
    turnStart: s.position,
    dice: remainder,
    cascadeMode: true,
    steps: const [],
    context: _startContext(to, turns, remainder),
    turnsTaken: turns,
    pendingRemainder: const [],
    remainderTurn: true,
  );
  if (turn.tree.hasPlay) return GameUpdate(turn, events);
  return GameUpdate(_endRemainderTurn(turn), events);
}

/// The remainder player now rolls for its own turn. A remainder turn is
/// not a turn of its own: `turnsTaken` and `rollIndex` stay, and the
/// remainder's own unplayable tail is dropped.
GameState _endRemainderTurn(GameState s) {
  final side = s.sideToMove!;
  return s._copy(
    phase: GamePhase.awaitingRoll,
    turnStart: s.position,
    dice: const [],
    cascadeMode: false,
    steps: const [],
    context: _startContext(side, s.turnsTaken, const []),
    pendingRemainder: const [],
    remainderTurn: false,
  );
}
