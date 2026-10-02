import 'dart:math';

import 'package:tavli_bot/src/search/budget.dart';
import 'package:tavli_bot/src/search/ply.dart';
import 'package:tavli_bot/tavli_bot.dart';
import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/positions.dart';
import '../support/search_support.dart';

final _portes = Variant.portes.rules;
final _start = Position.forRules(_portes);

SearchResult _choose(
  Position p,
  List<int> dice,
  LevelProfile profile, {
  VariantRules? rules,
  int seed = 1,
  Evaluator? evaluator,
  Duration? budget,
  bool Function()? cancelled,
  bool cascade = false,
}) =>
    choosePlay(
      position: p,
      side: Side.one,
      dice: dice,
      cascade: cascade,
      context: TurnContext(),
      rules: rules ?? _portes,
      profile: profile,
      rng: Random(seed),
      evaluator: evaluator,
      budget: budget,
      cancelled: cancelled,
    );

void main() {
  final easy = LevelProfile.of(BotLevel.easy);
  final medium = LevelProfile.of(BotLevel.medium);
  final expert = LevelProfile.of(BotLevel.expert);

  group('no choice: no evaluation', () {
    test('a single legal play is returned without evaluation', () {
      // My last checker on my 1-point: 6-5 bears it off (one final).
      final p = posOpp({1: 1}, {13: 5, 8: 5, 6: 5});
      final r = _choose(p, [6, 5], expert);
      expect(r.stats.evaluated, 0);
      expect(r.stats.timedOut, isFalse);
      expectLegal(
          generatePlays(p, Side.one, [6, 5], _portes, TurnContext()), r.play);
    });

    test('no legal play returns the empty play', () {
      // On the bar against a closed board.
      final p = posOpp({13: 14}, {6: 3, 5: 2, 4: 2, 3: 2, 2: 2, 1: 2, 13: 2},
          barOne: 1);
      final r = _choose(p, [6, 6, 6, 6], expert);
      expect(r.play.steps, isEmpty);
      expect(r.play.finalPosition, p);
      expect(r.stats.evaluated, 0);
    });

    test('a double given as [d, d] is played as four dice', () {
      final a = _choose(_start, [3, 3], expert);
      final b = _choose(_start, [3, 3, 3, 3], expert);
      expect(a.play, b.play);
      expect(a.play.steps, hasLength(4));
    });
  });

  test('deterministic: same inputs and seed, same play', () {
    final ps = randomPositions(Variant.portes, 6, Random(11));
    for (final level in BotLevel.values) {
      final prof = LevelProfile.of(level);
      for (final p in ps) {
        // A budget no search here reaches, so timing cannot change it.
        final a = _choose(p, [5, 2], prof,
            seed: 9, budget: const Duration(seconds: 60));
        final b = _choose(p, [5, 2], prof,
            seed: 9, budget: const Duration(seconds: 60));
        expect(a.play, b.play, reason: '$level $p');
        expect(a.equity, b.equity, reason: '$level $p');
      }
    }
  });

  test('levels search to their depth', () {
    final p = randomPositions(Variant.portes, 1, Random(3)).single;
    const big = Duration(seconds: 60);
    expect(_choose(p, [6, 4], easy, budget: big).stats.depthReached, 0);
    expect(_choose(p, [6, 4], medium, budget: big).stats.depthReached, 1);
    expect(_choose(p, [6, 4], expert, budget: big).stats.depthReached, 2);
  });

  group('budget', () {
    test('2 ms evaluations, 20 ms budget: returns within 40 ms', () {
      final tree =
          generatePlays(_start, Side.one, [2, 2, 2, 2], _portes, TurnContext());
      expect(tree.plays().length, greaterThan(20), reason: 'needs > 20 ms');
      for (var rep = 0; rep < 2; rep++) {
        // The first round warms up the code paths.
        final slow = SlowEvaluator(
            evaluatorFor(_portes), const Duration(milliseconds: 2));
        final wall = Stopwatch()..start();
        final r = _choose(_start, [2, 2, 2, 2], expert,
            evaluator: slow, budget: const Duration(milliseconds: 20));
        final wallUs = wall.elapsedMicroseconds;
        expect(r.stats.timedOut, isTrue);
        expect(r.stats.depthReached, 0);
        expect(r.stats.evaluated, slow.calls);
        expectLegal(tree, r.play);
        // The search's own clock: the binding 40 ms. The wall clock adds
        // the call overhead and is capped loosely (CI noise).
        expect(r.stats.elapsedUs, lessThan(40000));
        expect(wallUs, lessThan(400000));
      }
    });

    test('a timeout during 1-ply falls back to the 0-ply answer', () {
      // 0-ply on ~30 plays fits in 30 ms; one 1-ply candidate (hundreds
      // of evaluations) does not.
      final slow = SlowEvaluator(
          evaluatorFor(_portes), const Duration(microseconds: 200));
      final r = _choose(_start, [6, 4], medium,
          evaluator: slow, budget: const Duration(milliseconds: 30));
      expect(r.stats.timedOut, isTrue);
      expect(r.stats.depthReached, 0);
      final zero = _choose(_start, [6, 4], zeroPly);
      expect(r.equity, isNot(isNaN));
      expect(r.equity, lessThanOrEqualTo(zero.equity + 1e-9));
    });

    test('cancel stops the search after the first evaluation', () {
      var polls = 0;
      final r = _choose(_start, [2, 2, 2, 2], expert, cancelled: () {
        polls++;
        return true;
      });
      expect(polls, 1);
      expect(r.stats.evaluated, 1);
      expect(r.stats.timedOut, isFalse);
      expectLegal(
          generatePlays(_start, Side.one, [2, 2, 2, 2], _portes, TurnContext()),
          r.play);
    });
  });

  group('selection', () {
    test('noise 0 and top fraction 0 take the best', () {
      final r = _choose(_start, [3, 1], zeroPly);
      expect(r.play.steps.toSet(), {const Step(8, 5, 3), const Step(6, 5, 1)});
    });

    test('Easy varies with the seed but stays in its top half', () {
      final p = randomPositions(Variant.portes, 1, Random(5)).single;
      final tree = generatePlays(p, Side.one, [4, 3], _portes, TurnContext());
      final n = tree.plays().length;
      final best = _choose(p, [4, 3], zeroPly).equity;
      final seen = <Position>{};
      for (var seed = 0; seed < 40; seed++) {
        final r = _choose(p, [4, 3], easy, seed: seed);
        seen.add(r.play.finalPosition);
        expect(r.equity, greaterThan(best - 2 * easy.noise - 1e-9));
      }
      expect(seen.length, greaterThan(1));
      expect(seen.length, lessThanOrEqualTo((n * easy.topFraction).ceil()));
    });
  });

  group('Gul Bara look-ahead plays doubles as four dice', () {
    final gulBara = Variant.gulBara.rules;
    final ps = randomPositions(Variant.gulBara, 20, Random(21));

    test('replies to a double are its four-dice finals, never a cascade', () {
      final scorer = PlyScorer(evaluatorFor(gulBara), gulBara,
          SearchClock(const Duration(hours: 1)));
      for (final p in ps) {
        for (var d = 1; d <= 6; d++) {
          final dice = [d, d, d, d];
          final tree = generatePlays(p, Side.two, dice, gulBara, TurnContext());
          expect(scorer.replies(p, Side.two, dice).toSet(),
              tree.hasPlay ? tree.finals : {p});
        }
      }
    });

    test('Medium 1-ply over every opponent roll finishes quickly', () {
      final medium = LevelProfile.of(BotLevel.medium);
      for (var rep = 0; rep < 2; rep++) {
        // The first round warms up the code paths.
        for (final p in ps) {
          final w = Stopwatch()..start();
          final r = choosePlay(
            position: p,
            side: Side.one,
            dice: [5, 2],
            cascade: false,
            context: TurnContext(),
            rules: gulBara,
            profile: medium,
            rng: Random(1),
            budget: const Duration(seconds: 60),
          );
          // Unbounded, so this is the whole 1-ply (k = 3..6 candidates x
          // 21 rolls, doubles included): about 5 ms asserts off. A single
          // cascade build in look-ahead could take up to 0.8 s.
          expect(w.elapsedMilliseconds, lessThan(500), reason: '$p');
          expect(r.stats.timedOut, isFalse);
        }
      }
    });
  });

  group('cascade turns', () {
    final gulBara = Variant.gulBara.rules;
    for (final (name, f) in [
      ('worstFailingCascade', worstFailingCascade),
      ('worstCascade', worstCascade),
    ]) {
      for (final level in [BotLevel.easy, BotLevel.expert]) {
        test('$name at ${level.name}: a complete legal play', () {
          final prof = LevelProfile.of(level);
          final wall = Stopwatch()..start();
          final r = choosePlay(
            position: f.position,
            side: f.side,
            dice: f.queue,
            cascade: true,
            context: TurnContext(),
            rules: gulBara,
            profile: prof,
            rng: Random(1),
          );
          final ms = wall.elapsedMilliseconds;
          final tree = generateCascade(
              f.position, f.side, f.queue, gulBara, TurnContext());
          expectLegal(tree, r.play, reason: name);
          expect(r.stats.depthReached, 0);
          // Strict cascade budgets are Task 9 benchmarks (asserts off);
          // here only a loose cap: tree building alone is ~0.26 s
          // asserts off on the failing fixture, and sampling without a
          // stop would take seconds on worstCascade.
          expect(ms, lessThan(10 * 1000), reason: '$name ${r.stats}');
        });
      }
    }
  });
}
