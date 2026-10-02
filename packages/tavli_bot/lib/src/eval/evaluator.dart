/// The evaluator interface (design spec SP2 §4).
library;

import 'dart:math' as math;

import 'package:tavli_core/tavli_core.dart';

/// A position's value for one side: probabilities in 0..1.
final class EvalResult {
  /// The probability that `me` wins.
  final double winProb;

  /// The probability that `me` wins a gammon or more (≤ [winProb]).
  final double gammonProb;

  /// The probability that `me` loses a gammon or more (≤ 1 − [winProb]).
  final double lossGammonProb;

  const EvalResult(this.winProb, this.gammonProb, this.lossGammonProb);

  /// Cubeless equity for `me`: positive is good.
  double get equity => (2 * winProb - 1) + (gammonProb - lossGammonProb);

  @override
  String toString() => 'EvalResult(win ${winProb.toStringAsFixed(3)}, '
      'g ${gammonProb.toStringAsFixed(3)}, '
      'lg ${lossGammonProb.toStringAsFixed(3)}, '
      'eq ${equity.toStringAsFixed(3)})';
}

/// Scores positions for one side.
abstract interface class Evaluator {
  /// The value of [p] for [me] under [r].
  EvalResult evaluate(BoardView p, Side me, VariantRules r);
}

/// `1 / (1 + e^-x)`.
double logistic(double x) => 1 / (1 + math.exp(-x));
