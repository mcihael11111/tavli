/// The worker isolate's side of [BotWorker]: an ordered queue of requests
/// answered one at a time by [Bot.decide] (design spec SP2 §8).
///
/// Internal: the messages here never leave the package. The public
/// protocol is [BotRequest] / [BotReply].
library;

import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import 'package:tavli_core/tavli_core.dart';

import '../bot.dart';
import '../level/bot_level.dart';
import 'protocol.dart';

/// A request as sent to the worker: [seq] is the client's own sequence
/// number, unique per [BotWorker], so a reply can never be matched to a
/// later request that reuses the caller's [BotRequest.id].
final class RequestEnvelope {
  const RequestEnvelope(this.seq, this.request);
  final int seq;
  final BotRequest request;
}

/// The reply to the [RequestEnvelope] with the same [seq].
final class ReplyEnvelope {
  const ReplyEnvelope(this.seq, this.reply);
  final int seq;
  final BotReply reply;
}

/// Drops the request with sequence number [seq] if it has not started.
final class CancelMessage {
  const CancelMessage(this.seq);
  final int seq;
}

/// A host-side job that is not a [BotRequest].
enum ControlKind {
  /// Decides one dummy request per family (queued like a request).
  warm,

  /// Replies with the ids decided so far (the last [WorkerHost.ledgerSize];
  /// answered on receipt), or null unless spawned for a test.
  ledger,
}

/// A [ControlKind] job; answered by a [ControlReply] with its [token].
final class ControlMessage {
  const ControlMessage(this.token, this.kind);
  final int token;
  final ControlKind kind;
}

final class ControlReply {
  const ControlReply(this.token, this.value);
  final int token;
  final Object? value;
}

/// Test-only behaviour, set by `BotWorker.spawnForTest`; the defaults are
/// production's:
/// - [exitOn]: the isolate exits (`Isolate.exit()`) when it is about to
///   decide the request with that id;
/// - [throwOn]: an uncaught error kills it there instead;
/// - [stallHandshakeFrom]: the isolates spawned at or after this spawn
///   number (1-based) never complete the handshake;
/// - [ledger]: keep the decided ids for `BotWorker.decidedIds`.
final class WorkerTestHooks {
  const WorkerTestHooks(
      {this.exitOn,
      this.throwOn,
      this.stallHandshakeFrom,
      this.ledger = false});
  final int? exitOn, throwOn, stallHandshakeFrom;
  final bool ledger;
}

/// The isolate entry point: sends its port back (the handshake), then
/// serves it until the client kills the isolate. [args]: the reply port,
/// the hooks and this isolate's spawn number.
void workerMain((SendPort, WorkerTestHooks, int) args) {
  final (out, hooks, spawn) = args;
  final port = ReceivePort();
  final host = WorkerHost(out, hooks);
  port.listen(host.receive);
  final stall = hooks.stallHandshakeFrom;
  if (stall == null || spawn < stall) out.send(port.sendPort);
}

/// Queues requests and answers them in order, one per event-loop turn.
///
/// Cancellation: [Bot.decide] runs synchronously, so no message is read
/// while a request runs. Each request runs in its own event (a zero
/// timer, which the VM posts behind the messages already received), so
/// every cancel that arrived meanwhile is applied before the next one
/// starts: a cancelled request still in the queue is dropped unanswered.
/// A running request runs to its budget and is answered; the client has
/// already failed it and drops the reply (its sequence number is no
/// longer pending).
final class WorkerHost {
  WorkerHost(this._out, this._hooks);

  /// How many decided ids [ControlKind.ledger] remembers.
  static const ledgerSize = 256;

  final SendPort _out;
  final WorkerTestHooks _hooks;
  final _queue = ListQueue<Object>();
  final _decided = ListQueue<int>();
  bool _scheduled = false;

  void receive(Object? m) {
    switch (m) {
      case RequestEnvelope():
        _enqueue(m);
      case CancelMessage(:final seq):
        _queue.removeWhere((j) => j is RequestEnvelope && j.seq == seq);
      case ControlMessage(kind: ControlKind.ledger, :final token):
        _out.send(
            ControlReply(token, _hooks.ledger ? List<int>.of(_decided) : null));
      case ControlMessage():
        _enqueue(m);
    }
  }

  void _enqueue(Object job) {
    _queue.add(job);
    _schedule();
  }

  void _schedule() {
    if (_scheduled) return;
    _scheduled = true;
    Timer.run(_runNext);
  }

  void _runNext() {
    _scheduled = false;
    if (_queue.isEmpty) return;
    final job = _queue.removeFirst();
    try {
      _run(job);
    } finally {
      // Scheduled after the job, so its timer event queues behind every
      // message that arrived while the job ran.
      if (_queue.isNotEmpty) _schedule();
    }
  }

  void _run(Object job) {
    switch (job) {
      case RequestEnvelope(:final seq, request: final r):
        if (r.id == _hooks.exitOn) Isolate.exit();
        if (r.id == _hooks.throwOn) throw StateError('test fault');
        final reply = Bot.decide(r);
        if (_hooks.ledger) {
          _decided.add(r.id);
          if (_decided.length > ledgerSize) _decided.removeFirst();
        }
        _out.send(ReplyEnvelope(seq, reply));
      case ControlMessage(:final token):
        for (final r in warmRequests()) {
          Bot.decide(r);
        }
        _out.send(ControlReply(token, null));
    }
  }
}

/// One dummy `choosePlay` per family (hitting, pinning, running) from
/// the start position, at Medium: warms the evaluators and the search.
List<BotRequest> warmRequests() => [
      for (final v in [Variant.portes, Variant.plakoto, Variant.fevga])
        BotRequest(
          id: -1,
          kind: BotRequestKind.choosePlay,
          variant: v,
          position: Position.forRules(v.rules),
          side: Side.one,
          dice: const [3, 1],
          context: TurnContext(firstTurn: true),
          cube: const CubeState(enabled: false),
          level: BotLevel.medium,
          seed: 0,
        ),
    ];
