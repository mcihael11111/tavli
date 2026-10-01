/// How a game ended and what it scored (design spec §5.4).
library;

import '../board/board_view.dart';
import '../board/side.dart';
import '../variant/variant_rules.dart';

/// The kind of game end.
enum ResultKind {
  single,
  gammon,
  triple,
  mother,
  draw,
  checkersRemaining,
  resign,
  timeout,
}

/// The result of a finished game.
final class GameResult {
  /// The winner; null for a draw.
  final Side? winner;
  final ResultKind kind;

  /// Points to the winner, cube included; for a draw, points to EACH side.
  final int points;

  /// The cube value the game ended at.
  final int cubeValue;

  const GameResult({
    required this.winner,
    required this.kind,
    required this.points,
    required this.cubeValue,
  });

  @override
  bool operator ==(Object other) =>
      other is GameResult &&
      other.winner == winner &&
      other.kind == kind &&
      other.points == points &&
      other.cubeValue == cubeValue;

  @override
  int get hashCode => Object.hash(winner, kind, points, cubeValue);

  @override
  String toString() => 'GameResult(${winner?.name ?? 'draw'}, ${kind.name}, '
      '$points, cube $cubeValue)';
}

/// The result if the step [justMoved] just made ended the game, else null
/// (plan Task 11; matrix G8, D6, D8-D10, D21). Non-null exactly when
/// `endsGame(p, rules, justMoved)` is true: only [justMoved] can win, and
/// only the opponent's mother is examined.
///
/// 1. Bear-off win: [justMoved] has borne off all 15.
///    - Checkers-remaining scoring (D21): the loser's checkers on board.
///    - Otherwise gammon (2) if the loser has borne off none, else single
///      (1); upgraded to `scoring.triple` when set, the loser has borne
///      off none and the triple condition holds (bar or the winner's home
///      = the loser's pips 19..24). Times [cubeValue].
/// 2. Mother rule, when the opponent's mother (its pip 24) is pinned: a
///    draw at `pin.bothPinnedPoints` each if [justMoved]'s mother is
///    pinned too; else a `mother` win at `pin.motherPoints` once
///    [justMoved] has no checker left on its own start.
///
/// Mother, draw and checkers-remaining results are not multiplied: those
/// variants have no cube, so [cubeValue] must be 1 there (asserted).
GameResult? checkGameEnd(
  BoardView p,
  VariantRules rules, {
  required Side justMoved,
  required int cubeValue,
}) {
  if (p.borneOff(justMoved) == 15) {
    return _bearOffResult(p, rules, justMoved, cubeValue);
  }
  final pin = rules.pin;
  final them = justMoved.opponent;
  if (pin == null || !pin.motherRule || !p.isPinned(them, 24)) return null;
  assert(cubeValue == 1, 'pinning games have no cube');
  if (p.isPinned(justMoved, 24)) {
    return GameResult(
      winner: null,
      kind: ResultKind.draw,
      points: pin.bothPinnedPoints,
      cubeValue: cubeValue,
    );
  }
  if (p.count(justMoved, 24) > 0) return null;
  return GameResult(
    winner: justMoved,
    kind: ResultKind.mother,
    points: pin.motherPoints,
    cubeValue: cubeValue,
  );
}

/// Matrix A9: [loser] resigns or runs out of time ([kind] is `resign` or
/// `timeout`) and forfeits what the board threatens, times [cubeValue]:
/// - checkers-remaining scoring (Tawla 31): the loser's checkers on board;
/// - mother rule with the loser's mother pinned: `pin.motherPoints`;
/// - otherwise triple if the variant has one, the loser has borne off
///   none and the triple condition holds; gammon if the loser has borne
///   off none; else single.
///
/// So resigning at the start, with nothing borne off, concedes a gammon
/// (or a triple where the start position meets the triple condition).
GameResult forfeitResult(
  BoardView p,
  VariantRules rules,
  Side loser,
  ResultKind kind,
  int cubeValue,
) {
  final int points;
  final pin = rules.pin;
  if (rules.scoring.model == ScoringModel.checkersRemaining) {
    points = p.checkersOnBoard(loser);
  } else if (pin != null && pin.motherRule && p.isPinned(loser, 24)) {
    points = pin.motherPoints;
  } else {
    points = _margin(p, rules.scoring, loser).points;
  }
  return GameResult(
    winner: loser.opponent,
    kind: kind,
    points: points * cubeValue,
    cubeValue: cubeValue,
  );
}

GameResult _bearOffResult(
  BoardView p,
  VariantRules rules,
  Side winner,
  int cubeValue,
) {
  final loser = winner.opponent;
  final scoring = rules.scoring;
  if (scoring.model == ScoringModel.checkersRemaining) {
    assert(cubeValue == 1, 'checkers-remaining games have no cube');
    return GameResult(
      winner: winner,
      kind: ResultKind.checkersRemaining,
      points: p.checkersOnBoard(loser),
      cubeValue: cubeValue,
    );
  }
  final (:kind, :points) = _margin(p, scoring, loser);
  return GameResult(
    winner: winner,
    kind: kind,
    points: points * cubeValue,
    cubeValue: cubeValue,
  );
}

/// Single (1), gammon (2) or triple (`scoring.triple`) against [loser],
/// before the cube (G8, D6).
({ResultKind kind, int points}) _margin(
  BoardView p,
  Scoring scoring,
  Side loser,
) {
  if (p.borneOff(loser) > 0) return (kind: ResultKind.single, points: 1);
  final triple = scoring.triple;
  if (triple != null && _tripleHolds(p, loser, scoring.tripleCondition!)) {
    return (kind: ResultKind.triple, points: triple);
  }
  return (kind: ResultKind.gammon, points: 2);
}

/// D6: the loser has a checker in the winner's home (its own pips
/// 19..24), or, for [TripleCondition.barOrWinnerHome], on its bar.
bool _tripleHolds(BoardView p, Side loser, TripleCondition c) {
  if (c == TripleCondition.barOrWinnerHome && p.onBar(loser) > 0) {
    return true;
  }
  for (var pip = 19; pip <= 24; pip++) {
    if (p.count(loser, pip) > 0) return true;
  }
  return false;
}
