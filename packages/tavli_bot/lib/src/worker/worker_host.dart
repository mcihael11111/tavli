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

/// Drops request [id] if it has not started.
final class CancelMessage {
  const CancelMessage(this.id);
  final int id;
}

/// A host-side job that is not a [BotRequest].
enum ControlKind {
  /// Decides one dummy request per family (queued like a request).
  warm,

  /// Replies with the ids decided so far (the last [WorkerHost.ledgerSize];
  /// answered on receipt). For tests.
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

/// Closes the host's port; the isolate then ends.
final class ShutdownMessage {
  const ShutdownMessage();
}

/// Test-only faults, set by `BotWorker.spawnForTest`: when request
/// [exitOn] is about to be decided the isolate exits
/// (`Isolate.exit()`), and when [throwOn] is, an uncaught error kills it.
final class WorkerFaults {
  const WorkerFaults({this.exitOn, this.throwOn});
  final int? exitOn, throwOn;
}

/// The isolate entry point: sends its port back (the handshake), then
/// serves it until a [ShutdownMessage].
void workerMain((SendPort, WorkerFaults) args) {
  final (out, faults) = args;
  final port = ReceivePort();
  final host = WorkerHost(out, faults);
  port.listen((m) {
    if (m is ShutdownMessage) {
      port.close();
    } else {
      host.receive(m);
    }
  });
  out.send(port.sendPort);
}

/// Queues requests and answers them in order, one per event-loop turn.
///
/// Cancellation: [Bot.decide] runs synchronously, so no message is read
/// while a request runs. Each request runs in its own event (a zero
/// timer, which the VM posts behind the messages already received), so
/// every cancel or superseding request that arrived meanwhile is applied
/// before the next one starts: a cancelled request still in the queue is
/// dropped unanswered. A running request runs to its budget and is
/// answered; the client has already failed it and discards the reply.
final class WorkerHost {
  WorkerHost(this._out, this._faults);

  /// How many decided ids [ControlKind.ledger] remembers.
  static const ledgerSize = 256;

  final SendPort _out;
  final WorkerFaults _faults;
  final _queue = ListQueue<Object>();
  final _decided = ListQueue<int>();
  bool _scheduled = false;

  void receive(Object? m) {
    switch (m) {
      case BotRequest(:final supersedes):
        if (supersedes != null) _drop(supersedes);
        _enqueue(m);
      case CancelMessage(:final id):
        _drop(id);
      case ControlMessage(kind: ControlKind.ledger, :final token):
        _out.send(ControlReply(token, List<int>.of(_decided)));
      case ControlMessage():
        _enqueue(m);
    }
  }

  void _drop(int id) =>
      _queue.removeWhere((j) => j is BotRequest && j.id == id);

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
      case BotRequest():
        if (job.id == _faults.exitOn) Isolate.exit();
        if (job.id == _faults.throwOn) throw StateError('test fault');
        final reply = Bot.decide(job);
        _decided.add(job.id);
        if (_decided.length > ledgerSize) _decided.removeFirst();
        _out.send(reply);
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
