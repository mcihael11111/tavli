// Prints Gul Bara cascade timings (SP3 Task 1, design spec SP3 §5.4).
// ignore_for_file: avoid_print
library;

import 'package:tavli_core/tavli_core.dart';

import 'bench_suite.dart';

/// `tavli_bot`'s `slowestRealCascade` (the real-game full 1-1 cascade
/// with the most search work), copied so the core can time it.
const slowestRealCascade = GenerationFixture(
    Variant.gulBara,
    '{"direction":"same","one":[0,0,0,1,2,0,0,2,1,0,1,0,0,0,0,0,0,0,1,1,1,0,0,2,3,0],"two":[0,1,1,1,1,3,0,0,0,0,0,0,0,3,0,0,0,0,0,0,0,0,0,0,5,0],"pinnedOne":[],"pinnedTwo":[]}',
    Side.one,
    [1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6],
    20,
    cascade: true);

/// The worst cascade fixtures and sampled cascades, asserts off:
///
///     dart run --no-enable-asserts benchmark/cascade_timing.dart
void main() {
  String ms(int ns) => (ns / 1e6).toStringAsFixed(2);
  print('| cascade | n | p50 (ms) | p95 (ms) | max (ms) | states |');
  print('|---|---:|---:|---:|---:|---:|');
  for (final (name, f) in [
    ('worstFailingCascade', worstFailingCascade),
    ('worstCascade', worstCascade),
    ('slowestRealCascade', slowestRealCascade),
  ]) {
    final r = benchGeneration(f, samples: 20, warmup: 2);
    final s = r.stats;
    final states = f.run(f.position).searchedStates;
    print('| $name | ${s.samples} | ${ms(s.p50Ns)} | ${ms(s.p95Ns)} | '
        '${ms(s.maxNs)} | $states |');
  }
  for (final n in [17, 1500]) {
    final c = sampleCascades(n);
    for (final r in [c.all, c.failing]) {
      final s = r.stats;
      print('| ${s.name} ($n positions) | ${s.samples} | ${ms(s.p50Ns)} | '
          '${ms(s.p95Ns)} | ${ms(s.maxNs)} | ${r.note} |');
    }
  }
}
