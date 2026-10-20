import 'dart:math';

import 'package:tavli_bot/tavli_bot.dart';
import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/positions.dart';
import '../support/search_support.dart' show worstCascade;

/// The largest budget a request may ask for: `Bot.requestBudget` caps it
/// at 2x the level's (160 ms at Medium), which every request here needs
/// only a fraction of, so timing does not change a reply.
const _big = Duration(seconds: 60);

BotRequest _req(
  Variant v, {
  BotRequestKind kind = BotRequestKind.choosePlay,
  Position? position,
  Side side = Side.one,
  List<int> dice = const [3, 1],
  bool cascade = false,
  CubeState cube = const CubeState(enabled: false),
  BotLevel level = BotLevel.medium,
  List<Step> steps = const [],
  Duration? budget = _big,
  int seed = 1,
  int id = 1,
  TurnContext? context,
}) =>
    BotRequest(
      id: id,
      kind: kind,
      variant: v,
      position: position ?? Position.forRules(v.rules),
      side: side,
      dice: dice,
      cascade: cascade,
      context: context ?? TurnContext(firstTurn: position == null),
      cube: cube,
      level: level,
      seed: seed,
      budget: budget,
      steps: steps,
    );

/// The tree [r] plays in.
PlayTree _tree(BotRequest r) {
  final rules = r.variant.rules;
  final d = r.dice;
  return r.cascade
      ? generateCascade(r.position, r.side, d, rules, r.context)
      : generatePlays(
          r.position,
          r.side,
          d.length == 2 && d[0] == d[1] ? [d[0], d[0], d[0], d[0]] : d,
          rules,
          r.context);
}

/// [steps] replay from [r]'s position, one basically legal step at a time
/// ([StepRules]), to a complete play of a freshly generated tree, i.e. a
/// legal play the reducer accepts as `SubmitPlay(steps)`.
void _expectReplays(BotRequest r, List<Step> steps) {
  final tree = _tree(r);
  if (!tree.hasPlay) {
    expect(steps, isEmpty, reason: '$r');
    return;
  }
  final sr = StepRules(r.variant.rules);
  final m = r.position.toMutable();
  for (final s in steps) {
    expect(sr.basicSteps(m, r.side, s.die), contains(s),
        reason: '$r: $s in $steps');
    sr.apply(m, r.side, s);
  }
  final node = tree.walk(steps);
  expect(node, isNotNull, reason: '$r: $steps leave the tree');
  expect(node!.isComplete, isTrue, reason: '$r: $steps incomplete');
  expect(m.freeze(), node.finalPosition, reason: '$r');
}

void main() {
  const families = [
    Variant.portes,
    Variant.plakoto,
    Variant.fevga,
    Variant.shortNard,
  ];

  group('each kind in each family', () {
    for (final v in families) {
      test('${v.name}: choosePlay', () {
        // Mid-game: from the start, Fevga's 6-5 has a single play.
        final p = randomPositions(v, 1, Random(7)).single;
        final r = _req(v, position: p, dice: const [6, 5]);
        expect(_tree(r).plays().length, greaterThan(1));
        final reply = Bot.decide(r);
        expect(reply, isA<PlayReply>());
        expect(reply.id, r.id);
        expect((reply as PlayReply).steps, isNotEmpty);
        _expectReplays(r, reply.steps);
        expect(reply.stats.evaluated, greaterThan(0));
        expect(reply.stats.depthReached, 1);
        expect(reply.stats.timedOut, isFalse);
      });

      test('${v.name}: offerDouble and takeDouble', () {
        const cube = CubeState(enabled: true);
        final offer = Bot.decide(_req(v,
            kind: BotRequestKind.offerDouble, dice: const [], cube: cube));
        expect(offer, isA<DecisionReply>());
        // The start position is no double.
        expect((offer as DecisionReply).yes, isFalse);
        final take = Bot.decide(_req(v,
            kind: BotRequestKind.takeDouble,
            dice: const [],
            cube: cube.copyWith(value: 1, offeredBy: Side.two)));
        expect(take, isA<DecisionReply>());
        expect((take as DecisionReply).yes, isTrue);
        expect(take.stats.evaluated, greaterThan(0));
      });

      test('${v.name}: analyze', () {
        final r = _req(v, kind: BotRequestKind.analyze);
        final reply = Bot.decide(r);
        expect(reply, isA<AnalysisReply>());
        final a = (reply as AnalysisReply).analysis;
        expect(a.nextStepQuality.values, contains(StepQuality.best));
        expect(a.lossSoFar, 0);
        expect(reply.stats.depthReached, 1);
      });
    }

    test('gulBara cascade: choosePlay and analyze', () {
      final f = worstCascade;
      final r = _req(Variant.gulBara,
          position: f.position,
          side: f.side,
          dice: f.queue,
          cascade: true,
          level: BotLevel.easy,
          budget: const Duration(milliseconds: 50));
      final play = Bot.decide(r);
      expect(play, isA<PlayReply>());
      _expectReplays(r, (play as PlayReply).steps);
      final a = Bot.decide(_req(Variant.gulBara,
          kind: BotRequestKind.analyze,
          position: f.position,
          side: f.side,
          dice: f.queue,
          cascade: true,
          steps: play.steps.take(3).toList(),
          budget: const Duration(milliseconds: 50)));
      expect(a, isA<AnalysisReply>(), reason: '$a');
    });
  });

  test('deterministic: equal requests give equal steps', () {
    final p = randomPositions(Variant.plakoto, 1, Random(3)).single;
    for (final level in BotLevel.values) {
      final r =
          _req(Variant.plakoto, position: p, dice: const [6, 5], level: level);
      final a = Bot.decide(r) as PlayReply, b = Bot.decide(r) as PlayReply;
      expect(a.steps, b.steps, reason: level.name);
      expect(a.stats.timedOut, isFalse, reason: level.name);
    }
  });

  test('cascade remainders (tails of a cascade queue) are valid', () {
    final p = randomPositions(Variant.gulBara, 1, Random(5)).single;
    for (final q in [
      cascadeQueue(1),
      cascadeQueue(4),
      const [5, 6, 6, 6, 6],
      const [6],
    ]) {
      final r = _req(Variant.gulBara,
          position: p, dice: q, cascade: true, level: BotLevel.easy);
      final reply = Bot.decide(r);
      expect(reply, isA<PlayReply>(), reason: '$q: $reply');
      _expectReplays(r, (reply as PlayReply).steps);
    }
  });

  test('a request budget is capped at 2x the level budget', () {
    for (final level in BotLevel.values) {
      final prof = LevelProfile.of(level);
      Duration of(Duration? b, {bool cascade = false}) =>
          Bot.requestBudget(_req(Variant.gulBara,
              level: level,
              budget: b,
              cascade: cascade,
              dice: cascade ? cascadeQueue(3) : const [3, 1]));
      expect(of(null), prof.budget);
      expect(of(null, cascade: true), prof.cascadeBudget);
      expect(
          of(const Duration(milliseconds: 1)), const Duration(milliseconds: 1));
      expect(of(_big), prof.budget * 2);
      expect(of(_big, cascade: true), prof.cascadeBudget * 2);
    }
  });

  test('the search gets the budget less a 5 % reserve (at least 1 ms)', () {
    Duration ms(num v) => Duration(microseconds: (v * 1000).round());
    expect(Bot.searchBudget(ms(270)), ms(256.5));
    expect(Bot.searchBudget(ms(100)), ms(95));
    expect(Bot.searchBudget(ms(7)), ms(6));
    expect(Bot.searchBudget(ms(0.5)), Duration.zero);
  });

  group('invalid requests are ErrorReplies', () {
    const cube = CubeState(enabled: true);
    final bad = <String, BotRequest>{
      'die 7': _req(Variant.portes, dice: const [7, 1]),
      'die 0': _req(Variant.portes, dice: const [0, 1]),
      'three dice': _req(Variant.portes, dice: const [1, 2, 3]),
      'four unequal': _req(Variant.portes, dice: const [1, 1, 1, 2]),
      'no dice': _req(Variant.portes, dice: const []),
      'cascade outside Gul Bara':
          _req(Variant.portes, dice: cascadeQueue(3), cascade: true),
      'empty cascade': _req(Variant.gulBara, dice: const [], cascade: true),
      'long cascade':
          _req(Variant.gulBara, dice: [...cascadeQueue(1), 6], cascade: true),
      'cube with dice': _req(Variant.portes,
          kind: BotRequestKind.offerDouble, dice: const [3, 1], cube: cube),
      'take without an offer': _req(Variant.portes,
          kind: BotRequestKind.takeDouble, dice: const [], cube: cube),
      'take of own offer': _req(Variant.portes,
          kind: BotRequestKind.takeDouble,
          dice: const [],
          cube: cube.copyWith(offeredBy: Side.one)),
      'wrong direction': _req(Variant.portes,
          position: Position.forRules(Variant.fevga.rules)),
      'game over':
          _req(Variant.portes, position: posOpp(const {}, const {6: 15})),
      'negative budget':
          _req(Variant.portes, budget: const Duration(milliseconds: -1)),
      'steps on choosePlay':
          _req(Variant.portes, steps: const [Step(24, 21, 3)]),
      'steps off the tree': _req(Variant.portes,
          kind: BotRequestKind.analyze, steps: const [Step(24, 18, 6)]),
      'cascade queue not ending in 6s':
          _req(Variant.gulBara, dice: const [2, 2, 2, 2], cascade: true),
      'cascade queue with a gap': _req(Variant.gulBara,
          dice: const [4, 4, 4, 4, 6, 6, 6, 6], cascade: true),
      'cascade queue out of order':
          _req(Variant.gulBara, dice: const [6, 6, 6, 5], cascade: true),
      'negative head departures':
          _req(Variant.longNard, context: TurnContext(headDepartures: -1)),
      'too many head departures':
          _req(Variant.longNard, context: TurnContext(headDepartures: 16)),
      'home hit on pip 0':
          _req(Variant.portes, context: TurnContext(homeHitMask: 1)),
      'home hit on pip 7':
          _req(Variant.portes, context: TurnContext(homeHitMask: 1 << 7)),
      '25 steps': _req(Variant.portes,
          kind: BotRequestKind.analyze,
          steps: List.filled(25, const Step(24, 21, 3))),
    };
    for (final MapEntry(key: why, value: r) in bad.entries) {
      test(why, () {
        final reply = Bot.decide(r);
        expect(reply, isA<ErrorReply>(), reason: '$reply');
        expect(reply.id, r.id);
        expect((reply as ErrorReply).message, isNotEmpty);
      });
    }
  });

  test(
      'random requests in every variant and kind: never throws; '
      'every play replays legally', () {
    final rng = Random(2026);
    var plays = 0;
    for (final v in Variant.values) {
      final rules = v.rules;
      for (final p in randomPositions(v, 25, Random(100 + v.index))) {
        for (final kind in BotRequestKind.values) {
          final a = 1 + rng.nextInt(6), b = 1 + rng.nextInt(6);
          final cube = kind == BotRequestKind.offerDouble ||
              kind == BotRequestKind.takeDouble;
          final cascade = !cube && rules.cascade != null && a == b;
          final side = rng.nextBool() ? Side.one : Side.two;
          final r = BotRequest(
            id: rng.nextInt(1 << 30),
            kind: kind,
            variant: v,
            position: p,
            side: side,
            dice: cube
                ? const []
                : cascade
                    ? cascadeQueue(a)
                    : rng.nextBool() || a != b
                        ? [a, b]
                        : [a, a, a, a],
            cascade: cascade,
            context: TurnContext(),
            cube: CubeState(
                enabled: true,
                offeredBy:
                    kind == BotRequestKind.takeDouble ? side.opponent : null),
            level: BotLevel.values[rng.nextInt(4)],
            seed: rng.nextInt(1000),
            budget: const Duration(milliseconds: 3),
          );
          final reply = Bot.decide(r);
          expect(reply.id, r.id);
          switch (reply) {
            case PlayReply(:final steps):
              _expectReplays(r, steps);
              plays++;
            case DecisionReply():
              expect(cube, isTrue);
            case AnalysisReply():
              expect(kind, BotRequestKind.analyze);
            case ErrorReply(:final message):
              fail('$r: $message');
          }
        }
      }
    }
    expect(plays, Variant.values.length * 25);
  });
}
