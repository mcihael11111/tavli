/// The long-lived bot isolate and its client (design spec SP2 §8): the UI
/// isolate sends [BotRequest]s and awaits [BotReply]s; it never searches.
library;

import 'dart:async';
import 'dart:isolate';

import 'protocol.dart';
import 'worker_host.dart';

const _noStats =
    BotStats(evaluated: 0, depthReached: 0, elapsedUs: 0, timedOut: false);

/// Hosts [Bot.decide] in a long-lived isolate.
///
/// **Ordering.** The worker answers requests one at a time, in the order
/// sent.
///
/// **Cancellation** ([cancel], or a request whose `supersedes` names an
/// older one). A search is synchronous, so the worker cannot read a
/// cancel while one runs; instead:
/// - the cancelled request's future completes at once with
///   `ErrorReply('cancelled')`, here on the calling isolate;
/// - if the worker has not started it, it is dropped unanswered (the
///   worker applies every message received before starting each
///   request);
/// - if it is running, it runs to its budget (the level's, or the
///   request's), and its late reply is discarded.
///
/// So a cancel frees the caller at once and the worker within one budget.
///
/// **Faults.** [Bot.decide] turns every error into an [ErrorReply], so
/// the isolate does not die of a bad request. If it dies anyway (exit or
/// uncaught error), every pending request completes with an
/// [ErrorReply] naming the cause, and the next [request] spawns a fresh
/// isolate ([spawnCount]).
final class BotWorker {
  BotWorker._(this._faults);

  final WorkerFaults _faults;
  _Connection? _live;
  Future<_Connection>? _connecting;
  final _pending = <int, Completer<BotReply>>{};
  final _controls = <int, Completer<Object?>>{};
  var _nextToken = 0;
  var _disposed = false;
  var _spawns = 0;

  /// How many isolates this worker has spawned (1 + respawns).
  int get spawnCount => _spawns;

  /// Spawns the isolate and waits for its handshake.
  static Future<BotWorker> spawn() => _spawn(const WorkerFaults());

  /// For tests only: a worker whose isolate exits (`Isolate.exit`) when
  /// it is about to decide request [exitOn], or dies of an uncaught error
  /// before deciding request [throwOn]. Respawned isolates keep the same
  /// faults. Not part of the protocol: a production worker cannot be
  /// told to crash.
  static Future<BotWorker> spawnForTest({int? exitOn, int? throwOn}) =>
      _spawn(WorkerFaults(exitOn: exitOn, throwOn: throwOn));

  static Future<BotWorker> _spawn(WorkerFaults faults) async {
    final w = BotWorker._(faults);
    await w._connect();
    return w;
  }

  /// Decides one dummy request per family in the worker (JIT/AOT
  /// warm-up). Throws [StateError] if the isolate dies meanwhile.
  Future<void> warm() => _control(ControlKind.warm);

  /// For tests: the ids the current isolate has decided, oldest first
  /// (the last [WorkerHost.ledgerSize]). Dropped requests are absent.
  Future<List<int>> decidedIds() async =>
      (await _control(ControlKind.ledger))! as List<int>;

  /// Answers [r] in the worker. Never throws once spawned: a failure is
  /// an [ErrorReply]. A request whose id is still pending is refused
  /// with an [ErrorReply]. Throws [StateError] after [dispose].
  Future<BotReply> request(BotRequest r) async {
    if (_disposed) throw StateError('BotWorker disposed');
    if (_pending.containsKey(r.id)) {
      return ErrorReply(
          id: r.id, stats: _noStats, message: 'duplicate id ${r.id}');
    }
    final old = r.supersedes;
    if (old != null) cancel(old);
    final done = Completer<BotReply>();
    _pending[r.id] = done;
    try {
      final c = _live ?? await _connect();
      // Still ours: not cancelled, failed or disposed while connecting.
      if (identical(_pending[r.id], done)) c.to.send(r);
    } catch (e) {
      _finish(r.id, 'worker spawn failed: $e');
    }
    return done.future;
  }

  /// Cancels request [id]: its future completes now with
  /// `ErrorReply('cancelled')` (see the class comment). No-op if it is
  /// not pending.
  void cancel(int id) {
    if (!_finish(id, 'cancelled')) return;
    _live?.to.send(CancelMessage(id));
  }

  /// Fails the pending requests with `ErrorReply('disposed')` and kills
  /// the isolate.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    // An isolate still connecting is killed when its handshake arrives.
    final c = _live;
    if (c != null) _die(c, 'disposed');
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

  /// Completes pending request [id] with an [ErrorReply]; false if it was
  /// not pending.
  bool _finish(int id, String message) {
    final done = _pending.remove(id);
    done?.complete(ErrorReply(id: id, stats: _noStats, message: message));
    return done != null;
  }

  void _failAll(String message) {
    for (final id in [..._pending.keys]) {
      _finish(id, message);
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
    final from = ReceivePort('tavli_bot replies');
    final exit = ReceivePort('tavli_bot exit');
    final errors = ReceivePort('tavli_bot errors');
    final handshake = Completer<SendPort>();
    final c = _Connection(from, exit, errors);
    from.listen((m) {
      if (m is SendPort) {
        handshake.complete(m);
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
    try {
      c.isolate = await Isolate.spawn(
        workerMain,
        (from.sendPort, _faults),
        onExit: exit.sendPort,
        onError: errors.sendPort,
        debugName: 'tavli_bot',
      );
      _spawns++;
      c.to = await handshake.future;
    } catch (_) {
      c.close();
      rethrow;
    }
    if (_disposed) {
      _die(c, 'disposed');
      throw StateError('BotWorker disposed');
    }
    _live = c;
    return c;
  }

  void _onMessage(Object? m) {
    switch (m) {
      case BotReply(:final id):
        // Absent if cancelled: the late reply is discarded.
        _pending.remove(id)?.complete(m);
      case ControlReply(:final token, :final value):
        _controls.remove(token)?.complete(value);
    }
  }

  /// [c] is dead: close it and, if it was the live one, fail everything
  /// pending on it. The next request respawns.
  void _die(_Connection c, String why) {
    if (c.dead) return;
    c.dead = true;
    c.isolate?.kill(priority: Isolate.immediate);
    c.close();
    if (identical(_live, c)) {
      _live = null;
      _failAll(why);
    }
  }
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
