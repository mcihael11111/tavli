/// The pinning-family evaluator: Plakoto, Tapa, Mahbusa (design spec SP2
/// §4).
library;

import 'package:tavli_core/tavli_core.dart';

import 'evaluator.dart';
import 'family_common.dart';
import 'features.dart';

/// Pinning games: pins held (by how far the pinned checker is from its
/// home), the mother (own pip 24: a pinned mother ends a Plakoto game, so
/// leaving it alone within reach is costly), made points, blots and pip
/// lead. Ideas from the legacy `PlakotoEvaluator`, re-derived over
/// [Features].
///
/// The score is `side(me) − side(opp) + lead`, each side valued by the
/// same function: exactly antisymmetric and on-roll neutral.
final class PinningEvaluator implements Evaluator {
  const PinningEvaluator();

  @override
  EvalResult evaluate(BoardView p, Side me, VariantRules r) {
    final f = extractFeatures(p, me, r);
    final opp = me.opponent;
    final mother = r.pin?.motherRule ?? false;
    final lead = relativeLead(f.pipMe, f.pipOpp);
    final s = _side(p, me, mother, f.homePointsMe, f.madePointsMe, f.primeLenMe,
            f.blotsMe, f.directShotsMe, f.indirectShotsMe) -
        _side(p, opp, mother, f.homePointsOpp, f.madePointsOpp, f.primeLenOpp,
            f.blotsOpp, f.directShotsOpp, f.indirectShotsOpp) +
        5 * lead;
    return resultOf(
      s,
      _gammonShare(
          lead, f.offOpp, f.pinnedOpp, mother && f.motherPinnedOpp, f.offMe),
      _gammonShare(
          -lead, f.offMe, f.pinnedMe, mother && f.motherPinnedMe, f.offOpp),
    );
  }

  /// One side [s]'s value: its structure, the pins it holds and its
  /// mother's safety.
  static double _side(BoardView p, Side s, bool motherRule, int home, int made,
      int prime, int blots, int direct, int indirect) {
    final them = s.opponent;
    // Pins held: each opposing pinned checker, worth more the farther it
    // is from its home (its own pip q); the opposing mother most of all.
    var pins = 0.0;
    final mask = p.pinnedMask(them);
    for (var q = 1; q <= 24; q++) {
      if ((mask >> q) & 1 == 1) pins += 0.2 + 0.025 * q;
    }
    if (motherRule && p.isPinned(them, 24)) pins += 1.5;

    // My mother alone on my 24, unpinned, within the opponent's reach.
    var mother = 0.0;
    if (p.count(s, 24) == 1 && !p.isPinned(s, 24)) {
      final q = p.geometry.toOpponent(24);
      final weight = motherRule ? 1.0 : 0.3;
      if (shotsAt(p, them, q, 1) > 0) {
        mother = 0.6 * weight;
      } else if (shotsAt(p, them, q, 7) > 0) {
        mother = 0.25 * weight;
      }
    }

    return 0.1 * home +
        0.06 * made +
        0.03 * prime * prime -
        0.02 * blots -
        0.03 * direct -
        0.01 * indirect +
        pins -
        mother;
  }

  /// The chance a win is a gammon: none once the loser has borne one off;
  /// more with the loser's checkers pinned (its mother above all) and a
  /// pip lead.
  static double _gammonShare(double lead, int loserOff, int loserPinned,
      bool loserMotherPinned, int winnerOff) {
    if (loserOff > 0) return 0;
    return logistic(-2.5 +
        0.5 * loserPinned +
        (loserMotherPinned ? 2 : 0) +
        0.15 * winnerOff +
        2 * lead);
  }
}
