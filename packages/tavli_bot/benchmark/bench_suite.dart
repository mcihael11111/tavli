/// Bot benchmarks with budgets (plan Task 9), shared by
/// `bot_bench_test.dart` (`dart test ... benchmark`, asserts on) and
/// `run_benchmarks.dart` (asserts off: the numbers for the SP2 report).
library;

import 'dart:convert';
import 'dart:math';

import 'package:tavli_bot/tavli_bot.dart';
import 'package:tavli_core/tavli_core.dart';
import 'package:tavli_testkit/tavli_testkit.dart';

import '../test/support/positions.dart';
import '../test/support/search_support.dart' as sp1;
import 'fixtures.dart';

export 'fixtures.dart';

/// Loose regression cap (not a budget) on the single worst cascades:
/// their cost is the core's non-interruptible tree build and walks, up
/// to about 1.1 s for a real-game full 1-1 cascade at Medium. They run
/// on the worker isolate, so they cannot block the UI. 4 s leaves
/// headroom for slower development machines.
const worstCascadeCap = Duration(seconds: 4);

/// The desktop gates (design §1): a third of each level's device budget
/// ([LevelProfile.budget], program spec §3.3). The benchmarks pass them
/// as explicit request budgets and gate against them.
const desktopGates = {
  BotLevel.easy: Duration(milliseconds: 7),
  BotLevel.medium: Duration(milliseconds: 27),
  BotLevel.hard: Duration(milliseconds: 100),
  BotLevel.expert: Duration(milliseconds: 270),
};

/// The desktop gate of [level], doubled for a cascade (design §1).
Duration desktopGate(BotLevel level, {bool cascade = false}) =>
    desktopGates[level]! * (cascade ? 2 : 1);

/// `dart test` runs with asserts on: its budgets are this many times the
/// real ones (as in SP1).
const assertAllowance = 2;

/// Sampled Gul Bara cascades for the cascade gate (≥ 200, plan Task 9).
const sampledCascadeCount = 200;

/// One benchmark result: its stats and, when gated or capped, the limit.
final class BenchResult {
  BenchResult(this.stats, this.budget, {this.note = ''});

  final BenchStats stats;
  final Duration? budget;
  final String note;

  /// Within [budget] times [factor] (and `TAVLI_BENCH_SCALE`).
  bool within({int factor = 1}) =>
      budget == null || stats.withinBudget(budget! * factor);
}

/// A decision to time: a position, side and dice (or cascade queue).
final class PlayFixture {
  const PlayFixture(this.variant, this.json, this.side, this.dice, this.plays,
      {this.cascade = false});

  final Variant variant;

  /// `Position.toJson`, encoded.
  final String json;
  final Side side;
  final List<int> dice;

  /// Legal plays (for a cascade: the dice used), checked before timing so
  /// a fixture cannot silently drift.
  final int plays;
  final bool cascade;

  Position get position =>
      Position.fromJson(jsonDecode(json) as Map<String, Object?>);

  String get label => cascade
      ? '${variant.name} cascade ${dice.first}x${dice.length}'
      : '${variant.name} ${dice.join('-')}';

  /// What [plays] records, from a fresh tree.
  int measure() {
    final rules = variant.rules;
    return cascade
        ? generateCascade(position, side, dice, rules, TurnContext()).diceUsed
        : generatePlays(position, side, dice, rules, TurnContext())
            .plays()
            .length;
  }

  void check() {
    final got = measure();
    if (got != plays) {
      throw StateError('$label: measured $got, fixture says $plays');
    }
  }

  /// A [kind] request at [level] on this fixture, with the level's
  /// [desktopGate] as its budget unless [budget] is given.
  BotRequest request(BotLevel level,
      {int seed = 0,
      BotRequestKind kind = BotRequestKind.choosePlay,
      int id = 0,
      Duration? budget}) {
    final isCascade = cascade &&
        (kind == BotRequestKind.choosePlay || kind == BotRequestKind.analyze);
    return BotRequest(
      id: id,
      kind: kind,
      variant: variant,
      position: position,
      side: kind == BotRequestKind.takeDouble ? side.opponent : side,
      dice: switch (kind) {
        BotRequestKind.offerDouble || BotRequestKind.takeDouble => const [],
        _ => dice,
      },
      cascade: isCascade,
      context: TurnContext(),
      cube: CubeState(
          enabled: true,
          offeredBy: kind == BotRequestKind.takeDouble ? side : null),
      level: level,
      seed: seed,
      budget: budget ?? desktopGate(level, cascade: isCascade),
    );
  }
}

/// Times [Bot.decide] on each of [requests] once (after deciding the
/// first [warmup] untimed). Every reply must be a success.
BenchStats timeDecide(String name, List<BotRequest> requests,
    {int warmup = 2}) {
  for (final r in requests.take(warmup)) {
    _decide(r);
  }
  final nanosPerTick = 1e9 / Stopwatch().frequency;
  final ns = <int>[];
  final sw = Stopwatch();
  for (final r in requests) {
    sw
      ..reset()
      ..start();
    _decide(r);
    sw.stop();
    ns.add((sw.elapsedTicks * nanosPerTick).round());
  }
  return BenchStats.fromNanos(name, ns);
}

BotReply _decide(BotRequest r) {
  final reply = Bot.decide(r);
  if (reply is ErrorReply) throw StateError('$r: ${reply.message}');
  return reply;
}

/// Decides one request per level on every fixture, untimed (JIT warm-up).
void warmUp() {
  for (final f in playFixtures) {
    for (final l in BotLevel.values) {
      _decide(f.request(l));
    }
  }
}

/// `choosePlay` at [level] on fixture [f], [samples] seeds: gated by the
/// level's desktop gate.
BenchResult benchChoosePlay(PlayFixture f, BotLevel level, int samples) {
  f.check();
  return BenchResult(
    timeDecide('choosePlay ${level.name} ${f.label}',
        [for (var i = 0; i < samples; i++) f.request(level, seed: i)]),
    desktopGate(level),
    note: '${f.plays} plays',
  );
}

/// [kind] at Medium on every play fixture's position, [samples] seeds
/// each: gated by Medium's desktop gate.
BenchResult benchCube(BotRequestKind kind, int samples) => BenchResult(
      timeDecide('${kind.name} medium (${playFixtures.length} positions)', [
        for (final f in playFixtures)
          for (var i = 0; i < samples; i++)
            f.request(BotLevel.medium, seed: i, kind: kind),
      ]),
      desktopGate(BotLevel.medium),
    );

/// `analyze` at Medium (no steps taken) on fixture [f]: gated by
/// Medium's desktop gate.
BenchResult benchAnalyze(PlayFixture f, int samples) {
  f.check();
  return BenchResult(
    timeDecide('analyze medium ${f.label}', [
      for (var i = 0; i < samples; i++)
        f.request(BotLevel.medium, seed: i, kind: BotRequestKind.analyze),
    ]),
    desktopGate(BotLevel.medium),
  );
}

/// [n] Gul Bara cascades from random games (seeded): a random position,
/// side and double, its full queue. Like SP1's sampled cascades.
List<PlayFixture> sampledCascades([int n = sampledCascadeCount]) {
  final rng = Random(4242);
  return [
    for (final p in randomPositions(Variant.gulBara, n, Random(4243)))
      PlayFixture(
          Variant.gulBara,
          jsonEncode(p.toJson()),
          rng.nextBool() ? Side.one : Side.two,
          cascadeQueue(1 + rng.nextInt(6)),
          0,
          cascade: true),
  ];
}

/// [kind] at [level] on each of [cascades] once: p95 gated by the level's
/// cascade desktop gate (design §1: 2x).
BenchResult benchSampledCascades(
    List<PlayFixture> cascades, BotLevel level, BotRequestKind kind) {
  final stats = timeDecide(
      '${kind.name} ${level.name} gulBara sampled cascades',
      [
        for (var i = 0; i < cascades.length; i++)
          cascades[i].request(level, seed: i, kind: kind),
      ],
      warmup: 10);
  return BenchResult(stats, desktopGate(level, cascade: true),
      note: 'max ${(stats.maxNs / 1e6).toStringAsFixed(1)} ms');
}

/// The single worst cascades: SP1's `worstCascade` and
/// `worstFailingCascade`, and [slowestRealCascade]. Reported against
/// [worstCascadeCap] only.
List<PlayFixture> get worstCascades => [
      for (final (name, f) in [
        ('worstCascade', sp1.worstCascade),
        ('worstFailingCascade', sp1.worstFailingCascade),
      ])
        PlayFixture(Variant.gulBara, jsonEncode(f.position.toJson()), f.side,
            f.queue, name == 'worstCascade' ? 24 : 21,
            cascade: true),
      slowestRealCascade,
    ];

const _worstNames = [
  'SP1 worstCascade',
  'SP1 worstFailingCascade',
  'slowest real full cascade',
];

/// [kind] at [level] on each of [worstCascades], [samples] times: capped
/// by [worstCascadeCap].
List<BenchResult> benchWorstCascades(
        BotLevel level, BotRequestKind kind, int samples) =>
    [
      for (var i = 0; i < worstCascades.length; i++)
        () {
          final f = worstCascades[i]..check();
          return BenchResult(
            timeDecide(
                '${kind.name} ${level.name} ${_worstNames[i]}',
                [
                  for (var s = 0; s < samples; s++)
                    f.request(level, seed: s, kind: kind),
                ],
                warmup: 0),
            worstCascadeCap,
            note: 'regression cap',
          );
        }(),
    ];

/// A deterministic measure of what deciding cascade [f] costs: the
/// states the core's cascade search visits ([PlayTree.searchedStates])
/// building the tree and walking it once along first steps and 24 times
/// at random (seed 0), roughly as Medium's search walks it.
({int work, int diceUsed}) cascadeWork(PlayFixture f) {
  final tree = generateCascade(
      f.position, f.side, f.dice, f.variant.rules, TurnContext());
  if (!tree.hasPlay) return (work: 0, diceUsed: 0);
  final rng = Random(0);
  for (var walk = 0; walk <= 24; walk++) {
    var node = tree.root;
    while (!node.isComplete) {
      final next = node.nextSteps.toList();
      node =
          node.child(walk == 0 ? next.first : next[rng.nextInt(next.length)])!;
    }
  }
  return (work: tree.searchedStates, diceUsed: tree.diceUsed);
}

/// `choosePlay` at [level] with a tiny [budget] on the heaviest play
/// fixture (most plays). The search's predictive stop and reserve keep
/// it within the budget, except for the non-interruptible tree build:
/// the bound is the budget plus the build's p95 (measured here).
BenchResult benchSmallBudget(BotLevel level, int samples,
    {Duration budget = const Duration(milliseconds: 2)}) {
  final f = playFixtures.reduce((a, b) => b.plays > a.plays ? b : a)..check();
  final p = f.position;
  // The build and the play list: the search does both before it can
  // stop (choosePlay calls `.plays()` on the tree).
  final build = measure(
      () => generatePlays(p, f.side, f.dice, f.variant.rules, TurnContext())
          .plays(),
      name: 'build',
      samples: samples,
      minWarmup: Duration.zero);
  final stats = timeDecide(
      'choosePlay ${level.name} ${f.label} budget ${budget.inMilliseconds} ms',
      [
        for (var i = 0; i < samples; i++)
          f.request(level, seed: i, budget: budget)
      ]);
  final bound = budget + build.p95;
  return BenchResult(stats, bound,
      note: 'budget + tree build p95 '
          '${(build.p95Ns / 1e6).toStringAsFixed(2)} ms');
}

/// The 21 rolls.
final _rolls = [
  for (var a = 1; a <= 6; a++)
    for (var b = a; b <= 6; b++) a == b ? [a, a, a, a] : [a, b],
];

/// Variants with play fixtures: one per family (Portes, Plakoto, Fevga),
/// Mahbusa (the slowest at Expert among the SP1 worst fixtures), Long
/// Nard (head rule) and Gul Bara (normal rolls; its doubles cascade,
/// benchmarked separately).
const fixtureVariants = [
  Variant.portes,
  Variant.plakoto,
  Variant.fevga,
  Variant.mahbusa,
  Variant.longNard,
  Variant.gulBara,
];

/// Finds the fixtures and returns `fixtures.dart`'s source:
/// - [playFixtures]: per [fixtureVariants] entry, the contact position x
///   side x roll with the most legal plays over [positions] positions
///   from random games (seed 17 + variant index), one for a non-double
///   and (except Gul Bara) one for a double;
/// - [slowestRealCascade]: the full 1-1 cascade (both sides) over
///   [cascadePositions] random Gul Bara positions (seed 4244) with the
///   most [cascadeWork], a deterministic proxy for the slowest to decide
///   (wall clock would make the scan irreproducible).
String scanFixtures({int positions = 300, int cascadePositions = 6000}) {
  String entry(PlayFixture f) =>
      "PlayFixture(Variant.${f.variant.name}, '${f.json}', "
      'Side.${f.side.name}, ${f.dice}, ${f.plays}'
      '${f.cascade ? ', cascade: true' : ''})';
  final out = StringBuffer()
    ..writeln('/// Benchmark fixtures (plan Task 9), found by')
    ..writeln('/// `dart run --no-enable-asserts benchmark/run_benchmarks.dart '
        '--scan`,')
    ..writeln('/// which prints this file (regenerate it, never hand-edit it).')
    ..writeln('/// See `scanFixtures` in `bench_suite.dart`.')
    ..writeln('library;')
    ..writeln()
    ..writeln("import 'package:tavli_core/tavli_core.dart';")
    ..writeln()
    ..writeln("import 'bench_suite.dart' show PlayFixture;")
    ..writeln()
    ..writeln('const playFixtures = [');
  for (final v in fixtureVariants) {
    final rules = v.rules;
    PlayFixture? normal, double;
    for (final p in randomPositions(v, positions, Random(17 + v.index))) {
      if (isRace(p, rules)) continue;
      for (final side in Side.values) {
        for (final dice in _rolls) {
          final isDouble = dice.length == 4;
          if (isDouble && rules.cascade != null) continue;
          final n =
              generatePlays(p, side, dice, rules, TurnContext()).plays().length;
          final best = isDouble ? double : normal;
          if (best == null || n > best.plays) {
            final f = PlayFixture(v, jsonEncode(p.toJson()), side, dice, n);
            if (isDouble) {
              double = f;
            } else {
              normal = f;
            }
          }
        }
      }
    }
    out.writeln('  ${entry(normal!)},');
    if (double != null) out.writeln('  ${entry(double)},');
  }
  out.writeln('];');
  PlayFixture? slowest;
  var slowestWork = -1;
  for (final p
      in randomPositions(Variant.gulBara, cascadePositions, Random(4244))) {
    for (final side in Side.values) {
      final f = PlayFixture(
          Variant.gulBara, jsonEncode(p.toJson()), side, cascadeQueue(1), 0,
          cascade: true);
      final (:work, :diceUsed) = cascadeWork(f);
      if (work > slowestWork) {
        slowestWork = work;
        slowest = PlayFixture(f.variant, f.json, side, f.dice, diceUsed,
            cascade: true);
      }
    }
  }
  out
    ..writeln()
    ..writeln('/// The real-game full 1-1 cascade with the most '
        '`cascadeWork` ($slowestWork),')
    ..writeln('/// the proxy for the slowest to decide (wall clock would '
        'make the scan')
    ..writeln('/// irreproducible).')
    ..writeln('const slowestRealCascade = ${entry(slowest!)};');
  return out.toString();
}
