/// Action logs and replay (design spec §7; plan Task 15).
library;

import '../game/rule_violation.dart';
import '../match/match.dart';
import '../match/match_action.dart';
import '../match/match_config.dart';
import 'json_read.dart';

/// Everything needed to rebuild a match: its config and every accepted
/// action, in order. The match starts from `MatchState.initial(config)`.
final class GameLog {
  final int schemaVersion;
  final MatchConfig config;

  /// Unmodifiable.
  final List<MatchAction> actions;

  GameLog(this.config, List<MatchAction> actions)
      : schemaVersion = tavliCoreSchemaVersion,
        actions = List.unmodifiable(actions);

  /// A log with [a] appended.
  GameLog add(MatchAction a) => GameLog(config, [...actions, a]);

  /// `{"schemaVersion": 1, "config": {...}, "actions": [...]}`.
  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'config': config.toJson(),
        'actions': [for (final a in actions) a.toJson()],
      };

  /// Parses [toJson] output. Throws only [FormatException], including for
  /// a `schemaVersion` other than [tavliCoreSchemaVersion].
  static GameLog fromJson(Object? json) {
    final r = JsonReader(json, 'GameLog')..checkSchema();
    return GameLog(
      MatchConfig.fromJson(r.raw('config')),
      [for (final a in r.list('actions')) MatchAction.fromJson(a)],
    );
  }
}

/// The match [log] describes: `reduceMatch` folded over its actions from
/// the initial state. Deterministic. Throws [FormatException] if an action
/// is rejected (the log is corrupt or from another rule set).
MatchState replay(GameLog log) {
  var m = MatchState.initial(log.config);
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
