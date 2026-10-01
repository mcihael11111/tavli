import '../board/board_view.dart';
import '../board/side.dart';
import '../game/game_result.dart';
import '../variant/variant_rules.dart';

/// Whether the step [justMoved] just made ended the game (matrix A4):
/// - G8: [justMoved] has borne off all 15 checkers;
/// - mother rule (D8-D10), when the opponent's mother (its last checker on
///   its start, pip 24) is pinned:
///   - both mothers pinned: a draw;
///   - D8a/D8b: [justMoved] has no checker left on its own start: a win,
///     at once (D8a) or the moment its last start checker leaves (D8b).
///
/// A game-ending step terminates its play, which counts as using all its
/// dice (G4). Results and scoring come later; this is the pure predicate.
bool endsGame(BoardView p, VariantRules r, Side justMoved) {
  if (p.checkersOnBoard(justMoved) == 0) return true;
  if (r.pin?.motherRule != true) return false;
  final them = justMoved.opponent;
  if (!p.isPinned(them, 24)) return false;
  return p.isPinned(justMoved, 24) || p.count(justMoved, 24) == 0;
}

/// PROVISIONAL (Task 10): the result of the game ended by [justMoved]'s
/// last step, or null if [endsGame] is false. Task 11 replaces this with
/// full scoring (gammon, triple, checkers remaining).
///
/// For now:
/// - G8 bear-off: [justMoved] wins `single`, 1 x [cubeValue];
/// - both mothers pinned: a draw, `pin.bothPinnedPoints` each;
/// - mother rule: [justMoved] wins `mother`, `pin.motherPoints`.
GameResult? checkGameEnd(
  BoardView p,
  VariantRules rules, {
  required Side justMoved,
  required int cubeValue,
}) {
  if (!endsGame(p, rules, justMoved)) return null;
  if (p.checkersOnBoard(justMoved) == 0) {
    return GameResult(
      winner: justMoved,
      kind: ResultKind.single,
      points: cubeValue,
      cubeValue: cubeValue,
    );
  }
  final pin = rules.pin!;
  if (p.isPinned(justMoved, 24)) {
    return GameResult(
      winner: null,
      kind: ResultKind.draw,
      points: pin.bothPinnedPoints,
      cubeValue: cubeValue,
    );
  }
  return GameResult(
    winner: justMoved,
    kind: ResultKind.mother,
    points: pin.motherPoints,
    cubeValue: cubeValue,
  );
}
