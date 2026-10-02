/// Doubling-cube decisions (design spec SP2 §6).
library;

import 'dart:math';

import 'package:tavli_core/tavli_core.dart';

import '../eval/eval_dispatch.dart';
import '../eval/evaluator.dart';
import '../eval/features.dart';
import '../eval/race_eval.dart';
import '../level/bot_level.dart';

/// Offer at this win chance or more (market-window style)...
const double offerThreshold = 0.68;

/// ...unless too good: this win chance with [tooGoodGammon] gammons or
/// more is worth playing on for the gammon.
const double tooGoodWin = 0.85, tooGoodGammon = 0.35;

/// The taker needs this much (gammon-adjusted, see [shouldTake]).
const double takeThreshold = 0.25;

/// Easy takes with this win chance or more, ignoring gammons.
const double easyTakeThreshold = 0.20;

/// The race lead the side on roll gains from rolling first: added to its
/// lead (and taken from the other side's) before the race logistic.
const double raceOnRollLead = 0.04;

/// Whether [side], on roll and before rolling, doubles.
///
/// Never when the variant or game has no cube, a double is pending,
/// [side] does not hold the cube (it is centred or [side]'s), the cube
/// is at 64, in the Crawford game ([crawfordGame], which the core also
/// enforces), or at [BotLevel.easy]. Otherwise offers when
/// `winProb ≥ offerThreshold` and the position is not too good
/// (`winProb ≥ tooGoodWin` with `gammonProb ≥ tooGoodGammon`), on
/// [cubeView].
///
/// [rng] and [budget] are accepted for the uniform request shape; the
/// decision is deterministic and 0-ply, so it needs no budget.
bool shouldOffer({
  required Position position,
  required Side side,
  required VariantRules rules,
  required CubeState cube,
  required BotLevel level,
  required Random rng,
  Duration? budget,
  Evaluator? evaluator,
  bool crawfordGame = false,
}) {
  if (crawfordGame) return false;
  if (!rules.cube.available || !cube.enabled || cube.offeredBy != null) {
    return false;
  }
  if (cube.owner != null && cube.owner != side) return false;
  if (cube.value >= 64 || level == BotLevel.easy) return false;
  final e = cubeView(position, side, rules, evaluator: evaluator);
  final tooGood = e.winProb >= tooGoodWin && e.gammonProb >= tooGoodGammon;
  return e.winProb >= offerThreshold && !tooGood;
}

/// Whether [side] takes the double its opponent (on roll) offers.
///
/// From [side]'s view of [cubeView] (win `w`, gammons won `g` and lost
/// `lg`): takes iff `w + (g − lg) / 2 ≥ takeThreshold`. That is the
/// cubeless break-even of taking (doubled equity `2·E`) against passing
/// (−1): `E = 2w − 1 + g − lg ≥ −1/2`, so gammon risk raises the bar (the
/// design's "winProb + 0.5·lossGammonProb_adj ≥ 0.25", with the gammon
/// term signed). Cube ownership is not valued. Easy takes iff
/// `w ≥ easyTakeThreshold`. [rng] and [budget] as in [shouldOffer].
bool shouldTake({
  required Position position,
  required Side side,
  required VariantRules rules,
  required CubeState cube,
  required BotLevel level,
  required Random rng,
  Duration? budget,
  Evaluator? evaluator,
}) {
  final o = cubeView(position, side.opponent, rules, evaluator: evaluator);
  final w = 1 - o.winProb, g = o.lossGammonProb, lg = o.gammonProb;
  if (level == BotLevel.easy) return w >= easyTakeThreshold;
  return w + (g - lg) / 2 >= takeThreshold;
}

/// The chances of [onRoll], about to roll in [position], for a cube
/// decision: the 0-ply evaluation from [onRoll]'s view, shifted for the
/// roll ([withRaceRoll]). Every level uses it.
///
/// Hard and Expert used to average over [onRoll]'s 21 rolls (design §6),
/// but the max over noisy evaluations after each roll (winner's curse)
/// read 0.07-0.11 winProb high. They may get 1-ply back once the
/// evaluator is calibrated (plan Task 10).
EvalResult cubeView(Position position, Side onRoll, VariantRules rules,
    {Evaluator? evaluator}) {
  final e = evaluator ?? evaluatorFor(rules);
  return withRaceRoll(e.evaluate(position, onRoll, rules), position, rules,
      onRoll: true);
}

/// [e], a side's evaluation of [p], with the on-roll effect in a race
/// (the evaluators are on-roll neutral, plan Task 3): the side's race
/// lead moves by `+raceOnRollLead` if it is [onRoll], else by
/// `−raceOnRollLead`, i.e. its win log-odds by `± raceSlope ·
/// raceOnRollLead`. Its gammon and loss-gammon chances scale with its
/// win and loss chances, keeping the share of wins (losses) that are
/// gammons. Unchanged outside a race ([isRace]) or at a certain result.
EvalResult withRaceRoll(EvalResult e, BoardView p, VariantRules rules,
    {required bool onRoll}) {
  final w = e.winProb;
  if (!isRace(p, rules) || w <= 0 || w >= 1) return e;
  final shift = (onRoll ? 1 : -1) * raceSlope * raceOnRollLead;
  final w2 = logistic(log(w / (1 - w)) + shift);
  return EvalResult(
      w2, e.gammonProb * w2 / w, e.lossGammonProb * (1 - w2) / (1 - w));
}
