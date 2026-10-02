// Prints the measured event-loop gaps.
// ignore_for_file: avoid_print
library;

import 'dart:async';

import 'package:tavli_bot/tavli_bot.dart';
import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/generation_fixtures.dart';

/// Mahbusa's worst fixture (749 plays): Expert needs about 0.75 s for it
/// (asserts off), so an Expert search here runs to its budget.
final _worst =
    generationFixtures.firstWhere((f) => f.variant == Variant.mahbusa);

BotRequest _req(
  int id, {
  BotLevel level = BotLevel.hard,
  Duration? budget,
  List<int>? dice,
  int? supersedes,
}) =>
    BotRequest(
      id: id,
      kind: BotRequestKind.choosePlay,
      variant: _worst.variant,
      position: _worst.position,
      side: _worst.side,
      dice: dice ?? _worst.dice,
      context: TurnContext(),
      cube: const CubeState(enabled: false),
      level: level,
      seed: id,
      budget: budget,
      supersedes: supersedes,
    );

/// A request answered in about [ms] (Expert runs to its budget here).
BotRequest _slow(int id, int ms, {int? supersedes}) => _req(id,
    level: BotLevel.expert,
    budget: Duration(milliseconds: ms),
    supersedes: supersedes);

/// A request answered at once (Easy, 0-ply, no time limit).
BotRequest _quick(int id) =>
    _req(id, level: BotLevel.easy, budget: const Duration(seconds: 60));

Matcher _error(String message) =>
    isA<ErrorReply>().having((e) => e.message, 'message', message);

void main() {
  late BotWorker worker;
  setUp(() async => worker = await BotWorker.spawn());
  tearDown(() => worker.dispose());

  test('round trip: replies equal in-process decide, for every kind', () async {
    await worker.warm();
    final rs = [
      _quick(1),
      BotRequest(
        id: 2,
        kind: BotRequestKind.offerDouble,
        variant: Variant.shortNard,
        position: Position.forRules(Variant.shortNard.rules),
        side: Side.one,
        dice: const [],
        context: TurnContext(),
        cube: const CubeState(enabled: true),
        level: BotLevel.medium,
        seed: 2,
      ),
      BotRequest(
        id: 3,
        kind: BotRequestKind.analyze,
        variant: Variant.portes,
        position: Position.forRules(Variant.portes.rules),
        side: Side.two,
        dice: const [5, 3],
        context: TurnContext(firstTurn: true),
        cube: const CubeState(enabled: false),
        level: BotLevel.medium,
        seed: 3,
        budget: const Duration(seconds: 60),
      ),
    ];
    for (final r in rs) {
      final got = await worker.request(r);
      final want = Bot.decide(r);
      expect(got.runtimeType, want.runtimeType, reason: '$got');
      expect(got.id, r.id);
      switch ((got, want)) {
        case (final PlayReply a, final PlayReply b):
          expect(a.steps, b.steps);
        case (final DecisionReply a, final DecisionReply b):
          expect(a.yes, b.yes);
        case (final AnalysisReply a, final AnalysisReply b):
          expect(a.analysis, b.analysis);
        default:
          fail('$got vs $want');
      }
    }
    expect(await worker.decidedIds(), [1, 2, 3]);
    expect(worker.spawnCount, 1);
  });

  test('a bad request is an ErrorReply and the worker lives on', () async {
    final bad = await worker.request(_req(1, dice: const [7, 1]));
    expect(bad, isA<ErrorReply>());
    expect(await worker.request(_quick(2)), isA<PlayReply>());
    expect(worker.spawnCount, 1);
  });

  test('a duplicate pending id is refused', () async {
    final first = worker.request(_slow(1, 100));
    expect(await worker.request(_quick(1)), _error('duplicate id 1'));
    expect(await first, isA<PlayReply>());
  });

  group('cancellation', () {
    test('a running request is failed at once; its late reply is discarded',
        () async {
      await worker.warm();
      final watch = Stopwatch()..start();
      final running = worker.request(_slow(1, 400));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      worker.cancel(1);
      expect(await running, _error('cancelled'));
      expect(watch.elapsedMilliseconds, lessThan(300),
          reason: 'completed before the search ended');
      // The worker finishes the search, then answers the next request.
      expect(await worker.request(_quick(2)), isA<PlayReply>());
      expect(
          watch.elapsedMilliseconds,
          greaterThanOrEqualTo(
              Bot.searchBudget(const Duration(milliseconds: 400))
                  .inMilliseconds));
      expect(await worker.decidedIds(), [1, 2]);
    });

    test('a queued request is dropped before it starts (cancel)', () async {
      await worker.warm();
      final watch = Stopwatch()..start();
      final first = worker.request(_slow(1, 300));
      final queued = worker.request(_slow(2, 300));
      final third = worker.request(_slow(3, 300));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      worker.cancel(2);
      expect(await queued, _error('cancelled'));
      expect(await first, isA<PlayReply>());
      expect(await third, isA<PlayReply>());
      expect(await worker.decidedIds(), [1, 3]);
      expect(watch.elapsedMilliseconds, lessThan(900),
          reason: 'request 2 never ran');
    });

    test('a queued request is dropped before it starts (supersedes)', () async {
      await worker.warm();
      final first = worker.request(_slow(1, 200));
      final stale = worker.request(_slow(2, 200));
      final fresh = worker.request(_slow(3, 50, supersedes: 2));
      expect(await stale, _error('cancelled'));
      expect(await first, isA<PlayReply>());
      expect(await fresh, isA<PlayReply>());
      expect(await worker.decidedIds(), [1, 3]);
    });

    test('cancelling an unknown or answered id is a no-op', () async {
      expect(await worker.request(_quick(1)), isA<PlayReply>());
      worker.cancel(1);
      worker.cancel(99);
      expect(await worker.request(_quick(2)), isA<PlayReply>());
    });
  });

  group('crash recovery', () {
    for (final (how, spawn, message) in [
      (
        'Isolate.exit',
        () => BotWorker.spawnForTest(exitOn: 13),
        'worker exited',
      ),
      (
        'uncaught error',
        () => BotWorker.spawnForTest(throwOn: 13),
        'worker error: Bad state: test fault',
      ),
    ]) {
      test('$how: pending requests fail, the next request respawns', () async {
        final w = await spawn();
        addTearDown(w.dispose);
        expect(await w.request(_quick(12)), isA<PlayReply>());
        final crash = w.request(_quick(13));
        final behind = w.request(_quick(14));
        expect(await crash, _error(message));
        expect(await behind, _error(message));
        expect(w.spawnCount, 1);
        expect(await w.request(_quick(15)), isA<PlayReply>());
        expect(w.spawnCount, 2);
        expect(await w.decidedIds(), [15]);
      });
    }
  });

  test('dispose fails pending requests; later requests throw', () async {
    final pending = worker.request(_slow(1, 200));
    await worker.dispose();
    expect(await pending, _error('disposed'));
    expect(() => worker.request(_quick(2)), throwsStateError);
    expect(worker.warm, throwsStateError);
  });

  test('the main isolate stays responsive during back-to-back Hard searches',
      () async {
    await worker.warm();
    final ticks = <int>[];
    final clock = Stopwatch()..start();
    final timer = Timer.periodic(const Duration(milliseconds: 1),
        (_) => ticks.add(clock.elapsedMicroseconds));
    // Hard on every variant's worst fixture in turn (each 2-10 ms asserts
    // off), so the main isolate also handles a steady stream of replies.
    var answered = 0;
    while (clock.elapsedMilliseconds < 1000) {
      final f = generationFixtures[answered % generationFixtures.length];
      final reply = await worker.request(BotRequest(
        id: answered,
        kind: BotRequestKind.choosePlay,
        variant: f.variant,
        position: f.position,
        side: f.side,
        dice: f.dice,
        context: TurnContext(),
        cube: const CubeState(enabled: false),
        level: BotLevel.hard,
        seed: answered,
      ));
      expect(reply, isA<PlayReply>(), reason: '$reply');
      answered++;
    }
    timer.cancel();
    final gaps = [
      for (var i = 1; i < ticks.length; i++) ticks[i] - ticks[i - 1],
    ]..sort();
    final p99 = gaps[(0.99 * gaps.length).ceil() - 1], max = gaps.last;
    print('main-isolate timer gaps over ${clock.elapsedMilliseconds} ms '
        '($answered Hard searches, ${gaps.length} gaps): '
        'p50 ${gaps[gaps.length ~/ 2]} us, p99 $p99 us, max $max us');
    expect(answered, greaterThanOrEqualTo(5));
    expect(p99, lessThanOrEqualTo(4000));
    expect(max, lessThanOrEqualTo(20000));
  });
}
