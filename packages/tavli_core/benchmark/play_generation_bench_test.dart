// Prints every BenchStats, as the plan asks.
// ignore_for_file: avoid_print
@Tags(['bench'])
library;

import 'package:tavli_core/tavli_core.dart';
import 'package:tavli_testkit/tavli_testkit.dart' show benchScale;
import 'package:test/test.dart';

import 'bench_suite.dart';

/// Benchmarks with budgets (plan Task 17), run alone by
/// `dart test --tags bench --concurrency=1 benchmark` (tool/ci/check.sh).
///
/// `dart test` runs with asserts on, so each budget is checked at
/// [assertAllowance] times its value (and `TAVLI_BENCH_SCALE`, for slow
/// CI runners). The report numbers come from `run_benchmarks.dart` with
/// asserts off.
void main() {
  void check(BenchResult r) {
    print('${r.stats}${r.note.isEmpty ? '' : '  (${r.note})'}');
    if (r.budget == null) return;
    expect(r.within(factor: assertAllowance), isTrue,
        reason: '${r.stats.name}: p95 ${r.stats.p95} over '
            '${r.budget! * assertAllowance} (budget x$assertAllowance '
            'for asserts, x${benchScale()} TAVLI_BENCH_SCALE)');
  }

  const warmup = Duration(milliseconds: 200);

  group('generatePlays p95 <= 2 ms on the worst fixture', () {
    for (final f in generationFixtures) {
      test(f.label, () {
        check(benchGeneration(f, samples: 100, minWarmup: warmup));
      });
    }
  });

  test('gulBara worst cascades within loose regression caps (1 s, 2 s)', () {
    check(benchGeneration(worstCascade, samples: 5, minWarmup: warmup));
    check(benchGeneration(worstFailingCascade,
        samples: 3, warmup: 1, minWarmup: Duration.zero));
  });

  test('gulBara sampled cascades p95 <= 50 ms (all and failing)', () {
    final r = sampleCascades(100);
    check(r.all);
    check(r.failing);
  });

  group('reduce StepAction p95 <= 50 us on a mid-game state', () {
    for (final v in Variant.values) {
      test(v.name, () {
        check(benchReducerStep(v, samples: 500, minWarmup: warmup));
      });
    }
  });
}
