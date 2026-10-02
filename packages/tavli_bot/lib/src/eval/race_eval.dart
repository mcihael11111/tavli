/// The no-contact race evaluator (design spec SP2 §4).
library;

import 'dart:math' as math;

import 'package:tavli_core/tavli_core.dart';

import 'evaluator.dart';

/// Average pips per roll, for converting pips to rolls.
const double pipsPerRoll = 8.1;

/// The race's logistic slope: `winProb = logistic(raceSlope · lead)`.
const double raceSlope = 11;

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

/// Checkers of [s] outside its home board (own pips 7..25).
int outsideHome(BoardView p, Side s) {
  var n = 0;
  for (var pip = 7; pip <= 25; pip++) {
    n += p.count(s, pip);
  }
  return n;
}

/// Rolls [s] needs before its first checker can come off: the larger of
/// its pips to the first bear-off ([firstOffPips] / 8.1) and its
/// crossovers (checkers to bring home, about 2.3 a roll).
double rollsToFirstOff(BoardView p, Side s) {
  final byPips = firstOffPips(p, s) / pipsPerRoll;
  final byCrossovers = outsideHome(p, s) / 2.3;
  return byPips > byCrossovers ? byPips : byCrossovers;
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
/// logistic(raceSlope · lead)`. Callers needing the on-roll effect (the cube
/// policy) add it.
///
/// Gammons: none once the loser has a checker off. Otherwise the share of
/// my wins that are gammons is `logistic(3·m − 0.75)` of the margin m =
/// the loser's [rollsToFirstOff] − my rolls to finish (effective pips /
/// 8.1): smooth and monotone, centred a quarter-roll in my favour. The
/// slope is 3, not 4, so one pip (1/8.1 roll) moves the share by at most
/// 3/4 × 1/8.1 ≈ 0.09.
///
/// Gammons mean nothing under `ScoringModel.checkersRemaining` (Tawla 31);
/// callers scoring such variants ignore [EvalResult.gammonProb] and
/// [EvalResult.lossGammonProb].
final class RaceEvaluator implements Evaluator {
  const RaceEvaluator();

  @override
  EvalResult evaluate(BoardView p, Side me, VariantRules r) {
    final opp = me.opponent;
    final epcMe = effectivePips(p, me), epcOpp = effectivePips(p, opp);
    final mean = math.max((epcMe + epcOpp) / 2, 1.0);
    final s = raceSlope * (epcOpp - epcMe) / mean;
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
    final margin = rollsToFirstOff(p, l) - epcW / pipsPerRoll;
    return logistic(3 * margin - 0.75);
  }
}
