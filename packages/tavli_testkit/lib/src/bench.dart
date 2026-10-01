import 'dart:io' show Platform;

/// Summary statistics for a micro-benchmark.
class BenchStats {
  final String name;
  final int samples;
  final Duration p50;
  final Duration p95;
  final Duration max;
  final Duration mean;

  const BenchStats({
    required this.name,
    required this.samples,
    required this.p50,
    required this.p95,
    required this.max,
    required this.mean,
  });

  /// Builds stats from raw microsecond samples using nearest-rank percentiles.
  factory BenchStats.fromMicros(String name, List<int> micros) {
    if (micros.isEmpty) {
      throw ArgumentError.value(micros, 'micros', 'must not be empty');
    }
    final sorted = List<int>.of(micros)..sort();
    int rank(double p) =>
        sorted[((p * sorted.length).ceil() - 1).clamp(0, sorted.length - 1)];
    final total = sorted.fold<int>(0, (a, b) => a + b);
    return BenchStats(
      name: name,
      samples: sorted.length,
      p50: Duration(microseconds: rank(0.50)),
      p95: Duration(microseconds: rank(0.95)),
      max: Duration(microseconds: sorted.last),
      mean: Duration(microseconds: total ~/ sorted.length),
    );
  }

  /// True when p95 is within [budget] multiplied by [scale].
  ///
  /// [scale] defaults to [benchScale] so slow CI runners can relax budgets
  /// via the `TAVLI_BENCH_SCALE` environment variable without code changes.
  bool withinBudget(Duration budget, {double? scale}) {
    final s = scale ?? benchScale();
    return p95.inMicroseconds <= budget.inMicroseconds * s;
  }

  Map<String, Object> toJson() => {
        'name': name,
        'samples': samples,
        'p50_us': p50.inMicroseconds,
        'p95_us': p95.inMicroseconds,
        'max_us': max.inMicroseconds,
        'mean_us': mean.inMicroseconds,
      };

  @override
  String toString() => '$name: n=$samples p50=${p50.inMicroseconds}us '
      'p95=${p95.inMicroseconds}us max=${max.inMicroseconds}us';
}

/// Runs [body] [warmup] times untimed, then [samples] times timed.
BenchStats measure(
  void Function() body, {
  String name = 'bench',
  int warmup = 20,
  int samples = 200,
}) {
  for (var i = 0; i < warmup; i++) {
    body();
  }
  final micros = <int>[];
  final sw = Stopwatch();
  for (var i = 0; i < samples; i++) {
    sw
      ..reset()
      ..start();
    body();
    sw.stop();
    micros.add(sw.elapsedMicroseconds);
  }
  return BenchStats.fromMicros(name, micros);
}

/// Budget multiplier from `TAVLI_BENCH_SCALE` (default 1.0).
double benchScale([Map<String, String>? env]) {
  final raw = (env ?? Platform.environment)['TAVLI_BENCH_SCALE'];
  final parsed = raw == null ? null : double.tryParse(raw);
  return (parsed == null || parsed <= 0) ? 1.0 : parsed;
}
