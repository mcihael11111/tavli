import '../board/board_view.dart';
import '../board/side.dart';
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
/// dice (G4). This is the pure predicate; `checkGameEnd` scores the end.
bool endsGame(BoardView p, VariantRules r, Side justMoved) {
  if (p.checkersOnBoard(justMoved) == 0) return true;
  if (r.pin?.motherRule != true) return false;
  final them = justMoved.opponent;
  if (!p.isPinned(them, 24)) return false;
  return p.isPinned(justMoved, 24) || p.count(justMoved, 24) == 0;
}
