/// The search result and the noisy pick among candidates (design spec SP2
/// §5 step 7).
library;

import 'dart:math';

import 'package:tavli_core/tavli_core.dart';

import '../level/bot_level.dart';
import '../worker/protocol.dart';

/// The play the search chose.
final class SearchResult {
  const SearchResult(this.play, this.equity, this.stats);

  /// The chosen play; `steps` is empty when the side has no legal play.
  final Play play;

  /// The chosen play's value for the mover, without noise, at
  /// `stats.depthReached`. NaN when nothing was evaluated (no play, or a
  /// single legal play).
  final double equity;

  final BotStats stats;

  @override
  String toString() => 'SearchResult($play, $equity, $stats)';
}

/// A candidate: an index into the caller's play list and its value.
typedef Candidate = (int index, double value);

/// Picks a candidate under [profile]'s noise and top fraction:
/// - rank the candidates by value (ties: lower index first);
/// - keep the best `ceil(n · topFraction)`, at least one;
/// - add uniform noise `±noise` to each kept value, drawn from [rng] in
///   rank order, and take the max (ties: better rank).
///
/// The top fraction is applied to the true values, so it bounds how far
/// down the ranking a pick can go; the noise only perturbs the order
/// within it (no weighted random, plan Task 5). Returns the chosen
/// candidate. [pool] must not be empty.
Candidate pickCandidate(
    List<Candidate> pool, LevelProfile profile, Random rng) {
  final ranked = [...pool]..sort((a, b) {
      final c = b.$2.compareTo(a.$2);
      return c != 0 ? c : a.$1.compareTo(b.$1);
    });
  final keep = max(1, (ranked.length * profile.topFraction - 1e-9).ceil());
  var best = ranked.first;
  var bestNoisy = double.negativeInfinity;
  for (final c in ranked.take(keep)) {
    final noisy = profile.noise > 0
        ? c.$2 + (rng.nextDouble() * 2 - 1) * profile.noise
        : c.$2;
    if (noisy > bestNoisy) {
      best = c;
      bestNoisy = noisy;
    }
  }
  return best;
}

/// The dice as `generatePlays` takes them: a double given as `[d, d]`
/// becomes `[d, d, d, d]`.
List<int> normalDice(List<int> dice) => dice.length == 2 && dice[0] == dice[1]
    ? [for (var i = 0; i < 4; i++) dice[0]]
    : dice;
