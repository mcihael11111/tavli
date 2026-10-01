part of 'game_state.dart';

// A whole play in one action (SubmitPlay; program design §4.7).

/// Plays [steps] as [StepAction]s, then commits as [CommitPlay] unless a
/// step ended the game; the events are theirs, in order. All or nothing:
/// any rejection rejects the whole play, and [s] stays as it was.
ReduceResult _submit(GameState s, List<Step> steps) {
  if (s.steps.isNotEmpty) {
    return const RuleViolation(
      ViolationCode.wrongPhase,
      'SubmitPlay after steps were taken this play (undo them first)',
    );
  }
  final events = <GameEvent>[];
  var cur = s;
  for (final (i, step) in steps.indexed) {
    if (cur.phase == GamePhase.gameOver) {
      return RuleViolation(
        ViolationCode.illegalStep,
        '${steps.sublist(i)} after the game ended',
      );
    }
    switch (_step(cur, step)) {
      case RuleViolation() && final v:
        return v;
      case GameUpdate(:final state, events: final e):
        cur = state;
        events.addAll(e);
    }
  }
  if (cur.phase == GamePhase.gameOver) return GameUpdate(cur, events);
  switch (_commit(cur)) {
    case RuleViolation() && final v:
      return v;
    case GameUpdate(:final state, events: final e):
      return GameUpdate(state, [...events, ...e]);
  }
}
