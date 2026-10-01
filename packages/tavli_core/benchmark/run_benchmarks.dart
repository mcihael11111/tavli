// Prints the benchmark table for the SP1 report.
// ignore_for_file: avoid_print
library;

import 'dart:io';

import 'package:tavli_core/tavli_core.dart';

import 'bench_suite.dart';

/// Benchmarks with asserts off (plan Task 17): the numbers for reports.
///
///     dart run --no-enable-asserts benchmark/run_benchmarks.dart
///
/// Budgets are checked at 1x (`TAVLI_BENCH_SCALE` still applies); the
/// exit code is 1 if any is exceeded. `--scan` instead re-finds the
/// worst-case fixtures and prints `bench_fixtures.dart` source.
void main(List<String> args) {
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
  final results = <BenchResult>[
    for (final f in generationFixtures) benchGeneration(f),
    benchGeneration(worstCascade, samples: 50),
    benchGeneration(worstFailingCascade,
        samples: 20, warmup: 2, minWarmup: Duration.zero),
    for (final v in Variant.values) benchReducerStep(v),
  ];
  final cascades = sampleCascades(1500);
  results.addAll([cascades.all, cascades.failing]);
  var failed = 0;
  print('| benchmark | n | p50 (us) | p95 (us) | max (us) | budget | ok |');
  print('|---|---:|---:|---:|---:|---:|:-:|');
  for (final r in results) {
    final s = r.stats;
    final ok = r.within();
    if (!ok) failed++;
    String us(int ns) => (ns / 1000).toStringAsFixed(1);
    final budget = r.budget == null
        ? r.note
        : '${r.budget!.inMicroseconds} us${r.note.isEmpty ? '' : ' (${r.note})'}';
    print('| ${s.name} | ${s.samples} | ${us(s.p50Ns)} | ${us(s.p95Ns)} | '
        '${us(s.maxNs)} | $budget | ${r.budget == null ? '-' : ok ? 'yes' : 'NO'} |');
  }
  if (failed > 0) {
    print('$failed over budget');
    exitCode = 1;
  }
}
