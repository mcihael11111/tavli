/// The no-contact race evaluator (design spec SP2 §4).
library;

import 'dart:math' as math;

import 'package:tavli_core/tavli_core.dart';

import 'evaluator.dart';

/// Average pips per roll, for converting pips to rolls.
const double pipsPerRoll = 8.1;

/// Effective pip count of [s]: pips plus wastage, where wastage is 1 per
/// checker beyond 3 on each of the own points 1..3, plus 0.5 per empty
/// own point among 4..6 (the home-board gaps that waste pips in the
/// bear-off; Keith-style). 0 once every checker is off.
double effectivePips(BoardView p, Side s) {
  if (p.checkersOnBoard(s) == 0) return 0;
  var waste = 0.0;
  for (var pip = 1; pip <= 3; pip++) {
    final c = p.count(s, pip);
    if (c > 3) waste += c - 3;
  }
  for (var pip = 4; pip <= 6; pip++) {
    if (p.count(s, pip) == 0) waste += 0.5;
  }
  return p.pipCount(s) + waste;
}

/// Pips [s] needs to bear off its first checker: every checker outside
/// the home board brought to the 6-point, plus the lowest home checker's
/// pip (6 if none is home yet).
int firstOffPips(BoardView p, Side s) {
  var bearIn = 0, lowest = 6;
  for (var pip = 25; pip >= 1; pip--) {
    final c = p.count(s, pip);
    if (c == 0) continue;
    if (pip > 6) {
      bearIn += c * (pip - 6);
    } else {
      lowest = pip;
    }
  }
  return bearIn + lowest;
}

/// A pure race: the effective pip lead through a logistic.
///
/// On-roll neutral and exactly antisymmetric (plan Task 3): the lead is
/// `(epcOpp − epcMe) / ((epcMe + epcOpp) / 2)` and `winProb =
/// logistic(11 · lead)`. Callers needing the on-roll effect (the cube
/// policy) add it.
///
/// Gammons: I win a gammon only if the opponent has nothing off and needs
/// more rolls to get its first checker off ([firstOffPips] / 8.1) than I
/// need to finish (effective pips / 8.1); then `logistic(4·margin − 1)`
/// of that margin in rolls, as a share of my wins.
final class RaceEvaluator implements Evaluator {
  const RaceEvaluator();

  @override
  EvalResult evaluate(BoardView p, Side me, VariantRules r) {
    final opp = me.opponent;
    final epcMe = effectivePips(p, me), epcOpp = effectivePips(p, opp);
    final mean = math.max((epcMe + epcOpp) / 2, 1.0);
    final s = 11 * (epcOpp - epcMe) / mean;
    final win = logistic(s), loss = logistic(-s);
    return EvalResult(
      win,
      win * _gammonShare(p, me, epcMe),
      loss * _gammonShare(p, opp, epcOpp),
    );
  }

  /// The chance that a win by [w] (effective pips [epcW]) is a gammon.
  static double _gammonShare(BoardView p, Side w, double epcW) {
    final l = w.opponent;
    if (p.borneOff(l) > 0) return 0;
    final margin = (firstOffPips(p, l) - epcW) / pipsPerRoll;
    return margin > 0 ? logistic(4 * margin - 1) : 0;
  }
}
