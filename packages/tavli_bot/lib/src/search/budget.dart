/// The search's time budget and cancel flag (design spec SP2 §5).
library;

/// A deadline plus an optional cancel callback, polled between candidates,
/// between rolls and between reply evaluations.
///
/// Once [expired] has returned true it stays true, so every loop above the
/// one that noticed unwinds without re-reading the clock.
final class SearchClock {
  /// Starts the clock now.
  SearchClock(Duration budget, [this._cancelled])
      : _limitUs = budget.inMicroseconds {
    _watch.start();
  }

  final Stopwatch _watch = Stopwatch();
  final int _limitUs;
  final bool Function()? _cancelled;
  bool _timedOut = false, _wasCancelled = false;

  /// The deadline passed before the search finished.
  bool get timedOut => _timedOut;

  /// The cancel callback fired before the search finished.
  bool get cancelled => _wasCancelled;

  /// Time since the clock started.
  int get elapsedUs => _watch.elapsedMicroseconds;

  /// Whether the search must stop now: cancelled, or past the deadline.
  bool get expired {
    if (_timedOut || _wasCancelled) return true;
    if (_cancelled?.call() ?? false) return _wasCancelled = true;
    if (_watch.elapsedMicroseconds >= _limitUs) return _timedOut = true;
    return false;
  }
}
