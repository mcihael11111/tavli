/// Cascade turns (Gul Bara, D15-D16): sampled and greedy completions,
/// scored at 0-ply (design spec SP2 §5, "Cascade turns").
library;

import 'dart:math';

import 'package:tavli_core/tavli_core.dart';

import '../level/bot_level.dart';
import 'budget.dart';
import 'ply.dart';
import 'selection.dart';

/// [side]'s play of the cascade [queue] from [position].
///
/// A cascade tree can hold millions of finals, so it is never enumerated:
/// - one [CascadeWalker.greedyCompletion] on the 0-ply value (always run:
///   it guarantees a complete play);
/// - up to `profile.cascadeSamples` [CascadeWalker.sampleCompletions],
///   stopped by the clock (one walk on a bad cascade can expand
///   thousands of states);
/// - the distinct finals scored at 0-ply (the greedy one always, the rest
///   while the clock allows) and picked by [pickCandidate]. No 1-ply.
///
/// Returns an empty play when the queue has no legal step.
SearchResult searchCascade(
  Position position,
  Side side,
  List<int> queue,
  TurnContext context,
  LevelProfile profile,
  Random rng,
  PlyScorer scorer,
) {
  final tree = generateCascade(position, side, queue, scorer.rules, context);
  if (!tree.hasPlay) {
    return SearchResult(
        Play(position, const []), double.nan, statsOf(scorer, 0));
  }
  final walker = CascadeWalker(tree);
  final clock = scorer.clock;
  // The greedy walk scores its final as a child: keep its scores so the
  // final is not evaluated twice.
  final scored = <BoardView, double>{};
  final greedy =
      walker.greedyCompletion((p) => scored[p] = scorer.value(p, side));
  final plays = [greedy];
  for (final s in walker.sampleCompletions(profile.cascadeSamples, rng,
      stop: () => clock.expired)) {
    if (s.finalPosition != greedy.finalPosition) plays.add(s);
  }
  final pool = <Candidate>[];
  for (var i = 0; i < plays.length; i++) {
    if (i > 0 && clock.wouldExpire(WorkUnit.zeroPly)) break;
    final f = plays[i].finalPosition;
    pool.add((
      i,
      (i == 0 ? scored[f] : null) ??
          clock.measure(WorkUnit.zeroPly, () => scorer.value(f, side))
    ));
  }
  final (i, v) = pickCandidate(pool, profile, rng);
  return SearchResult(plays[i], v, statsOf(scorer, 0));
}
