/// Builds a [BotRequest] from a core [GameState] (SP3 plan Task 2), so the
/// app never assembles position, dice, context and cube by hand.
library;

import 'package:tavli_core/tavli_core.dart';

import '../level/bot_level.dart';
import 'protocol.dart';

/// Request builders.
abstract final class BotRequests {
  /// The [kind] request for the side the question is for in [s]:
  ///
  /// - `choosePlay` and `analyze` need `GamePhase.moving` and ask about the
  ///   side to move. Both are posed from the turn start ([GameState.
  ///   turnStart], its dice, cascade flag and turn-start context), so a
  ///   cascade or a Gul Bara remainder turn is asked as the queue it is.
  ///   `analyze` carries the steps taken so far ([GameState.steps]); a
  ///   `choosePlay` reply is a whole play from the turn start, to submit
  ///   with no steps taken (undo them first).
  /// - `offerDouble` needs `awaitingRoll` and asks the side to move.
  /// - `takeDouble` needs `cubeOffered` and asks the side offered to.
  ///
  /// The cube and `crawfordGame` come from [s]. [budget] overrides the
  /// level's (see `Bot.requestBudget`); [supersedes] names an older request
  /// this one replaces.
  ///
  /// Throws [ArgumentError] when [s] is not in the phase [kind] needs.
  static BotRequest fromState(
    GameState s, {
    required BotRequestKind kind,
    required BotLevel level,
    required int id,
    required int seed,
    Duration? budget,
    int? supersedes,
  }) {
    final side = switch (kind) {
      BotRequestKind.choosePlay ||
      BotRequestKind.analyze =>
        _need(s, GamePhase.moving, kind, s.sideToMove),
      BotRequestKind.offerDouble =>
        _need(s, GamePhase.awaitingRoll, kind, s.sideToMove),
      BotRequestKind.takeDouble =>
        _need(s, GamePhase.cubeOffered, kind, s.cube.offeredBy?.opponent),
    };
    final moving =
        kind == BotRequestKind.choosePlay || kind == BotRequestKind.analyze;
    return BotRequest(
      id: id,
      kind: kind,
      variant: s.variant,
      position: moving ? s.turnStart : s.position,
      side: side,
      dice: moving ? s.dice : const [],
      cascade: moving && s.cascadeMode,
      context: moving ? s.turnStartContext : s.context,
      cube: s.cube,
      crawfordGame: s.crawfordGame,
      level: level,
      seed: seed,
      budget: budget,
      steps: kind == BotRequestKind.analyze ? s.steps : const [],
      supersedes: supersedes,
    );
  }

  static Side _need(
      GameState s, GamePhase phase, BotRequestKind kind, Side? side) {
    if (s.phase != phase || side == null) {
      throw ArgumentError.value(
          s.phase, 'phase', '${kind.name} needs ${phase.name}');
    }
    return side;
  }
}
