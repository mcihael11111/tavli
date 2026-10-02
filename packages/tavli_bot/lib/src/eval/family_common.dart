/// Helpers shared by the family evaluators (internal).
library;

import 'dart:math' as math;

import 'package:tavli_core/tavli_core.dart';

import 'evaluator.dart';

/// The result for score [s] (log-odds of a win for `me`), with [gMe] /
/// [gOpp] the chance that a win by me / by the opponent is a gammon.
///
/// Exactly antisymmetric when the opponent's view passes `-s` and the two
/// gammon shares swapped: its win is `logistic(-s)`, the same value as my
/// loss here.
EvalResult resultOf(double s, double gMe, double gOpp) {
  final win = logistic(s), loss = logistic(-s);
  return EvalResult(win, win * gMe, loss * gOpp);
}

/// `(pipOpp − pipMe) / mean pips`: the pip lead relative to the race
/// length; exactly negated for the other side.
double relativeLead(int pipMe, int pipOpp) =>
    (pipOpp - pipMe) / math.max((pipMe + pipOpp) / 2, 1.0);

/// Checkers of [s] on own pips [lo]..[hi].
int checkersOn(BoardView p, Side s, int lo, int hi) {
  var n = 0;
  for (var pip = lo; pip <= hi; pip++) {
    n += p.count(s, pip);
  }
  return n;
}

/// Movable checkers of [s] (pins and the bar included as sources) at own
/// pips [from]..[from]+5 behind its opponent's own pip [target]: the shots
/// [s] has at that pip. 25 = the bar.
int shotsAt(BoardView p, Side s, int target, int from) {
  var n = 0;
  for (var q = target + from; q <= target + from + 5 && q <= 25; q++) {
    if (q == 25) {
      if (p.onBar(s) > 0) n++;
    } else if (p.count(s, q) > 0 && !p.isPinned(s, q)) {
      n++;
    }
  }
  return n;
}
