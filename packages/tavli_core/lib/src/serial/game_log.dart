/// Action logs and replay (design spec §7; plan Task 15).
library;

import '../game/rule_violation.dart';
import '../match/match.dart';
import '../match/match_action.dart';
import '../match/match_config.dart';
import 'json_read.dart';

/// Everything needed to rebuild a match (design spec §7): its config, the
/// starting state and every accepted action, in order.
///
/// Trusted input only when it has a [start]: like `MatchState.fromJson`,
/// a starting state is not checked for how it could have been reached
/// (e.g. its scores). A server never accepts a client-supplied log or
/// state; untrusted peers send actions (`MatchAction.fromJson`), which
/// the server applies to its own authoritative state.
final class GameLog {
  final MatchConfig config;

  /// Where the match starts; null means `MatchState.initial(config)`. Set
  /// it for puzzles, challenges, resumed saves or spectators joining
  /// mid-match (e.g. a game built with `GameState.withPosition`).
  final MatchState? start;

  /// Unmodifiable.
  final List<MatchAction> actions;

  /// Throws [ArgumentError] if [start] has a different config.
  GameLog(this.config, List<MatchAction> actions, {this.start})
      : actions = List.unmodifiable(actions) {
    if (start != null && start!.config != config) {
      throw ArgumentError.value(start, 'start', 'config differs from $config');
    }
  }

  /// The state [replay] starts from.
  MatchState get startState => start ?? MatchState.initial(config);

  /// A log with [a] appended.
  GameLog add(MatchAction a) => GameLog(config, [...actions, a], start: start);

  /// `{"schemaVersion": 1, "config": {...}, "start": {...}|null,
  /// "actions": [...]}`; `start` is omitted for the initial state.
  Map<String, Object?> toJson() => {
        'schemaVersion': tavliCoreSchemaVersion,
        'config': config.toJson(),
        if (start != null) 'start': start!.toJson(),
        'actions': [for (final a in actions) a.toJson()],
      };

  /// Parses [toJson] output. Throws only [FormatException], including for
  /// a `schemaVersion` other than [tavliCoreSchemaVersion] and a `start`
  /// whose config differs from the log's.
  static GameLog fromJson(Object? json) {
    final r = JsonReader(json, 'GameLog')..checkSchema();
    final config = MatchConfig.fromJson(r.raw('config'));
    final rawStart = r.raw('start');
    final start = rawStart == null ? null : MatchState.fromJson(rawStart);
    if (start != null && start.config != config) {
      r.fail('start', "a match with the log's config");
    }
    return GameLog(
      config,
      [for (final a in r.list('actions')) MatchAction.fromJson(a)],
      start: start,
    );
  }
}

/// The match [log] describes: `reduceMatch` folded over its actions from
/// [GameLog.startState]. Deterministic. Throws [FormatException] if an action
/// is rejected (the log is corrupt or from another rule set).
MatchState replay(GameLog log) {
  var m = log.startState;
  for (final (i, a) in log.actions.indexed) {
    switch (reduceMatch(m, a)) {
      case MatchUpdate(:final state):
        m = state;
      case RuleViolation(:final code, :final message):
        throw FormatException('GameLog: action $i ($a) rejected: '
            '${code.name}: $message');
    }
  }
  return m;
}
