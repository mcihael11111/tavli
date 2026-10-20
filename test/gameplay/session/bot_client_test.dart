import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tavli/gameplay/session/bot_client.dart';
import 'package:tavli_bot/tavli_bot.dart';
import 'package:tavli_core/tavli_core.dart';

const _stats =
    BotStats(evaluated: 0, depthReached: 0, elapsedUs: 0, timedOut: false);

class FakeBackend implements BotBackend {
  final received = <BotRequest>[];
  final cancelled = <int>[];
  final replies = <int, Completer<BotReply>>{};
  int warms = 0;
  bool disposed = false;

  @override
  Future<BotReply> request(BotRequest r) {
    received.add(r);
    return (replies[r.id] = Completer<BotReply>()).future;
  }

  void answer(int id, {bool yes = true}) =>
      replies[id]!.complete(DecisionReply(id: id, stats: _stats, yes: yes));

  @override
  void cancel(int id) => cancelled.add(id);

  @override
  Future<void> warm() async => warms++;

  @override
  Future<void> dispose() async => disposed = true;
}

BotRequest _req(int id, {int? supersedes}) => BotRequests.fromState(
      GameState.initial(Variant.shortNard, starter: Side.one),
      kind: BotRequestKind.offerDouble,
      level: BotLevel.easy,
      id: id,
      seed: 1,
      supersedes: supersedes,
    );

void main() {
  late FakeBackend backend;
  late int spawns;
  late Completer<void> spawnGate;
  late bool failSpawn;

  BotClient make({bool gated = false}) {
    backend = FakeBackend();
    spawns = 0;
    failSpawn = false;
    spawnGate = Completer<void>();
    if (!gated) spawnGate.complete();
    return BotClient(spawn: () async {
      spawns++;
      await spawnGate.future;
      if (failSpawn) throw StateError('no isolate');
      return backend;
    });
  }

  test('spawns lazily, once, and warms once', () async {
    final c = make();
    expect(spawns, 0);
    await Future.wait([c.warmUp(), c.warmUp()]);
    await c.warmUp();
    expect(spawns, 1);
    expect(backend.warms, 1);
  });

  test('request forwards and returns the reply; ids are unique', () async {
    final c = make();
    final a = c.nextId(), b = c.nextId();
    expect(a, isNot(b));
    final f = c.request(_req(a));
    await pumpEventQueue();
    expect(backend.received.single.id, a);
    backend.answer(a, yes: false);
    expect(await f, DecisionReply(id: a, stats: _stats, yes: false));
    expect(spawns, 1);
  });

  test('a lane supersedes its previous pending request', () async {
    final c = make();
    final first = c.requestOn('teach', (id, old) => _req(id, supersedes: old));
    await pumpEventQueue();
    final firstId = backend.received.single.id;
    expect(backend.received.single.supersedes, isNull);
    final second = c.requestOn('teach', (id, old) => _req(id, supersedes: old));
    await pumpEventQueue();
    expect((await first as ErrorReply).message, 'cancelled');
    expect(backend.cancelled, contains(firstId));
    final secondReq = backend.received.last;
    expect(secondReq.supersedes, firstId);
    backend.answer(secondReq.id);
    expect(await second, isA<DecisionReply>());
    // Answered: the next request on the lane supersedes nothing.
    unawaited(c.requestOn('teach', (id, old) => _req(id, supersedes: old)));
    await pumpEventQueue();
    expect(backend.received.last.supersedes, isNull);
  });

  test('cancel before the worker is up never sends the request', () async {
    final c = make(gated: true);
    final id = c.nextId();
    final f = c.request(_req(id));
    c.cancel(id);
    expect((await f as ErrorReply).message, 'cancelled');
    spawnGate.complete();
    await pumpEventQueue();
    expect(backend.received, isEmpty);
  });

  test('cancelLane cancels the lane request', () async {
    final c = make();
    final f = c.requestOn('turn', (id, old) => _req(id, supersedes: old));
    await pumpEventQueue();
    c.cancelLane('turn');
    expect((await f as ErrorReply).message, 'cancelled');
    expect(backend.cancelled, [backend.received.single.id]);
  });

  test('a failed spawn is an ErrorReply and the next request respawns',
      () async {
    final c = make(gated: true);
    failSpawn = true;
    spawnGate.complete();
    final r = await c.request(_req(c.nextId()));
    expect(r, isA<ErrorReply>());
    failSpawn = false;
    final id = c.nextId();
    final f = c.request(_req(id));
    await pumpEventQueue();
    backend.answer(id);
    expect(await f, isA<DecisionReply>());
    expect(spawns, 2);
  });

  test('dispose fails pending requests and disposes the worker', () async {
    final c = make();
    final f = c.request(_req(c.nextId()));
    await pumpEventQueue();
    await c.dispose();
    expect((await f as ErrorReply).message, 'disposed');
    expect(backend.disposed, isTrue);
    final late = await c.request(_req(c.nextId()));
    expect((late as ErrorReply).message, 'disposed');
  });

  test('works end to end with the real worker', () async {
    final c = BotClient();
    addTearDown(c.dispose);
    final id = c.nextId();
    final s = GameState.initial(Variant.portes, starter: Side.one);
    final rolled = switch (reduce(s, const RollDice(3, 1))) {
      GameUpdate(:final state) => state,
      RuleViolation() && final v => throw StateError('$v'),
    };
    final reply = await c.request(BotRequests.fromState(rolled,
        kind: BotRequestKind.choosePlay,
        level: BotLevel.easy,
        id: id,
        seed: 3));
    expect(reply, isA<PlayReply>());
    expect((reply as PlayReply).steps, isNotEmpty);
  });
}
