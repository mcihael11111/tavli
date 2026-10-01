import 'dart:io' show Platform;

/// Receives every benchmark body result so the work cannot be optimized away.
// ignore: unused_element
Object? _benchSink;

/// Summary statistics for a micro-benchmark (nanosecond precision).
class BenchStats {
  final String name;
  final int samples;
  final int p50Ns;
  final int p95Ns;
  final int maxNs;
  final int meanNs;

  const BenchStats({
    required this.name,
    required this.samples,
    required this.p50Ns,
    required this.p95Ns,
    required this.maxNs,
    required this.meanNs,
  });

  /// Builds stats from raw nanosecond samples using nearest-rank percentiles.
  factory BenchStats.fromNanos(String name, List<int> nanos) {
    if (nanos.isEmpty) {
      throw ArgumentError.value(nanos, 'nanos', 'must not be empty');
    }
    final sorted = List<int>.of(nanos)..sort();
    int rank(double p) =>
        sorted[((p * sorted.length).ceil() - 1).clamp(0, sorted.length - 1)];
    final total = sorted.fold<int>(0, (a, b) => a + b);
    return BenchStats(
      name: name,
      samples: sorted.length,
      p50Ns: rank(0.50),
      p95Ns: rank(0.95),
      maxNs: sorted.last,
      meanNs: total ~/ sorted.length,
    );
  }

  /// Convenience for microsecond samples.
  factory BenchStats.fromMicros(String name, List<int> micros) =>
      BenchStats.fromNanos(name, [for (final m in micros) m * 1000]);

  Duration get p50 => Duration(microseconds: p50Ns ~/ 1000);
  Duration get p95 => Duration(microseconds: p95Ns ~/ 1000);
  Duration get max => Duration(microseconds: maxNs ~/ 1000);
  Duration get mean => Duration(microseconds: meanNs ~/ 1000);

  /// True when p95 is within [budget] multiplied by [scale].
  ///
  /// [scale] defaults to [benchScale] so slow CI runners can relax budgets
  /// via the `TAVLI_BENCH_SCALE` environment variable without code changes.
  bool withinBudget(Duration budget, {double? scale}) {
    final s = scale ?? benchScale();
    return p95Ns <= budget.inMicroseconds * 1000 * s;
  }

  Map<String, Object> toJson() => {
        'name': name,
        'samples': samples,
        'p50_us': p50Ns ~/ 1000,
        'p95_us': p95Ns ~/ 1000,
        'max_us': maxNs ~/ 1000,
        'mean_us': meanNs ~/ 1000,
        'p50_ns': p50Ns,
        'p95_ns': p95Ns,
        'max_ns': maxNs,
        'mean_ns': meanNs,
      };

  static String _us(int ns) => (ns / 1000).toStringAsFixed(1);

  @override
  String toString() => '$name: n=$samples p50=${_us(p50Ns)}us '
      'p95=${_us(p95Ns)}us max=${_us(maxNs)}us';
}

/// Runs [body] untimed until both [warmup] calls have completed and
/// [minWarmup] has elapsed, then [samples] times timed.
///
/// Slow bodies can pass `warmup: 0, minWarmup: Duration.zero`.
BenchStats measure(
  Object? Function() body, {
  String name = 'bench',
  int warmup = 20,
  Duration minWarmup = const Duration(milliseconds: 300),
  int samples = 200,
}) {
  if (samples <= 0) {
    throw ArgumentError.value(samples, 'samples', 'must be > 0');
  }
  final warm = Stopwatch()..start();
  var done = 0;
  while (done < warmup || warm.elapsed < minWarmup) {
    _benchSink = body();
    done++;
  }
  final nanosPerTick = 1000000000 / Stopwatch().frequency;
  final nanos = <int>[];
  final sw = Stopwatch();
  for (var i = 0; i < samples; i++) {
    sw
      ..reset()
      ..start();
    _benchSink = body();
    sw.stop();
    nanos.add((sw.elapsedTicks * nanosPerTick).round());
  }
  return BenchStats.fromNanos(name, nanos);
}

/// Budget multiplier from `TAVLI_BENCH_SCALE` (default 1.0).
double benchScale([Map<String, String>? env]) {
  final raw = (env ?? Platform.environment)['TAVLI_BENCH_SCALE'];
  final parsed = raw == null ? null : double.tryParse(raw);
  return (parsed == null || !parsed.isFinite || parsed <= 0) ? 1.0 : parsed;
}
