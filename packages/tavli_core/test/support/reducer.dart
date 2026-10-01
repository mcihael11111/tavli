/// Helpers for reducer tests.
library;

import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart' hide Timeout;

/// [a] must be accepted; returns the update.
GameUpdate ok(GameState s, GameAction a) {
  final r = reduce(s, a);
  expect(r, isA<GameUpdate>(), reason: '$a -> $r');
  return r as GameUpdate;
}

/// Applies [actions] in order, each accepted; returns the final state.
GameState play(GameState s, List<GameAction> actions) {
  for (final a in actions) {
    s = ok(s, a).state;
  }
  return s;
}

/// [a] must be rejected with [code], leaving nothing changed.
void rejects(GameState s, GameAction a, ViolationCode code) {
  final r = reduce(s, a);
  expect(r, isA<RuleViolation>(), reason: '$a');
  expect((r as RuleViolation).code, code, reason: '$a: ${r.message}');
}

/// Plays the first legal play of the tree (first next step each time) and
/// commits.
GameState playAny(GameState s) {
  while (!s.node.isComplete) {
    s = ok(s, StepAction(s.node.nextSteps.first)).state;
  }
  return ok(s, const CommitPlay()).state;
}
