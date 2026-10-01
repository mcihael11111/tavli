import 'package:tavli_testkit/tavli_testkit.dart';
import 'package:test/test.dart';

void main() {
  group('measure', () {
    test('collects the requested number of samples', () {
      var calls = 0;
      final stats = measure(
        () => calls++,
        warmup: 5,
        minWarmup: Duration.zero,
        samples: 50,
      );
      expect(stats.samples, 50);
      expect(calls, 55);
    });

    test('percentiles are ordered p50 <= p95 <= max', () {
      final stats = measure(() {
        var x = 0;
        for (var i = 0; i < 1000; i++) {
          x += i;
        }
        if (x < 0) throw StateError('unreachable');
        return x;
      }, samples: 100);
      expect(stats.p50 <= stats.p95, isTrue);
      expect(stats.p95 <= stats.max, isTrue);
    });
  });

  test('minWarmup extends warm-up beyond the warmup call count', () {
    var calls = 0;
    measure(() {
      calls++;
      final sw = Stopwatch()..start();
      while (sw.elapsedMicroseconds < 1000) {}
      return calls;
    }, warmup: 1, minWarmup: const Duration(milliseconds: 20), samples: 5);
    expect(calls, greaterThan(1 + 5));
  });

  test('samples must be positive', () {
    expect(() => measure(() => null, samples: 0), throwsArgumentError);
  });

  test('body result is accepted (Object?)', () {
    final stats = measure(() => 42, samples: 3, minWarmup: Duration.zero);
    expect(stats.samples, 3);
  });

  test('fromNanos keeps sub-microsecond precision', () {
    final stats = BenchStats.fromNanos('n', const [400, 500, 600]);
    expect(stats.p50Ns, 500);
    expect(stats.toJson()['p50_ns'], 500);
    expect(stats.toJson()['p50_us'], 0);
    expect(stats.toString(), contains('0.5us'));
  });

  group('BenchStats.fromMicros', () {
    test('computes nearest-rank percentiles', () {
      final stats = BenchStats.fromMicros(
        'x',
        List<int>.generate(100, (i) => i + 1), // 1..100 us
      );
      expect(stats.p50, const Duration(microseconds: 50));
      expect(stats.p95, const Duration(microseconds: 95));
      expect(stats.max, const Duration(microseconds: 100));
      expect(stats.mean, const Duration(microseconds: 50)); // 50.5 truncated
    });

    test('rejects empty input', () {
      expect(() => BenchStats.fromMicros('x', const []), throwsArgumentError);
    });
  });

  group('budget', () {
    final stats = BenchStats.fromMicros('gen', List<int>.filled(10, 1500));

    test('within budget at scale 1', () {
      expect(stats.withinBudget(const Duration(milliseconds: 2), scale: 1),
          isTrue);
    });

    test('over budget at scale 1', () {
      expect(stats.withinBudget(const Duration(milliseconds: 1), scale: 1),
          isFalse);
    });

    test('scale relaxes the budget (slow CI runners)', () {
      expect(stats.withinBudget(const Duration(milliseconds: 1), scale: 2),
          isTrue);
    });

    test('benchScale defaults to 1.0 for a missing/invalid env value', () {
      expect(benchScale(const {}), 1.0);
      expect(benchScale(const {'TAVLI_BENCH_SCALE': 'abc'}), 1.0);
      expect(benchScale(const {'TAVLI_BENCH_SCALE': '2.5'}), 2.5);
      for (final bad in ['NaN', 'Infinity', '0', '-1']) {
        expect(benchScale({'TAVLI_BENCH_SCALE': bad}), 1.0, reason: bad);
      }
    });
  });

  test('benchSink retains the last body result', () {
    measure(() => 'last', warmup: 1, minWarmup: Duration.zero, samples: 1);
    expect(benchSink, 'last');
  });

  test('toJson exposes microsecond fields', () {
    final json = BenchStats.fromMicros('gen', const [10, 20, 30]).toJson();
    expect(json['name'], 'gen');
    expect(json['samples'], 3);
    expect(json['p50_us'], 20);
    expect(json['p95_us'], 30);
    expect(json['max_us'], 30);
    expect(json['mean_us'], 20);
  });
}
