/// The hitting-family evaluator: Portes, Tavla, Short Nard, Shesh Besh
/// (design spec SP2 §4).
library;

import 'package:tavli_core/tavli_core.dart';

import 'evaluator.dart';
import 'family_common.dart';
import 'features.dart';

/// Hitting games: pip lead, home points, made points, primes, anchors,
/// blots weighted by the shots at them, and the bar. Ideas from the legacy
/// `BoardEvaluator`, re-derived over [Features].
///
/// The score is `side(me) − side(opp) + lead`, each side valued by the
/// same function, so the evaluator is exactly antisymmetric and on-roll
/// neutral (plan Task 3).
final class HittingEvaluator implements Evaluator {
  const HittingEvaluator();

  @override
  EvalResult evaluate(BoardView p, Side me, VariantRules r) {
    final f = extractFeatures(p, me, r);
    final opp = me.opponent;
    final lead = relativeLead(f.pipMe, f.pipOpp);
    final s = _side(
            f.homePointsMe,
            f.madePointsMe,
            f.primeLenMe,
            f.anchorsMe,
            f.barMe,
            f.offMe,
            f.blotsMe,
            f.directShotsMe,
            f.indirectShotsMe,
            f.homePointsOpp) -
        _side(
            f.homePointsOpp,
            f.madePointsOpp,
            f.primeLenOpp,
            f.anchorsOpp,
            f.barOpp,
            f.offOpp,
            f.blotsOpp,
            f.directShotsOpp,
            f.indirectShotsOpp,
            f.homePointsMe) +
        6 * lead;
    final backOpp = checkersOn(p, opp, 19, 25);
    final backMe = checkersOn(p, me, 19, 25);
    return resultOf(
      s,
      _gammonShare(lead, f.offOpp, backOpp, f.homePointsMe, f.offMe),
      _gammonShare(-lead, f.offMe, backMe, f.homePointsOpp, f.offOpp),
    );
  }

  /// One side's structure, against [theirHome] home points.
  static double _side(int home, int made, int prime, int anchors, int bar,
      int off, int blots, int direct, int indirect, int theirHome) {
    final risk = (0.02 * blots + 0.04 * direct + 0.015 * indirect) *
        (1 + 0.15 * theirHome);
    final cappedAnchors = anchors > 2 ? 2 : anchors;
    return 0.15 * home +
        0.05 * made +
        0.04 * prime * prime +
        0.1 * cappedAnchors +
        0.03 * off -
        bar * (0.3 + 0.1 * theirHome) -
        risk;
  }

  /// The chance a win is a gammon: none once the loser has borne one off;
  /// more with the loser's checkers back (own pips 19..25) or on the bar,
  /// a strong winner's board and a pip lead.
  static double _gammonShare(
      double lead, int loserOff, int loserBack, int winnerHome, int winnerOff) {
    if (loserOff > 0) return 0;
    return logistic(-2.2 +
        0.25 * loserBack +
        0.15 * winnerHome +
        0.15 * winnerOff +
        3 * lead);
  }
}
