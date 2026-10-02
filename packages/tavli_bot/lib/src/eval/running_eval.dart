/// The running-family evaluator: Fevga, Moultezim, Gul Bara, Long Nard,
/// Tawla 31 (design spec SP2 §4).
library;

import 'package:tavli_core/tavli_core.dart';

import 'evaluator.dart';
import 'family_common.dart';
import 'features.dart';

/// Running (block) games: the blockade in front of the opponent, the
/// runner's release (sole-runner variants), the head (own pip 24) and pip
/// lead. Ideas from the legacy `FevgaEvaluator`, re-derived over player-
/// relative pips.
///
/// The score is `side(me) − side(opp) + lead`, each side valued by the
/// same function: exactly antisymmetric and on-roll neutral.
final class RunningEvaluator implements Evaluator {
  const RunningEvaluator();

  @override
  EvalResult evaluate(BoardView p, Side me, VariantRules r) {
    final f = extractFeatures(p, me, r);
    final opp = me.opponent;
    final lead = relativeLead(f.pipMe, f.pipOpp);
    final s = _side(p, me, r) - _side(p, opp, r) + 7 * lead;
    return resultOf(
      s,
      _gammonShare(lead, f.offOpp, f.headCountOpp, f.offMe),
      _gammonShare(-lead, f.offMe, f.headCountMe, f.offOpp),
    );
  }

  /// One side [s]'s value.
  static double _side(BoardView p, Side s, VariantRules r) {
    final block = blockade(p, s);
    final cap = _forbidsSix(r.primes) ? 5 : 24;
    final b = block > cap ? cap : block;
    final head = p.count(s, 24);
    final headWeight = r.head != null ? 0.05 : 0.03;
    final adv = r.advancement;
    // Sole runner: the other checkers may leave the head only once a
    // runner has reached the release pip.
    var released = 0.0;
    if (adv != null && head < 15 && _lowest(p, s) <= adv.releasePip) {
      released = 0.2;
    }
    return 0.05 * b * b - headWeight * head + released;
  }

  /// The longest run of consecutive points [s] holds in front of the
  /// opponent's rearmost checker, counted along the opponent's path.
  static int blockade(BoardView p, Side s) {
    final them = s.opponent;
    var rear = 0;
    for (var q = 25; q >= 1; q--) {
      if (p.count(them, q) > 0) {
        rear = q;
        break;
      }
    }
    final g = p.geometry;
    var run = 0, best = 0;
    for (var t = 1; t < rear && t <= 24; t++) {
      if (p.count(s, g.toOpponent(t)) > 0) {
        if (++run > best) best = run;
      } else {
        run = 0;
      }
    }
    return best;
  }

  /// Whether the variant forbids some six-point prime (D12, D14, D19):
  /// such structures score nothing beyond a five-point one.
  static bool _forbidsSix(PrimeRules pr) =>
      pr.noSixOwnStartQuarter ||
      pr.noSixBeforeOccupiedOppHead ||
      pr.noPrimeTrappingAll ||
      pr.maxPointsInOppStartQuarter != null;

  /// The lowest own pip (1..24) holding a checker of [s]; 25 if none.
  static int _lowest(BoardView p, Side s) {
    for (var pip = 1; pip <= 24; pip++) {
      if (p.count(s, pip) > 0) return pip;
    }
    return 25;
  }

  /// The chance a win is a gammon: none once the loser has borne one off;
  /// more with the loser still on its head and a pip lead.
  static double _gammonShare(
      double lead, int loserOff, int loserHead, int winnerOff) {
    if (loserOff > 0) return 0;
    return logistic(-2.5 + 3 * lead + 0.15 * winnerOff + 0.08 * loserHead);
  }
}
