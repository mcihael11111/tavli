/// The search's time budget and cancel flag (design spec SP2 §5).
library;

/// A unit of search work whose cost [SearchClock] learns, to stop before
/// a unit that would end past the deadline.
enum WorkUnit {
  /// One candidate scored at 0-ply.
  zeroPly,

  /// One opponent roll of a 1-ply value.
  onePlyRoll,

  /// One candidate scored at 2-ply.
  twoPly,
}

/// A deadline plus an optional cancel callback, polled between candidates,
/// between rolls and between reply evaluations.
///
/// **Predictive stop.** Before a [WorkUnit] the search asks
/// [wouldExpire], which also says yes when the unit's expected cost (an
/// exponential moving average of the units of that kind done so far,
/// weight [emaWeight] on the newest) would carry it past the deadline.
/// So the search stops early rather than late: it overruns only when a
/// unit costs more than its average (the first unit of a kind, with no
/// average yet, is never refused for its cost). Polls inside a unit
/// ([expired]) still stop it at the deadline itself.
///
/// Once [expired] or [wouldExpire] has returned true it stays true, so
/// every loop above the one that noticed unwinds without re-reading the
/// clock.
final class SearchClock {
  /// Starts the clock now.
  SearchClock(Duration budget, [this._cancelled])
      : _limitUs = budget.inMicroseconds {
    _watch.start();
  }

  /// The weight of the newest unit in the cost average.
  static const emaWeight = 0.3;

  final Stopwatch _watch = Stopwatch();
  final int _limitUs;
  final bool Function()? _cancelled;
  final _avgUs = List<double?>.filled(WorkUnit.values.length, null);
  bool _timedOut = false, _wasCancelled = false;

  /// The deadline passed (or was predicted to pass) before the search
  /// finished.
  bool get timedOut => _timedOut;

  /// The cancel callback fired before the search finished.
  bool get cancelled => _wasCancelled;

  /// Time since the clock started.
  int get elapsedUs => _watch.elapsedMicroseconds;

  /// The average cost of a [u] so far, in microseconds (null before the
  /// first).
  double? averageUs(WorkUnit u) => _avgUs[u.index];

  /// Whether the search must stop now: cancelled, or past the deadline.
  bool get expired {
    if (_timedOut || _wasCancelled) return true;
    if (_cancelled?.call() ?? false) return _wasCancelled = true;
    if (_watch.elapsedMicroseconds >= _limitUs) return _timedOut = true;
    return false;
  }

  /// Whether to skip a unit of [u]: [expired], or the unit's average cost
  /// would end it past the deadline.
  bool wouldExpire(WorkUnit u) {
    if (expired) return true;
    final avg = _avgUs[u.index];
    if (avg != null && _watch.elapsedMicroseconds + avg > _limitUs) {
      return _timedOut = true;
    }
    return false;
  }

  /// Runs [unit] as one [u] and records its cost.
  T measure<T>(WorkUnit u, T Function() unit) {
    final start = _watch.elapsedMicroseconds;
    final out = unit();
    final cost = (_watch.elapsedMicroseconds - start).toDouble();
    final avg = _avgUs[u.index];
    _avgUs[u.index] = avg == null ? cost : avg + emaWeight * (cost - avg);
    return out;
  }
}
