import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/positions.dart';
import '../support/reducer.dart';

typedef S = Side;

const _gul = Variant.gulBara;

/// Side two to roll at roll 4 of the game (cascades on), on [p]: side one
/// starts, three doubles are played normally, then the board is set.
GameState _twoToRollAtRoll4(Position p) {
  var s = GameState.initial(_gul, starter: S.one);
  for (final d in const [3, 4, 2]) {
    s = playAny(ok(s, RollDice(d, d)).state);
  }
  expect(s.sideToMove, S.two);
  expect(s.rollIndex, 3);
  return s.withPosition(p);
}

void main() {
  test('D15 cascade starts after the first 3 rolls of the game', () {
    // Gul Bara re-rolls the opening (D1-B): the opening roll is no roll.
    var s = ok(GameState.initial(_gul), const RollOpening(5, 2)).state;
    expect(s.phase, GamePhase.awaitingRoll);
    expect(s.rollIndex, 0);
    for (final (i, d) in const [(1, 3), (2, 4), (3, 2)]) {
      s = ok(s, RollDice(d, d)).state;
      expect(s.rollIndex, i);
      expect(s.cascadeMode, isFalse, reason: 'roll $i');
      expect(s.dice, [d, d, d, d]);
      expect(s.tree.isLazy, isFalse);
      s = playAny(s);
    }
    s = ok(s, const RollDice(5, 5)).state;
    expect(s.rollIndex, 4);
    expect(s.cascadeMode, isTrue);
    expect(s.dice, cascadeQueue(5));
    expect(s.tree.isLazy, isTrue);
    // A non-double never cascades.
    final n = ok(playAny(s), const RollDice(6, 1)).state;
    expect(n.cascadeMode, isFalse);
    expect(n.dice, [6, 1]);
  });

  test('D16 opponent plays remainder, then rolls its own turn', () {
    // One blocks two's 18 and 13 (its 6 and 1): after 24->19 x4 with the
    // 5s, no 6 plays (19->13 and 24->18 are closed).
    final p = posSame(
      two: {24: 15},
      one: {6: 2, 1: 2, 20: 2, 15: 2, 24: 7},
    );
    final s = ok(_twoToRollAtRoll4(p), const RollDice(5, 5)).state;
    expect(s.pendingRemainder, [6, 6, 6, 6]);
    expect(s.tree.remainder, [6, 6, 6, 6]);
    final played = play(s, const [
      StepAction(Step(24, 19, 5)),
      StepAction(Step(24, 19, 5)),
      StepAction(Step(24, 19, 5)),
      StepAction(Step(24, 19, 5)),
    ]);
    final u = ok(played, const CommitPlay());
    expect(u.events, [
      PlayCommitted(S.two, played.steps),
      RemainderPassed(S.one, const [6, 6, 6, 6]),
    ]);
    final rem = u.state;
    expect(rem.phase, GamePhase.moving);
    expect(rem.sideToMove, S.one);
    expect(rem.remainderTurn, isTrue);
    expect(rem.cascadeMode, isTrue);
    expect(rem.dice, [6, 6, 6, 6]);
    expect(rem.pendingRemainder, isEmpty);
    expect(rem.turnStart, played.position);
    expect(rem.rollIndex, 4, reason: 'a remainder is not a roll');
    expect(rem.tree.diceUsed, 4);
    rejects(rem, const RollDice(3, 1), ViolationCode.wrongPhase);

    final after = playAny(rem);
    expect(after.phase, GamePhase.awaitingRoll);
    expect(after.sideToMove, S.one, reason: 'the remainder player, not two');
    expect(after.remainderTurn, isFalse);
    expect(after.turnsTaken[S.one], rem.turnsTaken[S.one],
        reason: 'a remainder turn is not a turn of its own');
    expect(after.turnsTaken[S.two], s.turnsTaken[S.two]! + 1);
  });

  test('D16 remainder stops at its own first failure', () {
    // Two: 12->6 with one 6 (15->9 is closed by one's 21), so [6, 6, 6]
    // passes. One then plays 21->15->9; 9->3 is closed by two's 15, and
    // that last 6 is discarded, never passed back.
    final p = posSame(one: {21: 1, 9: 1}, two: {12: 1, 15: 1});
    final s = ok(_twoToRollAtRoll4(p), const RollDice(6, 6)).state;
    expect(s.tree.diceUsed, 1);
    final u = ok(s, const StepAction(Step(12, 6, 6))).state;
    final rem = ok(u, const CommitPlay()).state;
    expect(rem.remainderTurn, isTrue);
    expect(rem.dice, [6, 6, 6]);
    expect(rem.tree.diceUsed, 2);
    expect(rem.tree.remainder, [6]);
    expect(rem.pendingRemainder, isEmpty);
    final after = play(rem, const [
      StepAction(Step(21, 15, 6)),
      StepAction(Step(15, 9, 6)),
    ]);
    final done = ok(after, const CommitPlay());
    expect(done.events, [
      PlayCommitted(S.one, const [Step(21, 15, 6), Step(15, 9, 6)]),
    ]);
    expect(done.state.phase, GamePhase.awaitingRoll);
    expect(done.state.sideToMove, S.one);
  });

  test('D16 a remainder the opponent cannot play goes straight to its roll',
      () {
    // As above, but two also holds its 3 (= one's 15): no 6 for one.
    final p = posSame(one: {21: 1, 9: 1}, two: {12: 1, 15: 1, 3: 1});
    final s = ok(_twoToRollAtRoll4(p), const RollDice(6, 6)).state;
    final moved = ok(s, const StepAction(Step(12, 6, 6))).state;
    final u = ok(moved, const CommitPlay());
    expect(u.events, [
      PlayCommitted(S.two, const [Step(12, 6, 6)]),
      RemainderPassed(S.one, const [6, 6, 6]),
    ]);
    expect(u.state.phase, GamePhase.awaitingRoll);
    expect(u.state.sideToMove, S.one);
    expect(u.state.remainderTurn, isFalse);
    expect(u.state.dice, isEmpty);
  });

  test('A6 a cascade with no step at all hands over the whole queue', () {
    // Two's 15->9 and 12->6 are closed by one's 21 and 18.
    final p = posSame(one: {21: 1, 18: 1}, two: {12: 1, 15: 1});
    final u = ok(_twoToRollAtRoll4(p), const RollDice(6, 6));
    expect(u.events, [
      DiceRolled(S.two, const [6, 6]),
      TurnPassed(S.two, const [6, 6]),
      RemainderPassed(S.one, const [6, 6, 6, 6]),
    ]);
    expect(u.state.phase, GamePhase.moving);
    expect(u.state.sideToMove, S.one);
    expect(u.state.remainderTurn, isTrue);
    expect(u.state.dice, [6, 6, 6, 6]);
  });

  test('a remainder turn refuses the cube and the other side', () {
    final p = posSame(one: {21: 1, 9: 1}, two: {12: 1, 15: 1});
    final s = ok(_twoToRollAtRoll4(p), const RollDice(6, 6)).state;
    final rem = play(s, const [StepAction(Step(12, 6, 6)), CommitPlay()]);
    expect(rem.remainderTurn, isTrue);
    expect(actorOf(rem, const StepAction(Step(21, 15, 6))), S.one);
    rejects(rem, const OfferDouble(), ViolationCode.wrongPhase);
    rejects(rem, const OfferDouble(), ViolationCode.notYourAction, by: S.two);
    rejects(rem, const StepAction(Step(21, 15, 6)), ViolationCode.notYourAction,
        by: S.two);
    rejects(rem, const CommitPlay(), ViolationCode.notYourAction, by: S.two);
    expect(reduce(rem, const StepAction(Step(21, 15, 6)), by: S.one),
        isA<GameUpdate>());
  });

  test('undo within a remainder turn stays in the remainder turn', () {
    final p = posSame(one: {21: 1, 9: 1}, two: {12: 1, 15: 1});
    final s = ok(_twoToRollAtRoll4(p), const RollDice(6, 6)).state;
    final rem = play(s, const [StepAction(Step(12, 6, 6)), CommitPlay()]);
    final stepped = ok(rem, const StepAction(Step(21, 15, 6))).state;
    final back = ok(stepped, const UndoStep()).state;
    expect(back, rem);
  });
}
