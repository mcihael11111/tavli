import 'package:tavli_bot/tavli_bot.dart';
import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/generation_fixtures.dart';
import '../support/search_support.dart' show worstFailingCascade;

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
  // spawnForTest for decidedIds; no fault hooks set.
  setUp(() async => worker = await BotWorker.spawnForTest());
  tearDown(() => worker.dispose());

  test('round trip: replies equal in-process decide, for every kind', () async {
    await worker.warm();
    // Small positions, far inside their budgets, so timing cannot change
    // a reply (the timedOut checks below).
    final rs = [
      BotRequest(
        id: 1,
        kind: BotRequestKind.choosePlay,
        variant: Variant.plakoto,
        position: Position.forRules(Variant.plakoto.rules),
        side: Side.one,
        dice: const [6, 5],
        context: TurnContext(firstTurn: true),
        cube: const CubeState(enabled: false),
        level: BotLevel.medium,
        seed: 1,
      ),
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
      Bot.decide(r); // warms this isolate
      final want = Bot.decide(r);
      expect(got.stats.timedOut, isFalse, reason: '$got');
      expect(want.stats.timedOut, isFalse, reason: '$want');
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

    test('a reused id after cancelling a running request gets its own reply',
        () async {
      // SP1's worstFailingCascade at Medium: about 0.3 s of
      // non-interruptible core tree build.
      final f = worstFailingCascade;
      BotRequest at(BotRequestKind kind) => BotRequest(
            id: 20,
            kind: kind,
            variant: Variant.gulBara,
            position: f.position,
            side: f.side,
            dice: kind == BotRequestKind.choosePlay ? f.queue : const [],
            cascade: kind == BotRequestKind.choosePlay,
            context: TurnContext(),
            cube: const CubeState(enabled: true),
            level: BotLevel.medium,
            seed: 20,
          );
      await worker.warm();
      final running = worker.request(at(BotRequestKind.choosePlay));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      worker.cancel(20);
      expect(await running, _error('cancelled'));
      final again = await worker.request(at(BotRequestKind.offerDouble));
      expect(again, isA<DecisionReply>(), reason: '$again');
      expect(again.id, 20);
      expect(await worker.decidedIds(), [20, 20]);
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

  test('respawns back off: 50 ms, doubling per death without a reply',
      () async {
    final w = await BotWorker.spawnForTest(exitOn: 13);
    addTearDown(w.dispose);
    final watch = Stopwatch()..start();
    expect(await w.request(_quick(13)), _error('worker exited'));
    final first = watch.elapsedMilliseconds;
    expect(await w.request(_quick(13)), _error('worker exited'));
    final second = watch.elapsedMilliseconds;
    expect(await w.request(_quick(15)), isA<PlayReply>());
    final third = watch.elapsedMilliseconds;
    expect(second - first, greaterThanOrEqualTo(50));
    expect(third - second, greaterThanOrEqualTo(100));
    expect(w.spawnCount, 3);
    // A reply resets the backoff.
    final quick = Stopwatch()..start();
    expect(await w.request(_quick(16)), isA<PlayReply>());
    expect(quick.elapsedMilliseconds, lessThan(50));
  });

  test('a respawn whose handshake times out fails the waiting requests',
      () async {
    final w = await BotWorker.spawnForTest(
        exitOn: 13,
        stallHandshakeFrom: 2,
        handshakeTimeout: const Duration(milliseconds: 200));
    addTearDown(w.dispose);
    expect(await w.request(_quick(13)), _error('worker exited'));
    final a = w.request(_quick(14)), b = w.request(_quick(15));
    for (final r in [await a, await b]) {
      expect(
          r,
          isA<ErrorReply>().having((e) => e.message, 'message',
              startsWith('worker spawn failed: TimeoutException')));
    }
  });

  test('decidedIds is test-only', () async {
    final w = await BotWorker.spawn();
    addTearDown(w.dispose);
    expect(await w.request(_quick(1)), isA<PlayReply>());
    await expectLater(w.decidedIds(), throwsStateError);
  });

  test('dispose fails pending requests; later requests throw', () async {
    final pending = worker.request(_slow(1, 200));
    await worker.dispose();
    expect(await pending, _error('disposed'));
    expect(() => worker.request(_quick(2)), throwsStateError);
    expect(worker.warm, throwsStateError);
  });
}
