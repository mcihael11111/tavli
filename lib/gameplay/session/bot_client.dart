/// The app's one bot worker (design §3, bot turn; SP3 plan Task 2).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tavli_bot/tavli_bot.dart';

/// What [BotClient] needs of a worker; [BotWorker] in the app, a fake in
/// tests.
abstract interface class BotBackend {
  /// Never throws before [dispose]; a failure is an [ErrorReply].
  Future<BotReply> request(BotRequest r);
  void cancel(int id);
  Future<void> warm();
  Future<void> dispose();
}

/// Starts a worker.
typedef BotBackendSpawner = Future<BotBackend> Function();

/// [BotWorker] as a [BotBackend].
final class WorkerBackend implements BotBackend {
  WorkerBackend._(this._w);
  final BotWorker _w;

  static Future<BotBackend> spawn() async =>
      WorkerBackend._(await BotWorker.spawn());

  @override
  Future<BotReply> request(BotRequest r) => _w.request(r);
  @override
  void cancel(int id) => _w.cancel(id);
  @override
  Future<void> warm() => _w.warm();
  @override
  Future<void> dispose() => _w.dispose();
}

const _noStats =
    BotStats(evaluated: 0, depthReached: 0, elapsedUs: 0, timedOut: false);

/// One per app ([botClientProvider]). Spawns the worker lazily, on the
/// first [warmUp] (call it when a game opens) or [request], and never on
/// the startup path.
///
/// [request] never throws: a failed spawn, a cancel or [dispose] completes
/// the request with an [ErrorReply] (`'bot unavailable: ...'`,
/// `'cancelled'`, `'disposed'`), and a failed spawn is retried by the next
/// request. A cancel completes the request at once, whether or not it has
/// reached the worker.
///
/// Lanes ([requestOn]) name a stream of questions where only the newest
/// matters (teaching analysis, the bot's turn): each request supersedes
/// the lane's pending one.
class BotClient {
  BotClient({BotBackendSpawner? spawn}) : _spawn = spawn ?? WorkerBackend.spawn;

  final BotBackendSpawner _spawn;
  Future<BotBackend>? _backend;

  /// The connected worker, once [_backend] has completed.
  BotBackend? _live;
  Future<void>? _warm;
  bool _disposed = false;
  int _nextId = 1;

  final _pending = <int, Completer<BotReply>>{};
  final _sent = <int>{};
  final _lanes = <Object, int>{};

  /// A fresh request id.
  int nextId() => _nextId++;

  /// Spawns and warms the worker, once. Never throws: a failure is logged
  /// and the next call or request tries again.
  Future<void> warmUp() => _warm ??= () async {
        try {
          await (await _connect()).warm();
        } catch (e) {
          _warm = null;
          debugPrint('BotClient: warm-up failed: $e');
        }
      }();

  /// Asks the worker [r] (ids from [nextId]).
  Future<BotReply> request(BotRequest r) {
    if (_disposed) return Future.value(_error(r.id, 'disposed'));
    if (_pending.containsKey(r.id)) {
      return Future.value(_error(r.id, 'duplicate id ${r.id}'));
    }
    final old = r.supersedes;
    if (old != null) cancel(old);
    final done = Completer<BotReply>();
    _pending[r.id] = done;
    unawaited(_send(r));
    return done.future;
  }

  /// Sends the request [build] makes from a fresh id and the lane's pending
  /// request id (null if none), cancelling that one.
  Future<BotReply> requestOn(
      Object lane, BotRequest Function(int id, int? supersedes) build) {
    final old = _lanes[lane];
    final id = nextId();
    final r = build(id, _pending.containsKey(old) ? old : null);
    if (old != null) cancel(old);
    _lanes[lane] = id;
    return request(r).whenComplete(() {
      if (_lanes[lane] == id) _lanes.remove(lane);
    });
  }

  /// Completes request [id] with `ErrorReply('cancelled')` now; no-op if it
  /// is not pending.
  void cancel(int id) {
    if (!_finish(id, _error(id, 'cancelled'))) return;
    if (_sent.remove(id)) _live?.cancel(id);
  }

  /// Cancels [lane]'s pending request, if any.
  void cancelLane(Object lane) {
    final id = _lanes.remove(lane);
    if (id != null) cancel(id);
  }

  /// Fails every pending request with `'disposed'` and stops the worker.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final id in [..._pending.keys]) {
      _finish(id, _error(id, 'disposed'));
    }
    final b = _backend;
    _backend = null;
    _live = null;
    if (b != null) {
      try {
        await (await b).dispose();
      } catch (_) {
        // The spawn failed: nothing to stop.
      }
    }
  }

  Future<BotBackend> _connect() {
    if (_disposed) return Future.error(StateError('BotClient disposed'));
    return _backend ??= _spawn().then((b) {
      if (!_disposed) _live = b;
      return b;
    }, onError: (Object e) {
      _backend = null;
      throw e;
    });
  }

  Future<void> _send(BotRequest r) async {
    final BotBackend b;
    try {
      b = await _connect();
    } catch (e) {
      _finish(r.id, _error(r.id, 'bot unavailable: $e'));
      return;
    }
    // Cancelled or disposed while the worker was starting.
    if (!_pending.containsKey(r.id)) return;
    _sent.add(r.id);
    BotReply reply;
    try {
      reply = await b.request(r);
    } catch (e) {
      reply = _error(r.id, 'bot unavailable: $e');
    }
    _sent.remove(r.id);
    _finish(r.id, reply);
  }

  bool _finish(int id, BotReply reply) {
    final done = _pending.remove(id);
    if (done == null) return false;
    done.complete(reply);
    return true;
  }

  static ErrorReply _error(int id, String message) =>
      ErrorReply(id: id, stats: _noStats, message: message);
}

/// The app's bot client; disposed with the root container.
final botClientProvider = Provider<BotClient>((ref) {
  final c = BotClient();
  ref.onDispose(() => unawaited(c.dispose()));
  return c;
});
