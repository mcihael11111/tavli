/// The running-family evaluator: Fevga, Moultezim, Gul Bara, Long Nard,
/// Tawla 31 (design spec SP2 §4).
library;

import 'package:tavli_core/tavli_core.dart';

import 'evaluator.dart';
import 'family_common.dart';
import 'features.dart';

/// Running (block) games: the blockade in front of the opponent, the
/// runner's release (sole-runner variants), the head (own pip 24), the
/// points held, checkers home, stacking and pip lead. Ideas from the
/// legacy `FevgaEvaluator`, re-derived over player-relative pips.
///
/// Every play of a turn moves the same pips, so the pip lead does not
/// rank plays; the structure terms do. Points held, checkers home and
/// the stacking penalty were added at the Task 10 tuning (SP2 report):
/// without them noiseless 0-ply lost to the noisy Easy in Fevga.
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
    // Not capped for prime-restricted variants: the finals scored are
    // legal, so a six-prime here is one the rules allow.
    final b = blockade(p, s);
    final head = p.count(s, 24);
    final headWeight = r.head != null ? 0.05 : 0.03;
    final adv = r.advancement;
    // Sole runner: the other checkers may leave the head only once a
    // runner has reached the release pip.
    var released = 0.0;
    if (adv != null && head < 15 && _lowest(p, s) <= adv.releasePip) {
      released = 0.2;
    }
    // Points held off the head (a single checker blocks), checkers home
    // or borne off, and checkers stacked beyond 3 on a point.
    var points = 0, home = p.borneOff(s), stacked = 0;
    for (var pip = 1; pip <= 23; pip++) {
      final c = p.count(s, pip);
      if (c == 0) continue;
      points++;
      if (pip <= 6) home += c;
      if (c > 3) stacked += c - 3;
    }
    return 0.05 * b * b -
        headWeight * head +
        released +
        0.05 * points +
        0.1 * home -
        0.05 * stacked;
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
