/// Position and play values for the search: 0-ply, 1-ply and 2-ply
/// (design spec SP2 §5).
library;

import 'package:tavli_core/tavli_core.dart';

import '../eval/evaluator.dart';
import 'budget.dart';

/// One roll: its dice as `generatePlays` takes them, and its weight in 36.
typedef Roll = ({List<int> dice, int weight});

/// The 21 distinct rolls: doubles as four dice (weight 1), the rest as
/// `[a, b]` (weight 2).
final List<Roll> allRolls = List.unmodifiable([
  for (var a = 1; a <= 6; a++)
    for (var b = a; b <= 6; b++)
      (
        dice: List<int>.unmodifiable(a == b ? [a, a, a, a] : [a, b]),
        weight: a == b ? 1 : 2,
      ),
]);

/// The value of a finished game for [me], on the equity scale of
/// [EvalResult.equity]: the result's points (single 1, gammon 2, triple
/// 3, mother `pin.motherPoints`), negated for a loss, 0 for a draw. Under
/// checkers-remaining scoring a win is `1 + points / 15` (1..2), above
/// every unfinished position there (whose value is `2·winProb − 1`).
double terminalValue(GameResult r, Side me) {
  final w = r.winner;
  if (w == null) return 0;
  final v = r.kind == ResultKind.checkersRemaining
      ? 1 + r.points / 15
      : r.points.toDouble();
  return w == me ? v : -v;
}

/// Scores positions for the search, counting evaluations and polling the
/// [clock] between rolls and between reply evaluations.
///
/// Every value is for the side that has just moved, with the other side
/// to roll. Evaluators are on-roll neutral and antisymmetric (plan Task
/// 3), so the opponent's value of a position is minus mine.
final class PlyScorer {
  PlyScorer(this.evaluator, this.rules, this.clock)
      : _start = Position.forRules(rules),
        _cascades = rules.doubles == DoublesMode.cascade,
        _remaining = rules.scoring.model == ScoringModel.checkersRemaining;

  final Evaluator evaluator;
  final VariantRules rules;
  final SearchClock clock;

  /// Calls to [evaluator] so far.
  int evaluated = 0;

  final Position _start;
  final bool _cascades, _remaining;
  static final _plain = TurnContext(), _first = TurnContext(firstTurn: true);

  /// The 0-ply value of [p] for [mover], who has just moved: the game's
  /// [terminalValue] if [mover]'s last step ended it, else the evaluator's
  /// equity (`2·winProb − 1` under checkers-remaining scoring, where
  /// gammons mean nothing).
  double value(BoardView p, Side mover) {
    final end = checkGameEnd(p, rules, justMoved: mover, cubeValue: 1);
    if (end != null) return terminalValue(end, mover);
    evaluated++;
    final e = evaluator.evaluate(p, mover, rules);
    return _remaining ? 2 * e.winProb - 1 : e.equity;
  }

  /// The turn context of [s] about to roll in [p]. Only the head rule
  /// reads it (`firstTurn`), and a side still on its start layout has not
  /// moved yet.
  TurnContext contextFor(BoardView p, Side s) =>
      rules.head != null && _atStart(p, s) ? _first : _plain;

  bool _atStart(BoardView p, Side s) {
    if (p.onBar(s) > 0 || p.borneOff(s) > 0) return false;
    for (var pip = 1; pip <= 24; pip++) {
      if (p.count(s, pip) != _start.count(s, pip)) return false;
    }
    return true;
  }

  /// The finals [s] may reach from [p] with [dice], [p] itself if [s]
  /// cannot move.
  ///
  /// A double in a cascading variant (Gul Bara) is played as its cascade
  /// by [CascadeWalker.greedyCompletion] on [value]: one reply, not every
  /// final. Which doubles cascade depends on the game's roll count, which
  /// the search does not know, so every double is treated as cascading
  /// there (plan Task 5's allowed simplification). With [cascades] false
  /// a double is played as four dice instead: the 2-ply leaves do that,
  /// because one failing cascade can take most of a second to generate
  /// (it cannot be interrupted) and the leaves would run hundreds.
  Iterable<Position> replies(Position p, Side s, List<int> dice,
      {bool cascades = true}) {
    final ctx = contextFor(p, s);
    if (cascades && _cascades && dice.length == 4) {
      final tree = generateCascade(p, s, cascadeQueue(dice[0]), rules, ctx);
      if (!tree.hasPlay) return [p];
      return [
        CascadeWalker(tree).greedyCompletion((b) => value(b, s)).finalPosition
      ];
    }
    final tree = generatePlays(p, s, dice, rules, ctx);
    return tree.hasPlay ? tree.finals : [p];
  }

  /// The best 0-ply value [s] reaches from [p] with [dice]; null once the
  /// clock expires.
  double? bestReply(Position p, Side s, List<int> dice,
      {bool cascades = true}) {
    var best = double.negativeInfinity;
    for (final q in replies(p, s, dice, cascades: cascades)) {
      if (clock.expired) return null;
      final v = value(q, s);
      if (v > best) best = v;
    }
    return best;
  }

  /// [me]'s 1-ply value of [f], a position [me] just reached: over the
  /// opponent's 21 rolls, minus the opponent's best 0-ply reply, weighted
  /// by roll. A finished game scores its [terminalValue]. Null once the
  /// clock expires. [cascades] as in [replies].
  double? onePly(Position f, Side me, {bool cascades = true}) {
    final end = checkGameEnd(f, rules, justMoved: me, cubeValue: 1);
    if (end != null) return terminalValue(end, me);
    final opp = me.opponent;
    var sum = 0.0;
    for (final r in allRolls) {
      if (clock.expired) return null;
      final b = bestReply(f, opp, r.dice, cascades: cascades);
      if (b == null) return null;
      sum -= r.weight * b;
    }
    return sum / 36;
  }

  /// [me]'s 2-ply value of [f] (Expert): over the opponent's 21 rolls,
  /// the opponent takes the best by its own 1-ply value among its top
  /// [replyWidth] replies by 0-ply (their 1-ply plays my doubles as four
  /// dice, see [replies]). Null once the clock expires.
  double? twoPly(Position f, Side me, {int replyWidth = 3}) {
    final end = checkGameEnd(f, rules, justMoved: me, cubeValue: 1);
    if (end != null) return terminalValue(end, me);
    final opp = me.opponent;
    var sum = 0.0;
    for (final r in allRolls) {
      if (clock.expired) return null;
      final ranked = <(Position, double)>[];
      for (final q in replies(f, opp, r.dice)) {
        if (clock.expired) return null;
        ranked.add((q, value(q, opp)));
      }
      ranked.sort((a, b) => b.$2.compareTo(a.$2));
      var best = double.negativeInfinity;
      for (final (q, _) in ranked.take(replyWidth)) {
        final v = onePly(q, opp, cascades: false);
        if (v == null) return null;
        if (v > best) best = v;
      }
      sum -= r.weight * best;
    }
    return sum / 36;
  }
}
