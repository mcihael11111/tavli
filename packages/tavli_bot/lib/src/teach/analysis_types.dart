/// Teaching analysis results (design spec SP2 §7). `analyzeTurn` comes in
/// plan Task 7; the types live here so the worker protocol can carry them.
library;

import 'package:tavli_core/tavli_core.dart';

import '../util/collection_eq.dart';

/// How good a next step is, by the equity gap between the best play it
/// leads to and the best play overall: best ≤ 0.01, good ≤ 0.03,
/// acceptable ≤ 0.08, poor > 0.08.
enum StepQuality { best, good, acceptable, poor }

/// How good each next step of a turn is, and the chosen play if complete.
final class TurnAnalysis {
  /// The quality of each legal next step after the steps taken so far.
  final Map<Step, StepQuality> nextStepQuality;

  /// The best play value reachable through each next step.
  final Map<Step, double> nextStepEquity;

  /// The best play value of the turn.
  final double bestEquity;

  /// When the steps taken form a complete play: best − chosen (≥ 0).
  final double? playEquityLoss;

  /// Copies both maps (unmodifiable, insertion order kept).
  TurnAnalysis({
    required Map<Step, StepQuality> nextStepQuality,
    required Map<Step, double> nextStepEquity,
    required this.bestEquity,
    required this.playEquityLoss,
  })  : nextStepQuality = Map.unmodifiable(nextStepQuality),
        nextStepEquity = Map.unmodifiable(nextStepEquity);

  @override
  bool operator ==(Object other) =>
      other is TurnAnalysis &&
      other.bestEquity == bestEquity &&
      other.playEquityLoss == playEquityLoss &&
      mapEq(other.nextStepQuality, nextStepQuality) &&
      mapEq(other.nextStepEquity, nextStepEquity);

  @override
  int get hashCode => Object.hash(bestEquity, playEquityLoss,
      mapHash(nextStepQuality), mapHash(nextStepEquity));

  @override
  String toString() => 'TurnAnalysis(best: $bestEquity, loss: $playEquityLoss, '
      'steps: $nextStepQuality)';
}
