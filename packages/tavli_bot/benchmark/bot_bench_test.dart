// Prints every BenchStats, as the plan asks.
// ignore_for_file: avoid_print
@Tags(['bench'])
library;

import 'package:tavli_bot/tavli_bot.dart';
import 'package:tavli_testkit/tavli_testkit.dart' show benchScale;
import 'package:test/test.dart';

import 'bench_suite.dart';

/// Bot benchmarks with budgets (plan Task 9), run alone by
/// `dart test --tags bench --concurrency=1 benchmark` (tool/ci/check.sh).
///
/// `dart test` runs with asserts on, so each gate and cap is checked at
/// [assertAllowance] times its value (and `TAVLI_BENCH_SCALE`, for slow
/// CI runners). The report numbers come from `run_benchmarks.dart` with
/// asserts off, at 1x.
void main() {
  void check(BenchResult r) {
    print('${r.stats}${r.note.isEmpty ? '' : '  (${r.note})'}');
    if (r.budget == null) return;
    expect(r.within(factor: assertAllowance), isTrue,
        reason: '${r.stats.name}: p95 ${r.stats.p95} over '
            '${r.budget! * assertAllowance} (gate x$assertAllowance '
            'for asserts, x${benchScale()} TAVLI_BENCH_SCALE)');
  }

  setUpAll(warmUp);

  group('choosePlay p95 within the level gate on the worst fixtures', () {
    for (final level in BotLevel.values) {
      test(
          '${level.name} (${LevelProfile.of(level).budget.inMilliseconds} '
          'ms)', () {
        for (final f in playFixtures) {
          check(benchChoosePlay(f, level, level == BotLevel.expert ? 6 : 20));
        }
      });
    }
  });

  group('cascades', () {
    final cascades = sampledCascades();
    test('choosePlay p95 within 2x the level gate on sampled cascades', () {
      for (final level in BotLevel.values) {
        check(benchSampledCascades(cascades, level, BotRequestKind.choosePlay));
      }
    });

    test('analyze medium p95 within 2x the gate on sampled cascades', () {
      check(benchSampledCascades(
          cascades, BotLevel.medium, BotRequestKind.analyze));
    });

    test('worst cascades within the 2 s regression cap (Medium)', () {
      for (final kind in [BotRequestKind.choosePlay, BotRequestKind.analyze]) {
        benchWorstCascades(BotLevel.medium, kind, 1).forEach(check);
      }
    });
  });

  test('cube decisions at Medium within its gate', () {
    check(benchCube(BotRequestKind.offerDouble, 5));
    check(benchCube(BotRequestKind.takeDouble, 5));
  });

  test('analyze at Medium within its gate on the worst fixtures', () {
    for (final f in playFixtures) {
      check(benchAnalyze(f, 10));
    }
  });
}
