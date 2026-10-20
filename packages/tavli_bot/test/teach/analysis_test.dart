import 'dart:math';

import 'package:tavli_bot/tavli_bot.dart';
import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/generation_fixtures.dart';
import '../support/positions.dart';
import '../support/search_support.dart';
import '../support/tactics.dart';

const _one = Side.one;

TurnAnalysis _analyze(
  Position p,
  List<int> dice,
  VariantRules rules, {
  List<Step> steps = const [],
  Side side = _one,
  bool cascade = false,
  Duration? budget = const Duration(seconds: 60),
  LevelProfile? profile,
}) =>
    analyzeTurn(
      position: p,
      side: side,
      dice: dice,
      cascade: cascade,
      context: TurnContext(),
      rules: rules,
      steps: steps,
      profile: profile,
      rng: Random(1),
      budget: budget,
    );

/// Qualities follow the equities: a higher equity never has a worse
/// quality, the gaps to the best next step match the thresholds, and one
/// next step is best.
void _expectConsistent(TurnAnalysis a, {String reason = ''}) {
  if (a.nextStepEquity.isEmpty) return;
  final bestNext = a.nextStepEquity.values.reduce(max);
  expect(bestNext, lessThanOrEqualTo(a.bestEquity), reason: reason);
  expect(a.lossSoFar, closeTo(a.bestEquity - bestNext, 1e-12), reason: reason);
  expect(a.nextStepQuality.values, contains(StepQuality.best), reason: reason);
  for (final s in a.nextStepEquity.keys) {
    final gap = bestNext - a.nextStepEquity[s]!;
    expect(gap, greaterThanOrEqualTo(0), reason: reason);
    expect(a.nextStepQuality[s], qualityOf(gap), reason: reason);
    for (final t in a.nextStepEquity.keys) {
      if (a.nextStepEquity[s]! >= a.nextStepEquity[t]!) {
        expect(a.nextStepQuality[s]!.index,
            lessThanOrEqualTo(a.nextStepQuality[t]!.index),
            reason: reason);
      }
    }
  }
}

void main() {
  test('analyzeTurnRun reports its depth and whether it timed out', () {
    final rules = Variant.portes.rules;
    final start = Position.forRules(rules);
    AnalysisRun run(LevelProfile p, Duration budget) => analyzeTurnRun(
          position: start,
          side: _one,
          dice: const [5, 3],
          cascade: false,
          context: TurnContext(),
          rules: rules,
          steps: const [],
          profile: p,
          rng: Random(1),
          budget: budget,
        );
    final medium = LevelProfile.of(BotLevel.medium);
    final full = run(medium, const Duration(seconds: 60));
    expect((full.depth, full.timedOut), (1, false));
    expect(full.analysis, _analyze(start, [5, 3], rules, profile: medium));
    final none = run(medium, Duration.zero);
    expect((none.depth, none.timedOut), (0, true));
    final easy = run(LevelProfile.of(BotLevel.easy), Duration.zero);
    expect((easy.depth, easy.timedOut), (0, false), reason: '0-ply only');
  });

  test('qualityOf thresholds', () {
    expect(qualityOf(0), StepQuality.best);
    expect(qualityOf(0.01), StepQuality.best);
    expect(qualityOf(0.02), StepQuality.good);
    expect(qualityOf(0.03), StepQuality.good);
    expect(qualityOf(0.05), StepQuality.acceptable);
    expect(qualityOf(0.08), StepQuality.acceptable);
    expect(qualityOf(0.081), StepQuality.poor);
  });

  test('at the turn start one step is best; qualities follow equity', () {
    for (final v in [Variant.portes, Variant.plakoto, Variant.longNard]) {
      final ps = randomPositions(v, 4, Random(v.index));
      for (final p in ps) {
        for (final profile in [
          LevelProfile.of(BotLevel.easy),
          LevelProfile.of(BotLevel.medium),
        ]) {
          final a = _analyze(p, [5, 3], v.rules, profile: profile);
          if (a.nextStepEquity.isEmpty) continue; // no play
          expect(a.nextStepQuality.values, contains(StepQuality.best),
              reason: '$v $p');
          expect(a.playEquityLoss, isNull);
          expect(a.lossSoFar, 0);
          _expectConsistent(a, reason: '$v $p');
        }
      }
    }
  });

  group('keep the mother covered (Plakoto)', () {
    final t = pinningTactics.firstWhere((t) => t.name.contains('mother cov'));
    final r = t.variant.rules;

    test('exposing the mother is poor; the safe step is best', () {
      final a = _analyze(t.position, t.dice, r);
      // 24/20 leads only to plays that leave the mother alone or split
      // both checkers into their home: about 0.4 worse at 1-ply.
      expect(a.nextStepQuality[const Step(24, 20, 4)], StepQuality.poor);
      expect(a.nextStepQuality[const Step(10, 6, 4)], StepQuality.best);
      _expectConsistent(a);
    });

    test('playEquityLoss: 0 for the best play, > 0 for a worse one', () {
      final best =
          _analyze(t.position, t.dice, r, steps: const [Step(10, 6, 4)]);
      expect(best.playEquityLoss, isNull); // incomplete
      expect(
          _analyze(t.position, t.dice, r,
              steps: const [Step(10, 6, 4), Step(6, 5, 1)]).playEquityLoss,
          0);
      final worse = _analyze(t.position, t.dice, r,
          steps: const [Step(24, 20, 4), Step(24, 23, 1)]);
      expect(worse.playEquityLoss, greaterThan(0.08));
    });

    test('after a weak first step: a next step is best, lossSoFar > 0', () {
      final a = _analyze(t.position, t.dice, r, steps: const [Step(24, 20, 4)]);
      // 24/23 (both off the mother) beats 10/9 (mother left alone), and
      // is best among what is left, though 0.4 below the turn's best.
      expect(a.nextStepQuality[const Step(24, 23, 1)], StepQuality.best);
      expect(a.nextStepQuality[const Step(10, 9, 1)], StepQuality.poor);
      expect(a.lossSoFar, greaterThan(0.08));
      _expectConsistent(a);
    });
  });

  test('every play: the minimum loss is 0, and losses match', () {
    final t = hittingTactics.firstWhere((t) => t.name == 'hit and cover');
    final r = t.variant.rules;
    final plays =
        generatePlays(t.position, _one, t.dice, r, TurnContext()).plays();
    final losses = [
      for (final p in plays)
        _analyze(t.position, t.dice, r,
                steps: p.steps, profile: LevelProfile.of(BotLevel.easy))
            .playEquityLoss!,
    ];
    expect(losses.reduce(min), 0);
    expect(losses.where((l) => l > 0), isNotEmpty);
  });

  test('steps off the tree throw', () {
    expect(
        () => _analyze(Position.forRules(Variant.portes.rules), [3, 1],
            Variant.portes.rules,
            steps: const [Step(24, 20, 4)]),
        throwsArgumentError);
  });

  test('runs within the Medium budget on the worst normal fixtures', () {
    final medium = LevelProfile.of(BotLevel.medium);
    for (var rep = 0; rep < 2; rep++) {
      // The first round warms up the code paths.
      for (final f in generationFixtures) {
        final w = Stopwatch()..start();
        final a = analyzeTurn(
          position: f.position,
          side: f.side,
          dice: f.dice,
          cascade: false,
          context: TurnContext(),
          rules: f.variant.rules,
          steps: const [],
          rng: Random(1),
        );
        final ms = w.elapsedMilliseconds;
        expect(a.nextStepQuality.values, contains(StepQuality.best));
        // Strict p95 budgets are Task 9 benchmarks (asserts off); this
        // loose cap (10x) only catches a runaway analysis.
        expect(ms, lessThan(10 * medium.budget.inMilliseconds),
            reason: '${f.variant}');
      }
    }
  });

  group('cascades', () {
    final r = Variant.gulBara.rules;
    for (final (name, f) in [
      ('worstFailingCascade', worstFailingCascade),
      ('worstCascade', worstCascade),
    ]) {
      test('$name: sampled step values, consistent', () {
        final a = _analyze(f.position, f.queue, r,
            side: f.side, cascade: true, budget: null);
        expect(a.nextStepEquity, isNotEmpty);
        expect(a.lossSoFar, 0);
        _expectConsistent(a, reason: name);
      });
    }

    test('a complete cascade play has a loss', () {
      final f = worstFailingCascade;
      final play = choosePlay(
        position: f.position,
        side: f.side,
        dice: f.queue,
        cascade: true,
        context: TurnContext(),
        rules: r,
        profile: LevelProfile.of(BotLevel.easy),
        rng: Random(2),
      ).play;
      final a = _analyze(f.position, f.queue, r,
          side: f.side, cascade: true, steps: play.steps, budget: null);
      expect(a.nextStepEquity, isEmpty);
      expect(a.playEquityLoss, greaterThanOrEqualTo(0));
    });
  });
}
