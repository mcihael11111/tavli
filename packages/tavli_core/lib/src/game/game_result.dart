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
/// `endsGame(p, rules, justMoved)` is true.
///
/// 1. Bear-off win: [justMoved] has borne off all 15.
///    - Checkers-remaining scoring (D21): the loser's checkers on board.
///    - Otherwise gammon (2) if the loser has borne off none, else single
///      (1); upgraded to `scoring.triple` when set, the loser has borne
///      off none and the triple condition holds (bar or the winner's home
///      = the loser's pips 19..24). Times [cubeValue].
/// 2. Mother rule (stateless): both mothers (pip 24) pinned is a draw at
///    `pin.bothPinnedPoints` each; one side's mother pinned while the
///    pinner has left its own start is a `mother` win at `pin.motherPoints`.
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
  if (pin == null || !pin.motherRule) return null;
  if (p.isPinned(Side.one, 24) && p.isPinned(Side.two, 24)) {
    return GameResult(
      winner: null,
      kind: ResultKind.draw,
      points: pin.bothPinnedPoints,
      cubeValue: cubeValue,
    );
  }
  for (final mother in Side.values) {
    final pinner = mother.opponent;
    if (p.isPinned(mother, 24) && p.count(pinner, 24) == 0) {
      return GameResult(
        winner: pinner,
        kind: ResultKind.mother,
        points: pin.motherPoints,
        cubeValue: cubeValue,
      );
    }
  }
  return null;
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
    return GameResult(
      winner: winner,
      kind: ResultKind.checkersRemaining,
      points: p.checkersOnBoard(loser),
      cubeValue: cubeValue,
    );
  }
  var kind = ResultKind.single;
  var points = 1;
  if (p.borneOff(loser) == 0) {
    kind = ResultKind.gammon;
    points = 2;
    final triple = scoring.triple;
    if (triple != null && _tripleHolds(p, loser, scoring.tripleCondition!)) {
      kind = ResultKind.triple;
      points = triple;
    }
  }
  return GameResult(
    winner: winner,
    kind: kind,
    points: points * cubeValue,
    cubeValue: cubeValue,
  );
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
