/// Benchmarks with budgets (plan Task 17), shared by
/// `play_generation_bench_test.dart` (run by `dart test ... benchmark`,
/// asserts on) and
/// `run_benchmarks.dart` (asserts off: the numbers for the SP1 report).
library;

import 'dart:convert';
import 'dart:math';

import 'package:tavli_core/tavli_core.dart';
import 'package:tavli_testkit/tavli_testkit.dart';

import '../test/support/positions.dart';
import '../test/support/random_play.dart';

export 'bench_fixtures.dart';

/// `generatePlays` p95 on each variant's worst fixture (design spec §8).
const generationBudget = Duration(milliseconds: 2);

/// Reducer `StepAction` p95 on a mid-game state (design spec §8).
const reducerStepBudget = Duration(microseconds: 50);

/// Gul Bara cascade p95 over cascades sampled from random games, and over
/// the failing ones among them (plan Task 17). The worst single cascade
/// may exceed it; it is reported, not budgeted.
const cascadeBudget = Duration(milliseconds: 50);

/// Loose regression caps (not budgets) on the single worst cascades,
/// which may exceed [cascadeBudget]: about 13x and 5x their asserts-off
/// p95 when added, so only a big regression trips them.
const worstCascadeCap = Duration(seconds: 1);
const worstFailingCascadeCap = Duration(seconds: 2);

/// `dart test` runs with asserts on, where `MutablePosition.freeze()`
/// validates every board: its budgets are this many times the real ones.
const assertAllowance = 2;

/// One benchmark result: its stats and, when budgeted, its budget.
final class BenchResult {
  BenchResult(this.stats, this.budget, {this.note = ''});

  final BenchStats stats;
  final Duration? budget;
  final String note;

  /// Within [budget] times [factor] (and `TAVLI_BENCH_SCALE`).
  bool within({int factor = 1}) =>
      budget == null || stats.withinBudget(budget! * factor);
}

/// A position, side and dice for a generation benchmark.
final class GenerationFixture {
  const GenerationFixture(
    this.variant,
    this.json,
    this.side,
    this.dice,
    this.finals, {
    this.cascade = false,
  });

  final Variant variant;

  /// `Position.toJson`, encoded.
  final String json;
  final Side side;
  final List<int> dice;

  /// Legal finals (for a cascade: the dice used), checked before timing
  /// so a fixture cannot silently drift.
  final int finals;
  final bool cascade;

  Position get position =>
      Position.fromJson(jsonDecode(json) as Map<String, Object?>);

  /// Builds the tree; a cascade is also walked to its first complete node
  /// (what the reducer and a client do with it).
  PlayTree run(Position p) {
    final rules = variant.rules;
    if (!cascade) return generatePlays(p, side, dice, rules, TurnContext());
    final t = generateCascade(p, side, dice, rules, TurnContext());
    var n = t.root;
    while (t.hasPlay && !n.isComplete) {
      n = n.child(n.nextSteps.first)!;
    }
    return t;
  }

  /// What [finals] records, from a fresh run.
  int measureOf(PlayTree t) => cascade ? t.diceUsed : t.finals.length;

  String get label => cascade
      ? '${variant.name} cascade ${dice.first}x${dice.length} '
          '(${finals == dice.length ? 'reaches the end' : 'fails at $finals'})'
      : '${variant.name} ${dice.join('-')}';
}

/// `generatePlays` on [f], [samples] times.
BenchResult benchGeneration(
  GenerationFixture f, {
  int samples = 200,
  int warmup = 20,
  Duration minWarmup = const Duration(milliseconds: 300),
}) {
  final p = f.position;
  final got = f.measureOf(f.run(p));
  if (got != f.finals) {
    throw StateError('${f.label}: ${f.cascade ? 'used' : 'finals'} $got, '
        'fixture says ${f.finals}');
  }
  return BenchResult(
    measure(() => f.run(p),
        name: 'generate ${f.label}', samples: samples, minWarmup: minWarmup),
    !f.cascade
        ? generationBudget
        : f.finals == f.dice.length
            ? worstCascadeCap
            : worstFailingCascadeCap,
    note: f.cascade ? 'regression cap' : '${f.finals} finals',
  );
}

/// A mid-game moving state of [v] (seeded random legal play, at least 20
/// turns in), with its tree built.
GameState midGameState(Variant v) {
  final r = Random(31 + v.index);
  var s = GameState.initial(v);
  while (true) {
    final a = randomLegalAction(s, r);
    if (a == null) {
      s = GameState.initial(v); // ended early: play another game
      continue;
    }
    final res = reduce(s, a);
    if (res is GameUpdate) s = res.state;
    final turns = s.turnsTaken[Side.one]! + s.turnsTaken[Side.two]!;
    if (turns >= 20 &&
        s.phase == GamePhase.moving &&
        s.steps.isEmpty &&
        !s.cascadeMode) {
      s.tree; // built once, outside the timing
      return s;
    }
  }
}

/// `reduce(s, StepAction(...))` on [midGameState].
BenchResult benchReducerStep(
  Variant v, {
  int samples = 2000,
  Duration minWarmup = const Duration(milliseconds: 300),
}) {
  final s = midGameState(v);
  final step = StepAction(s.node.nextSteps.first);
  if (reduce(s, step) is! GameUpdate) throw StateError('$step rejected');
  return BenchResult(
    measure(() => reduce(s, step),
        name: 'reduce StepAction ${v.name}',
        samples: samples,
        minWarmup: minWarmup),
    reducerStepBudget,
  );
}

/// Gul Bara cascades sampled from random games: [positions] reachable
/// positions x both sides x the six full queues, each timed once as
/// [GenerationFixture.run] does. Returns all of them and the failing ones
/// (which cannot reach the end of the queue).
({BenchResult all, BenchResult failing}) sampleCascades(int positions) {
  final rules = Variant.gulBara.rules;
  final ps = randomReachablePositions(Variant.gulBara, positions, Random(4242));
  for (final p in ps.take(20)) {
    generateCascade(p, Side.one, cascadeQueue(3), rules, TurnContext());
  }
  final nanosPerTick = 1e9 / Stopwatch().frequency;
  final all = <int>[], failing = <int>[];
  final sw = Stopwatch();
  for (final p in ps) {
    for (final side in Side.values) {
      for (var d = 1; d <= 6; d++) {
        final f = GenerationFixture(
            Variant.gulBara, '', side, cascadeQueue(d), 0,
            cascade: true);
        sw
          ..reset()
          ..start();
        final t = f.run(p);
        sw.stop();
        final ns = (sw.elapsedTicks * nanosPerTick).round();
        all.add(ns);
        if (t.diceUsed < f.dice.length) failing.add(ns);
      }
    }
  }
  BenchResult result(String name, List<int> ns) {
    final sorted = List.of(ns)..sort();
    final p99 =
        sorted[((0.99 * sorted.length).ceil() - 1).clamp(0, ns.length - 1)];
    return BenchResult(BenchStats.fromNanos(name, ns), cascadeBudget,
        note: 'p99 ${(p99 / 1e6).toStringAsFixed(2)} ms');
  }

  return (
    all: result('gulBara sampled cascades', all),
    failing: result('gulBara sampled failing cascades', failing),
  );
}

/// The 21 rolls.
final _rolls = [
  for (var a = 1; a <= 6; a++)
    for (var b = a; b <= 6; b++) a == b ? [a, a, a, a] : [a, b],
];

/// Finds the fixtures: per variant, the position x roll x side with the
/// most finals over [positions] reachable positions (seed 17 + variant
/// index); for Gul Bara also the slowest succeeding and failing cascades
/// over the [sampleCascades] positions. Returns them as Dart source for
/// `bench_fixtures.dart`.
String scanFixtures({int positions = 300, int cascadePositions = 1500}) {
  final out = StringBuffer();
  String entry(GenerationFixture f) =>
      "  GenerationFixture(Variant.${f.variant.name}, '${f.json}', "
      'Side.${f.side.name}, ${f.dice}, ${f.finals}'
      '${f.cascade ? ', cascade: true' : ''}),\n';
  out.write('const generationFixtures = [\n');
  for (final v in Variant.values) {
    GenerationFixture? best;
    for (final p
        in randomReachablePositions(v, positions, Random(17 + v.index))) {
      for (final side in Side.values) {
        for (final dice in _rolls) {
          final n = generatePlays(p, side, dice, v.rules, TurnContext())
              .finals
              .length;
          if (best == null || n > best.finals) {
            best = GenerationFixture(v, jsonEncode(p.toJson()), side, dice, n);
          }
        }
      }
    }
    out.write(entry(best!));
  }
  out.write('];\n\n');
  GenerationFixture? ok, failing;
  var okUs = -1, failingUs = -1;
  for (final p in randomReachablePositions(
      Variant.gulBara, cascadePositions, Random(4242))) {
    for (final side in Side.values) {
      for (var d = 1; d <= 6; d++) {
        final q = cascadeQueue(d);
        final json = jsonEncode(p.toJson());
        final probe =
            GenerationFixture(Variant.gulBara, json, side, q, 0, cascade: true);
        final sw = Stopwatch()..start();
        final t = probe.run(p);
        final us = sw.elapsedMicroseconds;
        final f = GenerationFixture(Variant.gulBara, json, side, q, t.diceUsed,
            cascade: true);
        if (t.diceUsed == q.length && us > okUs) (ok, okUs) = (f, us);
        if (t.diceUsed < q.length && us > failingUs) {
          (failing, failingUs) = (f, us);
        }
      }
    }
  }
  out
    ..write(
        '/// The slowest succeeding cascade found ($okUs us when scanned).\n')
    ..write(
        'const worstCascade = ${entry(ok!).trim().replaceAll(RegExp(r',$'), '')};\n\n')
    ..write(
        '/// The slowest failing cascade found ($failingUs us when scanned).\n')
    ..write('const worstFailingCascade = '
        '${entry(failing!).trim().replaceAll(RegExp(r',$'), '')};\n');
  return out.toString();
}
