/// The long-lived bot isolate and its client (design spec SP2 §8): the UI
/// isolate sends [BotRequest]s and awaits [BotReply]s; it never searches.
library;

import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'protocol.dart';
import 'worker_host.dart';

const _noStats =
    BotStats(evaluated: 0, depthReached: 0, elapsedUs: 0, timedOut: false);

/// Hosts [Bot.decide] in a long-lived isolate.
///
/// **Ordering.** The worker answers requests one at a time, in the order
/// sent. Each request travels with a sequence number private to this
/// client, so a reply is matched to the request that asked for it even
/// when the caller reuses a [BotRequest.id] (e.g. after a cancel).
///
/// **Cancellation** ([cancel], or a request whose `supersedes` names an
/// older one). A search is synchronous, so the worker cannot read a
/// cancel while one runs; instead:
/// - the cancelled request's future completes at once with
///   `ErrorReply('cancelled')`, here on the calling isolate;
/// - if the worker has not started it, it is dropped unanswered (the
///   worker applies every message received before starting each
///   request);
/// - if it is running, it runs to its budget ([Bot.requestBudget]; a
///   Gul Bara cascade's core tree build cannot be interrupted at all),
///   and its late reply is dropped.
///
/// So a cancel frees the caller at once, and the worker once the running
/// request ends.
///
/// **Faults.** [Bot.decide] turns every error into an [ErrorReply], so
/// the isolate does not die of a bad request. If it dies anyway (exit or
/// uncaught error), every pending request completes with an
/// [ErrorReply] naming the cause, and the next [request] spawns a fresh
/// isolate:
/// - after a backoff of 50 ms, doubling per death without a reply in
///   between, up to 2 s (no tight respawn loop);
/// - a spawn whose handshake takes longer than the handshake timeout
///   (10 s) fails the requests waiting on it;
/// - if [warm] was ever called, the fresh isolate is warmed again before
///   it decides anything (one dummy decide per family, tens of ms).
final class BotWorker {
  BotWorker._(this._hooks, this._handshakeTimeout);

  final WorkerTestHooks _hooks;
  final Duration _handshakeTimeout;
  _Connection? _live;
  Future<_Connection>? _connecting;

  /// Pending requests by sequence number, and the sequence number of each
  /// pending caller id.
  final _pending = <int, _Pending>{};
  final _seqOf = <int, int>{};
  final _controls = <int, Completer<Object?>>{};
  var _nextSeq = 0, _nextToken = 0;
  var _disposed = false, _warmed = false;
  var _spawns = 0;

  /// Isolate deaths (or failed spawns) since the last reply: drives the
  /// respawn backoff.
  var _deaths = 0;

  /// How many isolates this worker has spawned (1 + respawns).
  /// Diagnostic; tests use it to observe respawns.
  int get spawnCount => _spawns;

  /// Spawns the isolate and waits for its handshake.
  static Future<BotWorker> spawn() =>
      _spawn(const WorkerTestHooks(), const Duration(seconds: 10));

  /// **Test-only.** A worker whose isolate exits (`Isolate.exit`) when it
  /// is about to decide request [exitOn], dies of an uncaught error
  /// before deciding request [throwOn], or, from spawn number
  /// [stallHandshakeFrom] on, never completes its handshake (with
  /// [handshakeTimeout]). Respawned isolates keep the same hooks. It also
  /// enables [decidedIds]. Not part of the protocol: a production worker
  /// cannot be told to crash.
  static Future<BotWorker> spawnForTest({
    int? exitOn,
    int? throwOn,
    int? stallHandshakeFrom,
    Duration handshakeTimeout = const Duration(seconds: 10),
  }) =>
      _spawn(
          WorkerTestHooks(
              exitOn: exitOn,
              throwOn: throwOn,
              stallHandshakeFrom: stallHandshakeFrom,
              ledger: true),
          handshakeTimeout);

  static Future<BotWorker> _spawn(
      WorkerTestHooks hooks, Duration handshakeTimeout) async {
    final w = BotWorker._(hooks, handshakeTimeout);
    await w._connect();
    return w;
  }

  /// Decides one dummy request per family in the worker (JIT/AOT
  /// warm-up), and again after every respawn. Throws [StateError] if the
  /// isolate dies meanwhile.
  Future<void> warm() {
    _warmed = true;
    return _control(ControlKind.warm);
  }

  /// **Test-only** ([spawnForTest] workers): the request ids the current
  /// isolate has decided, oldest first (the last [WorkerHost.ledgerSize]).
  /// Dropped requests are absent. Throws [StateError] on a production
  /// worker, which keeps no ledger.
  Future<List<int>> decidedIds() async {
    final ids = await _control(ControlKind.ledger);
    if (ids == null) throw StateError('decidedIds needs spawnForTest');
    return ids as List<int>;
  }

  /// Answers [r] in the worker. Never throws before [dispose]: a failure
  /// is an [ErrorReply]. A request whose id is still pending is refused
  /// with an [ErrorReply]. Throws [StateError] after [dispose].
  Future<BotReply> request(BotRequest r) async {
    if (_disposed) throw StateError('BotWorker disposed');
    if (_seqOf.containsKey(r.id)) {
      return ErrorReply(
          id: r.id, stats: _noStats, message: 'duplicate id ${r.id}');
    }
    final old = r.supersedes;
    if (old != null) cancel(old);
    final seq = _nextSeq++;
    final done = Completer<BotReply>();
    _pending[seq] = _Pending(r.id, done);
    _seqOf[r.id] = seq;
    final _Connection c;
    try {
      c = _live ?? await _connect();
    } catch (e) {
      _finish(seq, 'worker spawn failed: $e');
      return done.future;
    }
    // Still pending: not cancelled, failed or disposed while connecting.
    if (_pending.containsKey(seq)) {
      try {
        c.to.send(RequestEnvelope(seq, r));
      } catch (e) {
        _finish(seq, 'send failed: $e');
      }
    }
    return done.future;
  }

  /// Cancels request [id]: its future completes now with
  /// `ErrorReply('cancelled')` (see the class comment). No-op if it is
  /// not pending.
  void cancel(int id) {
    final seq = _seqOf[id];
    if (seq == null || !_finish(seq, 'cancelled')) return;
    _live?.to.send(CancelMessage(seq));
  }

  /// Fails the pending requests with `ErrorReply('disposed')` and kills
  /// the isolate.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    // An isolate still connecting is killed when its handshake arrives.
    final c = _live;
    if (c != null) _die(c, 'disposed', fault: false);
    _failAll('disposed');
  }

  Future<Object?> _control(ControlKind kind) async {
    if (_disposed) throw StateError('BotWorker disposed');
    final token = _nextToken++;
    final done = Completer<Object?>();
    _controls[token] = done;
    try {
      final c = _live ?? await _connect();
      if (identical(_controls[token], done)) {
        c.to.send(ControlMessage(token, kind));
      }
    } catch (_) {
      _controls.remove(token);
      rethrow;
    }
    return done.future;
  }

  /// Completes pending request [seq] with an [ErrorReply]; false if it
  /// was not pending.
  bool _finish(int seq, String message) {
    final p = _pending.remove(seq);
    if (p == null) return false;
    _seqOf.remove(p.id);
    p.done.complete(ErrorReply(id: p.id, stats: _noStats, message: message));
    return true;
  }

  void _failAll(String message) {
    for (final seq in [..._pending.keys]) {
      _finish(seq, message);
    }
    final controls = [..._controls.values];
    _controls.clear();
    for (final c in controls) {
      c.completeError(StateError(message));
    }
  }

  Future<_Connection> _connect() => _connecting ??= _open().whenComplete(() {
        _connecting = null;
      });

  Future<_Connection> _open() async {
    if (_deaths > 0) {
      final ms = min(50 << min(_deaths - 1, 10), 2000);
      await Future<void>.delayed(Duration(milliseconds: ms));
      if (_disposed) throw StateError('BotWorker disposed');
    }
    final from = ReceivePort('tavli_bot replies');
    final exit = ReceivePort('tavli_bot exit');
    final errors = ReceivePort('tavli_bot errors');
    final handshake = Completer<SendPort>();
    final c = _Connection(from, exit, errors);
    from.listen((m) {
      if (m is SendPort) {
        if (!handshake.isCompleted) handshake.complete(m);
      } else if (identical(_live, c)) {
        _onMessage(m);
      }
    });
    void died(String why) {
      if (!handshake.isCompleted) handshake.completeError(StateError(why));
      _die(c, why);
    }

    exit.listen((_) => died('worker exited'));
    errors.listen((e) =>
        died('worker error: ${e is List && e.isNotEmpty ? e.first : e}'));
    final n = _spawns + 1;
    try {
      c.isolate = await Isolate.spawn(
        workerMain,
        (from.sendPort, _hooks, n),
        onExit: exit.sendPort,
        onError: errors.sendPort,
        debugName: 'tavli_bot',
      );
      _spawns = n;
      c.to = await handshake.future.timeout(_handshakeTimeout,
          onTimeout: () => throw TimeoutException(
              'worker handshake timed out', _handshakeTimeout));
    } catch (e) {
      _die(c, 'spawn failed: $e');
      rethrow;
    }
    if (_disposed) {
      _die(c, 'disposed', fault: false);
      throw StateError('BotWorker disposed');
    }
    _live = c;
    if (n > 1 && _warmed) {
      // Re-warm a respawned isolate; queued before any request, and its
      // reply (an unknown token) is ignored.
      c.to.send(ControlMessage(_nextToken++, ControlKind.warm));
    }
    return c;
  }

  void _onMessage(Object? m) {
    switch (m) {
      case ReplyEnvelope(:final seq, :final reply):
        _deaths = 0;
        // Absent if cancelled: the late reply is dropped.
        final p = _pending.remove(seq);
        if (p == null) return;
        _seqOf.remove(p.id);
        p.done.complete(reply);
      case ControlReply(:final token, :final value):
        _controls.remove(token)?.complete(value);
    }
  }

  /// [c] is dead: kill and close it and, if it was the live one, fail
  /// everything pending on it. The next request respawns, after a
  /// backoff if [fault].
  void _die(_Connection c, String why, {bool fault = true}) {
    if (c.dead) return;
    c.dead = true;
    if (fault) _deaths++;
    c.isolate?.kill(priority: Isolate.immediate);
    c.close();
    if (identical(_live, c)) {
      _live = null;
      _failAll(why);
    }
  }
}

final class _Pending {
  _Pending(this.id, this.done);
  final int id;
  final Completer<BotReply> done;
}

/// One spawned isolate: its ports, and whether it has died.
final class _Connection {
  _Connection(this.from, this.exit, this.errors);

  final ReceivePort from, exit, errors;
  Isolate? isolate;
  late SendPort to;
  bool dead = false;

  void close() {
    from.close();
    exit.close();
    errors.close();
  }
}
