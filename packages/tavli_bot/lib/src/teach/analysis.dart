/// Teaching analysis: how good each next step and the chosen play are
/// (design spec SP2 §7).
library;

import 'dart:collection';
import 'dart:math';

import 'package:tavli_core/tavli_core.dart';

import '../eval/eval_dispatch.dart';
import '../eval/evaluator.dart';
import '../level/bot_level.dart';
import '../search/budget.dart';
import '../search/ply.dart';
import '../search/selection.dart';
import 'analysis_types.dart';

/// The quality of a step whose best play is [gap] below the best play:
/// best ≤ 0.01, good ≤ 0.03, acceptable ≤ 0.08, else poor.
StepQuality qualityOf(double gap) => gap <= 0.01
    ? StepQuality.best
    : gap <= 0.03
        ? StepQuality.good
        : gap <= 0.08
            ? StepQuality.acceptable
            : StepQuality.poor;

/// Analyses [side]'s turn with [dice] after the [steps] already taken.
///
/// - `nextStepEquity[s]`: the best value among the plays that continue
///   through `steps + [s]`;
/// - `bestEquity`: the best play value of the whole turn;
/// - `nextStepQuality[s]`: [qualityOf] `bestEquity − nextStepEquity[s]`.
///   Against the whole turn, so after a weak step no next step may be
///   `best` (a cue to undo);
/// - `playEquityLoss`: `bestEquity` minus the value of the play [steps]
///   completes, or null while it is incomplete.
///
/// Values (eager trees): every final at 0-ply; then, for a [profile]
/// with depth ≥ 1, 1-ply on the top `k` finals by 0-ply, the best final
/// (by 0-ply) through each next step and the chosen final. If that 1-ply
/// set finishes within [budget] (default: the profile's), every number
/// comes from it, else every number is 0-ply: one level, never mixed.
///
/// Cascades (lazy trees): sampled completions at 0-ply ([cascadeAnalysis]).
///
/// Throws [ArgumentError] if [steps] leave the tree.
TurnAnalysis analyzeTurn({
  required Position position,
  required Side side,
  required List<int> dice,
  required bool cascade,
  required TurnContext context,
  required VariantRules rules,
  required List<Step> steps,
  LevelProfile? profile,
  required Random rng,
  Duration? budget,
  Evaluator? evaluator,
}) {
  final prof = profile ?? LevelProfile.of(BotLevel.medium);
  final clock =
      SearchClock(budget ?? (cascade ? prof.cascadeBudget : prof.budget));
  final scorer = PlyScorer(evaluator ?? evaluatorFor(rules), rules, clock);
  final tree = cascade
      ? generateCascade(position, side, dice, rules, context)
      : generatePlays(position, side, normalDice(dice), rules, context);
  final node = tree.walk(steps);
  if (node == null) {
    throw ArgumentError.value(steps, 'steps', 'not a prefix of a legal play');
  }
  if (!tree.hasPlay) {
    // No legal play: the empty play is the turn.
    final v = scorer.value(position, side);
    return TurnAnalysis(
        nextStepQuality: const {},
        nextStepEquity: const {},
        bestEquity: v,
        playEquityLoss: 0);
  }
  if (cascade) return cascadeAnalysis(tree, node, side, prof, rng, scorer);

  final finals = tree.finals.toList();
  final zero = {for (final f in finals) f: scorer.value(f, side)};
  final next = node.nextSteps.toList();
  final reach = {for (final s in next) s: _finalsFrom(node.child(s)!)};
  final chosen = node.finalPosition;

  var value = zero;
  if (prof.depth >= 1) {
    Position bestOf(Iterable<Position> fs) =>
        fs.reduce((a, b) => zero[b]! > zero[a]! ? b : a);
    final ranked = [...finals]..sort((a, b) => zero[b]!.compareTo(zero[a]!));
    final wanted = <Position>{
      if (chosen != null) chosen,
      for (final s in next) bestOf(reach[s]!),
      ...ranked.take(max(prof.k, 1)),
    };
    final one = <Position, double>{};
    for (final f in wanted) {
      if (clock.expired) break;
      final v = scorer.onePly(f, side);
      if (v == null) break;
      one[f] = v;
    }
    if (one.length == wanted.length) value = one;
  }

  double bestIn(Iterable<Position> fs) {
    var b = double.negativeInfinity;
    for (final f in fs) {
      final v = value[f];
      if (v != null && v > b) b = v;
    }
    return b;
  }

  final best = bestIn(value.keys);
  final stepEq = {for (final s in next) s: bestIn(reach[s]!)};
  return TurnAnalysis(
    nextStepQuality: {
      for (final e in stepEq.entries) e.key: qualityOf(best - e.value),
    },
    nextStepEquity: stepEq,
    bestEquity: best,
    playEquityLoss: chosen == null ? null : max(0.0, best - value[chosen]!),
  );
}

/// [analyzeTurn] on a lazy cascade tree, whose finals are never
/// enumerated: each next step gets random completions from its node (at
/// least one, more while the clock allows, `profile.cascadeSamples` in
/// all); while the clock allows, the turn's best also takes a greedy
/// completion and samples from the root. All values 0-ply.
TurnAnalysis cascadeAnalysis(PlayTree tree, PlayNode node, Side side,
    LevelProfile profile, Random rng, PlyScorer scorer) {
  final clock = scorer.clock;
  double v(Position f) => scorer.value(f, side);
  var best = double.negativeInfinity;
  final chosen = node.finalPosition;
  final next = node.nextSteps.toList();
  final stepEq = <Step, double>{};
  final perStep = max(1, profile.cascadeSamples ~/ max(1, next.length));
  for (final s in next) {
    final child = node.child(s)!;
    var b = double.negativeInfinity;
    for (var i = 0; i < perStep; i++) {
      if (i > 0 && clock.expired) break;
      b = max(b, v(_randomFinal(child, rng)));
    }
    stepEq[s] = b;
    best = max(best, b);
  }
  final walker = CascadeWalker(tree);
  if (!clock.expired) {
    best = max(best,
        v(walker.greedyCompletion((p) => scorer.value(p, side)).finalPosition));
  }
  for (final p in walker.sampleCompletions(profile.cascadeSamples, rng,
      stop: () => clock.expired)) {
    best = max(best, v(p.finalPosition));
  }
  final chosenValue = chosen == null ? null : v(chosen);
  if (chosenValue != null) best = max(best, chosenValue);
  return TurnAnalysis(
    nextStepQuality: {
      for (final e in stepEq.entries) e.key: qualityOf(best - e.value),
    },
    nextStepEquity: stepEq,
    bestEquity: best,
    playEquityLoss: chosenValue == null ? null : best - chosenValue,
  );
}

/// The finals of the plays through [n] (identity DFS over a DAG).
Set<Position> _finalsFrom(PlayNode n) {
  final out = <Position>{};
  final seen = HashSet<PlayNode>.identity();
  void visit(PlayNode x) {
    if (!seen.add(x)) return;
    final f = x.finalPosition;
    if (f != null) {
      out.add(f);
      return;
    }
    for (final s in x.nextSteps) {
      visit(x.child(s)!);
    }
  }

  visit(n);
  return out;
}

/// The final of a uniformly random walk from [n] to a complete node.
Position _randomFinal(PlayNode n, Random rng) {
  var x = n;
  while (!x.isComplete) {
    final next = x.nextSteps;
    x = x.child(next.elementAt(rng.nextInt(next.length)))!;
  }
  return x.finalPosition!;
}
