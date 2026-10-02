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
/// - `nextStepQuality[s]`: [qualityOf] the gap to the best next step, so
///   at least one next step is always `best` (design §7);
/// - `bestEquity`: the best play value of the whole turn;
/// - `lossSoFar`: `bestEquity` minus the best value still reachable after
///   [steps] (0 at the turn start);
/// - `playEquityLoss`: `bestEquity` minus the value of the play [steps]
///   completes, or null while it is incomplete.
///
/// Values (eager trees): every final at 0-ply; then, for a [profile]
/// with depth ≥ 1, 1-ply on the top `k` finals by 0-ply, the best final
/// (by 0-ply) through each next step and the chosen final. If that 1-ply
/// set finishes within [budget] (default: the profile's), every number
/// comes from it, else every number is 0-ply: one level, never mixed.
///
/// Cascades (lazy trees): sampled and greedy completions at 0-ply
/// ([cascadeAnalysis]).
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
        lossSoFar: 0,
        playEquityLoss: 0);
  }
  if (cascade) {
    return cascadeAnalysis(
        tree, node, position, side, steps, prof, rng, scorer);
  }

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

  return _result(
    best: bestIn(value.keys),
    stepEq: {for (final s in next) s: bestIn(reach[s]!)},
    chosen: chosen == null ? null : value[chosen]!,
  );
}

/// The analysis from the turn's best, the best value through each next
/// step and, for a complete play, its value.
TurnAnalysis _result(
    {required double best,
    required Map<Step, double> stepEq,
    required double? chosen}) {
  final bestNext = stepEq.values.fold(double.negativeInfinity, max);
  final reachable = chosen ?? bestNext;
  return TurnAnalysis(
    nextStepQuality: {
      for (final e in stepEq.entries) e.key: qualityOf(bestNext - e.value),
    },
    nextStepEquity: stepEq,
    bestEquity: best,
    lossSoFar: max(0.0, best - reachable),
    playEquityLoss: chosen == null ? null : max(0.0, best - chosen),
  );
}

/// [analyzeTurn] on a lazy cascade tree, whose finals are never
/// enumerated. Each next step gets a greedy completion from its node
/// (best child by 0-ply at each node, so a good step is not labelled poor
/// by an unlucky sample) plus random completions while the clock allows
/// (`profile.cascadeSamples` in all); its value is their max. A greedy
/// completion and, while the clock allows, samples from the root also
/// count, for the turn's best and for the next step they take. All
/// values 0-ply.
TurnAnalysis cascadeAnalysis(
  PlayTree tree,
  PlayNode node,
  Position start,
  Side side,
  List<Step> steps,
  LevelProfile profile,
  Random rng,
  PlyScorer scorer,
) {
  final clock = scorer.clock;
  final rules = StepRules(scorer.rules);
  double v(BoardView p) => scorer.value(p, side);
  // The position after [steps], to replay greedy walks from.
  final here = start.toMutable();
  for (final s in steps) {
    rules.apply(here, side, s);
  }
  final at = here.freeze();

  final next = node.nextSteps.toList();
  final stepEq = <Step, double>{};
  final perStep = max(1, profile.cascadeSamples ~/ max(1, next.length));
  for (final s in next) {
    final child = node.child(s)!;
    final m = at.toMutable();
    rules.apply(m, side, s);
    var b = v(_greedyFinal(child, m, side, rules, v));
    for (var i = 1; i < perStep && !clock.expired; i++) {
      b = max(b, v(_randomFinal(child, rng)));
    }
    stepEq[s] = b;
  }
  final f = node.finalPosition;
  final chosen = f == null ? null : v(f);
  var best = max(stepEq.values.fold(double.negativeInfinity, max),
      chosen ?? double.negativeInfinity);
  // Plays from the root: each counts for the turn's best, and for the
  // next step it takes after [steps] when it continues them (so at the
  // turn start the best is always some step's).
  final walker = CascadeWalker(tree);
  for (final p in [
    walker.greedyCompletion(v),
    ...walker.sampleCompletions(profile.cascadeSamples, rng,
        stop: () => clock.expired),
  ]) {
    final x = v(p.finalPosition);
    best = max(best, x);
    if (p.steps.length > steps.length && _startsWith(p.steps, steps)) {
      final s = p.steps[steps.length];
      stepEq[s] = max(stepEq[s]!, x);
    }
  }
  return _result(best: best, stepEq: stepEq, chosen: chosen);
}

/// Whether [steps] begins with [prefix].
bool _startsWith(List<Step> steps, List<Step> prefix) {
  for (var i = 0; i < prefix.length; i++) {
    if (steps[i] != prefix[i]) return false;
  }
  return true;
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

/// The final of a greedy walk from [n], whose position is [m]: at each
/// node the next step whose result has the highest [score] (the first on
/// a tie). [m] is consumed.
Position _greedyFinal(PlayNode n, MutablePosition m, Side side, StepRules rules,
    double Function(BoardView) score) {
  var x = n;
  while (!x.isComplete) {
    Step? best;
    var bestScore = double.negativeInfinity;
    for (final s in x.nextSteps) {
      final a = rules.apply(m, side, s);
      final sc = score(m);
      rules.undo(m, side, a);
      if (best == null || sc > bestScore) {
        best = s;
        bestScore = sc;
      }
    }
    rules.apply(m, side, best!);
    x = x.child(best)!;
  }
  return x.finalPosition!;
}

/// The final of a uniformly random walk from [n] to a complete node.
Position _randomFinal(PlayNode n, Random rng) {
  var x = n;
  while (!x.isComplete) {
    final next = x.nextSteps.toList();
    x = x.child(next[rng.nextInt(next.length)])!;
  }
  return x.finalPosition!;
}
