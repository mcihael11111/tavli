/// `Bot.decide`: the pure request → reply function (design spec SP2 §8).
/// The worker isolate hosts it; tests, tournaments and the server call it
/// in-process.
library;

import 'dart:math';

import 'package:tavli_core/tavli_core.dart';

import 'cube/cube_policy.dart';
import 'eval/eval_dispatch.dart';
import 'eval/evaluator.dart';
import 'level/bot_level.dart';
import 'search/search.dart';
import 'teach/analysis.dart';
import 'worker/protocol.dart';

/// The bot's single entry point.
abstract final class Bot {
  /// Answers [request]. Pure: equal requests give equal replies (up to
  /// `stats.elapsedUs`, and the search depth reached within the budget).
  /// Never throws: an invalid request, or any error while answering, is
  /// an [ErrorReply] with a message.
  ///
  /// Dispatch by [BotRequest.kind]:
  /// - `choosePlay` → [PlayReply] from [choosePlay]: steps that replay
  ///   to a legal complete play (empty when no step is legal);
  /// - `offerDouble` / `takeDouble` → [DecisionReply] from [shouldOffer]
  ///   / [shouldTake];
  /// - `analyze` → [AnalysisReply] from [analyzeTurn] at the request's
  ///   level.
  ///
  /// The request's `Random` is `Random(seed)`. Its budget (the request's
  /// if set, else the level's, the cascade budget for a cascade) bounds
  /// the whole call: the search gets [searchBudget] of it.
  /// `stats.elapsedUs` covers the whole call.
  /// See [validate] for what a request must satisfy.
  static BotReply decide(BotRequest request) {
    final watch = Stopwatch()..start();
    try {
      final problem = validate(request);
      if (problem != null) {
        return ErrorReply(
            id: request.id, stats: _stats(watch), message: problem);
      }
      return _answer(request, watch);
    } catch (e) {
      return ErrorReply(
          id: request.id,
          stats: _stats(watch),
          message: 'error: ${e.runtimeType}: $e');
    }
  }

  /// Why [r] cannot be answered, or null if it can. Decide knows nothing
  /// of the game's phase; it checks only that the request is
  /// self-consistent:
  /// - the position's direction is the variant's, and the game is not
  ///   over ([endsGame] for neither side);
  /// - `choosePlay` / `analyze`: with `cascade`, the variant cascades and
  ///   the dice are a queue of 1..24 dice in 1..6; without, the dice are
  ///   `[a, b]` (a double as `[d, d]` or `[d, d, d, d]`) in 1..6;
  /// - `offerDouble` / `takeDouble`: no dice and no cascade (the cube is
  ///   handled before rolling); `takeDouble` needs the cube enabled and
  ///   offered by the bot's opponent;
  /// - `steps` only for `analyze`, and a budget, when set, ≥ 0.
  ///
  /// Whether the steps are a legal prefix is checked by the analysis.
  static String? validate(BotRequest r) {
    final rules = r.variant.rules;
    final p = r.position;
    if (p.direction != rules.direction) {
      return 'position direction ${p.direction.name} is not '
          '${r.variant.name}\'s ${rules.direction.name}';
    }
    for (final s in Side.values) {
      if (endsGame(p, rules, s)) return 'game over: ${s.name} has won';
    }
    final b = r.budget;
    if (b != null && b.isNegative) return 'negative budget $b';
    if (r.kind != BotRequestKind.analyze && r.steps.isNotEmpty) {
      return 'steps are only for analyze';
    }
    switch (r.kind) {
      case BotRequestKind.choosePlay || BotRequestKind.analyze:
        final d = r.dice;
        if (d.any((v) => v < 1 || v > 6)) return 'dice $d outside 1..6';
        if (r.cascade) {
          if (rules.cascade == null) {
            return '${r.variant.name} has no cascades';
          }
          if (d.isEmpty || d.length > 24) return 'cascade queue $d';
        } else {
          final ok =
              d.length == 2 || d.length == 4 && d.every((v) => v == d.first);
          if (!ok) return 'dice $d are not [a, b] or [d x4]';
        }
      case BotRequestKind.offerDouble || BotRequestKind.takeDouble:
        if (r.dice.isNotEmpty || r.cascade) {
          return 'a cube decision takes no dice';
        }
        if (r.kind == BotRequestKind.takeDouble &&
            (!r.cube.enabled || r.cube.offeredBy != r.side.opponent)) {
          return 'no double offered to ${r.side.name}';
        }
    }
    return null;
  }

  /// What the search may spend of a request's [budget]: all but a
  /// reserve of 5 % (at least 1 ms, at most all of it). A search polls
  /// its clock between units of work, so it overruns its deadline by the
  /// last unit (up to about 1 ms on the worst fixtures, asserts off, plan
  /// Task 9); the reserve keeps the whole call within [budget].
  static Duration searchBudget(Duration budget) {
    final reserveUs = max(1000, budget.inMicroseconds ~/ 20);
    return Duration(microseconds: max(0, budget.inMicroseconds - reserveUs));
  }

  static BotReply _answer(BotRequest r, Stopwatch watch) {
    final rules = r.variant.rules;
    final rng = Random(r.seed);
    final eval = _CountingEvaluator(evaluatorFor(rules));
    final profile = LevelProfile.of(r.level);
    final budget = searchBudget(
        r.budget ?? (r.cascade ? profile.cascadeBudget : profile.budget));
    switch (r.kind) {
      case BotRequestKind.choosePlay:
        final res = choosePlay(
          position: r.position,
          side: r.side,
          dice: r.dice,
          cascade: r.cascade,
          context: r.context,
          rules: rules,
          profile: profile,
          rng: rng,
          evaluator: eval,
          budget: budget,
        );
        return PlayReply(
            id: r.id,
            stats: _stats(watch,
                evaluated: res.stats.evaluated,
                depth: res.stats.depthReached,
                timedOut: res.stats.timedOut),
            steps: res.play.steps);
      case BotRequestKind.offerDouble || BotRequestKind.takeDouble:
        final yes = r.kind == BotRequestKind.offerDouble
            ? shouldOffer(
                position: r.position,
                side: r.side,
                rules: rules,
                cube: r.cube,
                level: r.level,
                rng: rng,
                budget: budget,
                evaluator: eval,
                crawfordGame: r.crawfordGame)
            : shouldTake(
                position: r.position,
                side: r.side,
                rules: rules,
                cube: r.cube,
                level: r.level,
                rng: rng,
                budget: budget,
                evaluator: eval);
        return DecisionReply(
            id: r.id, stats: _stats(watch, evaluated: eval.calls), yes: yes);
      case BotRequestKind.analyze:
        final a = analyzeTurn(
          position: r.position,
          side: r.side,
          dice: r.dice,
          cascade: r.cascade,
          context: r.context,
          rules: rules,
          steps: r.steps,
          profile: profile,
          rng: rng,
          budget: budget,
          evaluator: eval,
        );
        // The analysis does not report its depth: it is 1-ply unless the
        // budget ran out, which is the best signal for both fields.
        final over = watch.elapsedMicroseconds >= budget.inMicroseconds;
        return AnalysisReply(
            id: r.id,
            stats: _stats(watch,
                evaluated: eval.calls,
                depth: profile.depth >= 1 && !over ? 1 : 0,
                timedOut: over),
            analysis: a);
    }
  }

  static BotStats _stats(Stopwatch watch,
          {int evaluated = 0, int depth = 0, bool timedOut = false}) =>
      BotStats(
          evaluated: evaluated,
          depthReached: depth,
          elapsedUs: watch.elapsedMicroseconds,
          timedOut: timedOut);
}

/// Counts the evaluations of a request.
final class _CountingEvaluator implements Evaluator {
  _CountingEvaluator(this._inner);

  final Evaluator _inner;
  int calls = 0;

  @override
  EvalResult evaluate(BoardView p, Side me, VariantRules r) {
    calls++;
    return _inner.evaluate(p, me, r);
  }
}
