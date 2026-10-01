/// Helpers for reducer tests.
library;

import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

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

/// [a] (sent [by], if given) must be rejected with [code], leaving
/// nothing changed.
void rejects(GameState s, GameAction a, ViolationCode code, {Side? by}) {
  final hash = s.hashCode;
  final r = reduce(s, a, by: by);
  expect(r, isA<RuleViolation>(), reason: '$a');
  expect((r as RuleViolation).code, code, reason: '$a: ${r.message}');
  expect(s.hashCode, hash);
}

/// Plays the first legal play of the tree (first next step each time) and
/// commits.
GameState playAny(GameState s) {
  while (!s.node.isComplete) {
    s = ok(s, StepAction(s.node.nextSteps.first)).state;
  }
  return ok(s, const CommitPlay()).state;
}

/// The state after [a], which must be accepted; usable outside a test
/// (it throws a cast error instead of failing an expectation).
GameState stateAfter(GameState s, GameAction a) =>
    (reduce(s, a) as GameUpdate).state;
