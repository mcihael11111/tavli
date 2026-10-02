// Prints the measured gaps.
// ignore_for_file: avoid_print
@Tags(['bench'])
library;

import 'package:tavli_bot/tavli_bot.dart';
import 'package:tavli_testkit/tavli_testkit.dart' show benchScale;
import 'package:test/test.dart';

import 'worker_probe.dart';

/// Main-isolate responsiveness (plan Task 8), run alone by
/// `dart test --tags bench --concurrency=1 benchmark`: timer gaps depend
/// on free CPU, which parallel suites (and shared CI runners) take away.
void main() {
  late BotWorker worker;
  setUp(() async {
    worker = await BotWorker.spawn();
    await worker.warm();
  });
  tearDown(() => worker.dispose());

  test('the main isolate stays responsive during back-to-back Hard searches',
      () async {
    final g = await hardBackToBack(worker);
    print(g);
    final scale = benchScale();
    expect(g.requests, greaterThanOrEqualTo(5));
    expect(g.p99Us, lessThanOrEqualTo(4000 * scale), reason: '$g');
    expect(g.maxUs, lessThanOrEqualTo(20000 * scale), reason: '$g');
  });

  test('probe (no gate): gaps while the worker decides the slowest cascade',
      () async {
    print(await slowCascade(worker));
  });
}
