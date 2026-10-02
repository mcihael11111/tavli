// Prints the benchmark table for the SP2 report.
// ignore_for_file: avoid_print
library;

import 'dart:io';

import 'package:tavli_bot/tavli_bot.dart';

import 'bench_suite.dart';
import 'worker_probe.dart';

/// Bot benchmarks with asserts off (plan Task 9): the numbers for the SP2
/// report.
///
///     dart run --no-enable-asserts benchmark/run_benchmarks.dart
///
/// Gates (design §1) are checked at 1x (`TAVLI_BENCH_SCALE` still
/// applies); the exit code is 1 if any is missed. Regression caps are
/// checked the same way. Then prints the main-isolate timer gaps while
/// a worker isolate decides (report only). `--scan` instead re-finds the
/// fixtures and prints `fixtures.dart` source.
Future<void> main(List<String> args) async {
  var asserts = false;
  assert(asserts = true);
  if (args.contains('--scan')) {
    stdout.write(scanFixtures());
    return;
  }
  if (asserts) {
    stderr.writeln('warning: asserts are on; run with --no-enable-asserts '
        'for report numbers');
  }
  warmUp();
  final cascades = sampledCascades();
  final results = <BenchResult>[
    for (final level in BotLevel.values)
      for (final f in playFixtures)
        benchChoosePlay(f, level, level == BotLevel.expert ? 20 : 50),
    for (final level in BotLevel.values)
      benchSampledCascades(cascades, level, BotRequestKind.choosePlay),
    for (final level in BotLevel.values) benchSmallBudget(level, 50),
    for (final level in [BotLevel.medium, BotLevel.expert])
      ...benchWorstCascades(level, BotRequestKind.choosePlay, 3),
    benchCube(BotRequestKind.offerDouble, 20),
    benchCube(BotRequestKind.takeDouble, 20),
    for (final f in playFixtures) benchAnalyze(f, 30),
    benchSampledCascades(cascades, BotLevel.medium, BotRequestKind.analyze),
    ...benchWorstCascades(BotLevel.medium, BotRequestKind.analyze, 3),
  ];
  var failed = 0;
  print('| benchmark | n | p50 (ms) | p95 (ms) | max (ms) | gate (ms) | ok |');
  print('|---|---:|---:|---:|---:|---:|:-:|');
  for (final r in results) {
    final s = r.stats;
    final ok = r.within();
    if (!ok) failed++;
    String ms(int ns) => (ns / 1e6).toStringAsFixed(2);
    final gate = r.budget == null
        ? r.note
        : '${_ms(r.budget!)}${r.note.isEmpty ? '' : ' (${r.note})'}';
    print('| ${s.name} | ${s.samples} | ${ms(s.p50Ns)} | ${ms(s.p95Ns)} | '
        '${ms(s.maxNs)} | $gate | ${r.budget == null ? '-' : ok ? 'yes' : 'NO'} |');
  }
  final worker = await BotWorker.spawn();
  await worker.warm();
  print('');
  print(await hardBackToBack(worker));
  print(await slowCascade(worker, runs: 3));
  await worker.dispose();
  if (failed > 0) {
    print('$failed over their gate or cap');
    exitCode = 1;
  }
}

/// [d] in ms: whole, or to 2 decimals.
String _ms(Duration d) => d.inMicroseconds % 1000 == 0
    ? '${d.inMilliseconds}'
    : (d.inMicroseconds / 1000).toStringAsFixed(2);
