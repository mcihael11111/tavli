/// The worker protocol (design spec SP2 §8): plain, immutable data that
/// crosses isolates through a `SendPort`. No `GameState`, no trees.
library;

import 'package:tavli_core/tavli_core.dart';

import '../level/bot_level.dart';
import '../teach/analysis_types.dart';
import '../util/collection_eq.dart';

/// What a [BotRequest] asks for.
enum BotRequestKind { choosePlay, offerDouble, takeDouble, analyze }

/// One question for the bot. Every field is immutable, and the lists are
/// unmodifiable copies, so a request can be sent and compared by value.
final class BotRequest {
  /// Matches the [BotReply.id] of the answer.
  final int id;
  final BotRequestKind kind;
  final Variant variant;
  final Position position;

  /// The side the bot plays (to move, to double or to answer a double).
  final Side side;

  /// `[a, b]`, `[d, d, d, d]`, or a cascade queue when [cascade].
  final List<int> dice;

  /// Whether [dice] is a Gul Bara cascade queue.
  final bool cascade;

  /// The turn context before the first step.
  final TurnContext context;
  final CubeState cube;

  /// Whether this is the match's Crawford game, where no one may double:
  /// the bot never offers then (the core enforces it too).
  final bool crawfordGame;
  final BotLevel level;

  /// Seeds the request's `Random`: equal requests give equal replies.
  final int seed;

  /// Overrides the level's budget when set.
  final Duration? budget;

  /// [BotRequestKind.analyze]: the steps already taken this turn.
  final List<Step> steps;

  /// The id of an older request this one replaces; the worker drops it.
  final int? supersedes;

  BotRequest({
    required this.id,
    required this.kind,
    required this.variant,
    required this.position,
    required this.side,
    required List<int> dice,
    this.cascade = false,
    required this.context,
    required this.cube,
    this.crawfordGame = false,
    required this.level,
    required this.seed,
    this.budget,
    List<Step> steps = const [],
    this.supersedes,
  })  : dice = List.unmodifiable(dice),
        steps = List.unmodifiable(steps);

  @override
  bool operator ==(Object other) =>
      other is BotRequest &&
      other.id == id &&
      other.kind == kind &&
      other.variant == variant &&
      other.side == side &&
      other.cascade == cascade &&
      other.level == level &&
      other.seed == seed &&
      other.budget == budget &&
      other.supersedes == supersedes &&
      other.cube == cube &&
      other.crawfordGame == crawfordGame &&
      other.context == context &&
      other.position == position &&
      listEq(other.dice, dice) &&
      listEq(other.steps, steps);

  @override
  int get hashCode => Object.hash(
        id,
        kind,
        variant,
        position,
        side,
        Object.hashAll(dice),
        cascade,
        context,
        cube,
        crawfordGame,
        level,
        seed,
        budget,
        Object.hashAll(steps),
        supersedes,
      );

  @override
  String toString() => 'BotRequest(#$id ${kind.name} ${variant.name} '
      '${side.name} $dice${cascade ? ' cascade' : ''} ${level.name})';
}

/// What answering a request cost.
final class BotStats {
  /// Positions evaluated.
  final int evaluated;

  /// The deepest ply completed (0, 1 or 2).
  final int depthReached;
  final int elapsedUs;

  /// The budget ran out before the search finished.
  final bool timedOut;

  const BotStats({
    required this.evaluated,
    required this.depthReached,
    required this.elapsedUs,
    required this.timedOut,
  });

  @override
  bool operator ==(Object other) =>
      other is BotStats &&
      other.evaluated == evaluated &&
      other.depthReached == depthReached &&
      other.elapsedUs == elapsedUs &&
      other.timedOut == timedOut;

  @override
  int get hashCode => Object.hash(evaluated, depthReached, elapsedUs, timedOut);

  @override
  String toString() => 'BotStats($evaluated evals, depth $depthReached, '
      '${elapsedUs}us${timedOut ? ', timed out' : ''})';
}

/// The answer to the [BotRequest] with the same [id].
sealed class BotReply {
  const BotReply({required this.id, required this.stats});

  final int id;
  final BotStats stats;

  bool _sameHead(BotReply o) => o.id == id && o.stats == stats;
}

/// [BotRequestKind.choosePlay]: the steps to submit (empty if no play).
final class PlayReply extends BotReply {
  PlayReply(
      {required super.id, required super.stats, required List<Step> steps})
      : steps = List.unmodifiable(steps);

  final List<Step> steps;

  @override
  bool operator ==(Object other) =>
      other is PlayReply && _sameHead(other) && listEq(other.steps, steps);

  @override
  int get hashCode => Object.hash(PlayReply, id, stats, Object.hashAll(steps));

  @override
  String toString() => 'PlayReply(#$id $steps)';
}

/// [BotRequestKind.offerDouble] / [BotRequestKind.takeDouble]: yes or no.
final class DecisionReply extends BotReply {
  const DecisionReply(
      {required super.id, required super.stats, required this.yes});

  final bool yes;

  @override
  bool operator ==(Object other) =>
      other is DecisionReply && _sameHead(other) && other.yes == yes;

  @override
  int get hashCode => Object.hash(DecisionReply, id, stats, yes);

  @override
  String toString() => 'DecisionReply(#$id $yes)';
}

/// [BotRequestKind.analyze]: the teaching analysis.
final class AnalysisReply extends BotReply {
  const AnalysisReply(
      {required super.id, required super.stats, required this.analysis});

  final TurnAnalysis analysis;

  @override
  bool operator ==(Object other) =>
      other is AnalysisReply && _sameHead(other) && other.analysis == analysis;

  @override
  int get hashCode => Object.hash(AnalysisReply, id, stats, analysis);

  @override
  String toString() => 'AnalysisReply(#$id $analysis)';
}

/// The request failed; the worker stays alive.
final class ErrorReply extends BotReply {
  const ErrorReply(
      {required super.id, required super.stats, required this.message});

  final String message;

  @override
  bool operator ==(Object other) =>
      other is ErrorReply && _sameHead(other) && other.message == message;

  @override
  int get hashCode => Object.hash(ErrorReply, id, stats, message);

  @override
  String toString() => 'ErrorReply(#$id $message)';
}
