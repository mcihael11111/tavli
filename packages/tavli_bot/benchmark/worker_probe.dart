/// Main-isolate responsiveness while the worker isolate decides (plan
/// Task 8; design §1: the UI isolate never searches). Shared by
/// `worker_bench_test.dart` and `run_benchmarks.dart`.
library;

import 'dart:async';

import 'package:tavli_bot/tavli_bot.dart';

import 'bench_suite.dart';

/// Gaps between the ticks of a 1 ms periodic timer on this isolate.
final class GapStats {
  GapStats(this.name, List<int> gapsUs, this.requests)
      : _sorted = List.of(gapsUs)..sort();

  final String name;
  final List<int> _sorted;

  /// Worker requests answered while measuring.
  final int requests;

  int get count => _sorted.length;
  int _rank(double p) => _sorted[((p * count).ceil() - 1).clamp(0, count - 1)];
  int get p50Us => _rank(0.5);
  int get p99Us => _rank(0.99);
  int get maxUs => _sorted.last;

  /// Gaps over 4 ms (design §9: the event-loop latency target).
  int get over4ms => _sorted.where((g) => g > 4000).length;

  @override
  String toString() => '$name: $requests requests, $count gaps, '
      'p50 ${(p50Us / 1000).toStringAsFixed(2)} ms, '
      'p99 ${(p99Us / 1000).toStringAsFixed(2)} ms, '
      'max ${(maxUs / 1000).toStringAsFixed(2)} ms, $over4ms over 4 ms';
}

/// Runs [work] (which returns the requests it made) while a 1 ms timer
/// ticks on this isolate, and returns the gaps between ticks.
Future<GapStats> timerGaps(String name, Future<int> Function() work) async {
  final ticks = <int>[];
  final clock = Stopwatch()..start();
  final timer = Timer.periodic(const Duration(milliseconds: 1),
      (_) => ticks.add(clock.elapsedMicroseconds));
  final requests = await work();
  timer.cancel();
  return GapStats(
      name,
      [for (var i = 1; i < ticks.length; i++) ticks[i] - ticks[i - 1]],
      requests);
}

/// Hard `choosePlay` on every play fixture in turn, back to back, for
/// [duration] (each a few ms, so the main isolate also handles a steady
/// stream of replies).
Future<GapStats> hardBackToBack(BotWorker w,
        {Duration duration = const Duration(seconds: 1)}) =>
    timerGaps('Hard back-to-back', () async {
      final clock = Stopwatch()..start();
      var n = 0;
      while (clock.elapsed < duration) {
        final f = playFixtures[n % playFixtures.length];
        final reply = await w.request(f.request(BotLevel.hard, seed: n, id: n));
        if (reply is! PlayReply) throw StateError('$reply');
        n++;
      }
      return n;
    });

/// [slowestRealCascade] at Medium, [runs] times: about 1 s each of
/// allocation-heavy, non-interruptible core work in the worker, which
/// shares the app's isolate group heap (GC pauses).
Future<GapStats> slowCascade(BotWorker w, {int runs = 2}) =>
    timerGaps('slowest real cascade (Medium)', () async {
      for (var i = 0; i < runs; i++) {
        final reply = await w.request(
            slowestRealCascade.request(BotLevel.medium, seed: i, id: i));
        if (reply is! PlayReply) throw StateError('$reply');
      }
      return runs;
    });
