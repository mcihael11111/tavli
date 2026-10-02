/// The time-budgeted search: 0-ply, 1-ply on the top K with iterative
/// widening, Expert 2-ply, noisy selection (design spec SP2 §5).
library;

import 'dart:math';

import 'package:tavli_core/tavli_core.dart';

import '../eval/eval_dispatch.dart';
import '../eval/evaluator.dart';
import '../level/bot_level.dart';
import '../worker/protocol.dart';
import 'budget.dart';
import 'cascade_search.dart';
import 'ply.dart';
import 'selection.dart';

export 'selection.dart' show SearchResult;

/// Chooses [side]'s play of [dice] in [position].
///
/// - [dice]: `[a, b]`, `[d, d, d, d]` (or `[d, d]`), or with [cascade] a
///   Gul Bara cascade queue, searched by [searchCascade].
/// - [evaluator]: defaults to [evaluatorFor] of [rules].
/// - [budget]: defaults to the profile's budget (its cascade budget for a
///   cascade). The clock and [cancelled] are polled between candidates,
///   rolls and reply evaluations; on expiry the answer is the best
///   candidate of the deepest level completed, and `stats.timedOut` is
///   set (a cancel stops the same way without setting it).
///
/// Levels:
/// 0. every play by its 0-ply value ([PlyScorer.value]). The first play
///    is always scored, so even a zero budget yields an evaluated play.
/// 1. (depth ≥ 1) [PlyScorer.onePly] on the top `k` plays by 0-ply; while
///    budget remains, `k` doubles up to `kMax`. Level 1 counts as reached
///    once the first `k` are done; every candidate done by then is in the
///    pool.
/// 2. (Expert) [PlyScorer.twoPly] on the top two 1-ply candidates; kept
///    only if both finish.
///
/// The pool of the deepest level reached goes to [pickCandidate]. A
/// single legal play (or none) is returned without any evaluation.
SearchResult choosePlay({
  required Position position,
  required Side side,
  required List<int> dice,
  required bool cascade,
  required TurnContext context,
  required VariantRules rules,
  required LevelProfile profile,
  required Random rng,
  Evaluator? evaluator,
  Duration? budget,
  bool Function()? cancelled,
}) {
  final clock = SearchClock(
      budget ?? (cascade ? profile.cascadeBudget : profile.budget), cancelled);
  final scorer = PlyScorer(evaluator ?? evaluatorFor(rules), rules, clock);
  if (cascade) {
    return searchCascade(position, side, dice, context, profile, rng, scorer);
  }
  final plays =
      generatePlays(position, side, normalDice(dice), rules, context).plays();
  if (plays.length <= 1) {
    final play = plays.isEmpty ? Play(position, const []) : plays.first;
    return SearchResult(play, double.nan, statsOf(scorer, 0));
  }

  // Level 0.
  final zero = <double>[];
  for (var i = 0; i < plays.length; i++) {
    if (i > 0 && clock.expired) break;
    zero.add(scorer.value(plays[i].finalPosition, side));
  }
  var pool = [for (var i = 0; i < zero.length; i++) (i, zero[i])];
  var depth = 0;

  if (profile.depth >= 1 && zero.length == plays.length) {
    final one = _onePlyLevel(plays, zero, side, profile, scorer);
    if (one != null) {
      pool = one;
      depth = 1;
      if (profile.expertTwoPly) {
        final two = _twoPlyLevel(plays, one, side, scorer);
        if (two != null) {
          pool = two;
          depth = 2;
        }
      }
    }
  }

  final (i, v) = pickCandidate(pool, profile, rng);
  return SearchResult(plays[i], v, statsOf(scorer, depth));
}

/// The stats of a search by [scorer] that reached [depth].
BotStats statsOf(PlyScorer scorer, int depth) => BotStats(
      evaluated: scorer.evaluated,
      depthReached: depth,
      elapsedUs: scorer.clock.elapsedUs,
      timedOut: scorer.clock.timedOut,
    );

/// Level 1 with iterative widening; null if the first `k` did not finish.
List<Candidate>? _onePlyLevel(List<Play> plays, List<double> zero, Side side,
    LevelProfile profile, PlyScorer scorer) {
  final n = plays.length;
  final order = List.generate(n, (i) => i)
    ..sort((a, b) {
      final c = zero[b].compareTo(zero[a]);
      return c != 0 ? c : a.compareTo(b);
    });
  final kMax = min(max(profile.k, profile.kMax), n);
  final out = <Candidate>[];
  var k = min(max(profile.k, 1), n);
  var reached = false;
  while (true) {
    for (var j = out.length; j < k; j++) {
      if (scorer.clock.expired) return reached ? out : null;
      final v = scorer.onePly(plays[order[j]].finalPosition, side);
      if (v == null) return reached ? out : null;
      out.add((order[j], v));
    }
    reached = true;
    if (k >= kMax) return out;
    k = min(2 * k, kMax);
  }
}

/// Level 2 on the top two of [one]; null unless both finish.
List<Candidate>? _twoPlyLevel(
    List<Play> plays, List<Candidate> one, Side side, PlyScorer scorer) {
  if (one.length < 2) return null;
  final top = [...one]..sort((a, b) {
      final c = b.$2.compareTo(a.$2);
      return c != 0 ? c : a.$1.compareTo(b.$1);
    });
  final out = <Candidate>[];
  for (final (i, _) in top.take(2)) {
    if (scorer.clock.expired) return null;
    final v = scorer.twoPly(plays[i].finalPosition, side);
    if (v == null) return null;
    out.add((i, v));
  }
  return out;
}
