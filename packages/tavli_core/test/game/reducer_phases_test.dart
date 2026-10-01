import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/positions.dart';
import '../support/reducer.dart';

typedef S = Side;

const _portes = Variant.portes;

/// A Portes game with side one about to roll.
GameState _portesToRoll() => GameState.initial(_portes, starter: S.one);

void main() {
  group('opening', () {
    test('G7 opening tie re-rolls and stays in opening', () {
      final s = GameState.initial(_portes);
      expect(s.phase, GamePhase.opening);
      expect(s.sideToMove, isNull);
      final u = ok(s, const RollOpening(4, 4));
      expect(u.state, s);
      expect(u.events, hasLength(1));
      final e = u.events.single as OpeningRolled;
      expect([e.dieOne, e.dieTwo, e.starter], [4, 4, null]);
    });

    test('D1-A playOpeningDice: the winner moves with both dice', () {
      final u = ok(GameState.initial(_portes), const RollOpening(2, 5));
      final s = u.state;
      expect((u.events.single as OpeningRolled).starter, S.two);
      expect(s.phase, GamePhase.moving);
      expect(s.sideToMove, S.two);
      expect(s.dice, [5, 2]);
      expect(s.rollIndex, 1);
      expect(s.context.firstTurn, isTrue);
      expect(s.context.diceOfTurn, [5, 2]);
      expect(s.steps, isEmpty);
      expect(s.tree.hasPlay, isTrue);
      expect(s.turnStart, s.position);
    });

    test('D1-B winnerRerolls: the winner rolls next', () {
      final u = ok(GameState.initial(Variant.tavla), const RollOpening(6, 1));
      final s = u.state;
      expect((u.events.single as OpeningRolled).starter, S.one);
      expect(s.phase, GamePhase.awaitingRoll);
      expect(s.sideToMove, S.one);
      expect(s.dice, isEmpty);
      expect(s.rollIndex, 0);
    });

    test('opening dice outside 1..6 are invalidDice', () {
      final s = GameState.initial(_portes);
      rejects(s, const RollOpening(0, 3), ViolationCode.invalidDice);
      rejects(s, const RollOpening(2, 7), ViolationCode.invalidDice);
    });

    test('a starter skips the opening', () {
      final s = _portesToRoll();
      expect(s.phase, GamePhase.awaitingRoll);
      expect(s.sideToMove, S.one);
      rejects(s, const RollOpening(3, 1), ViolationCode.wrongPhase);
    });

    test('wrongPhase for non-opening actions in opening', () {
      final s = GameState.initial(_portes);
      for (final a in const [
        RollDice(3, 1),
        StepAction(Step(8, 5, 3)),
        UndoStep(),
        CommitPlay(),
        OfferDouble(),
        Take(),
        Drop(),
      ]) {
        rejects(s, a, ViolationCode.wrongPhase);
      }
    });
  });

  group('rolling', () {
    test('RollDice starts the moving phase', () {
      final u = ok(_portesToRoll(), const RollDice(3, 1));
      final s = u.state;
      final e = u.events.single as DiceRolled;
      expect([
        e.side,
        e.dice
      ], [
        S.one,
        const [3, 1]
      ]);
      expect(s.phase, GamePhase.moving);
      expect(s.dice, [3, 1]);
      expect(s.cascadeMode, isFalse);
      expect(s.rollIndex, 1);
      expect(s.context.firstTurn, isTrue);
      expect(s.tree.finals, hasLength(16));
    });

    test('G3 a double is four dice', () {
      final s = ok(_portesToRoll(), const RollDice(4, 4)).state;
      expect(s.dice, [4, 4, 4, 4]);
      expect(s.tree.diceUsed, 4);
    });

    test('roll dice outside 1..6 are invalidDice', () {
      rejects(_portesToRoll(), const RollDice(0, 2), ViolationCode.invalidDice);
      rejects(_portesToRoll(), const RollDice(3, 9), ViolationCode.invalidDice);
    });

    test('G9 no legal play: the turn passes', () {
      // Side two holds my 19..24: the bar checker cannot enter.
      final p = pos(
        one: {6: 14},
        barOne: 1,
        two: {1: 2, 2: 2, 3: 2, 4: 2, 5: 2, 6: 5},
      );
      final s0 = _portesToRoll().withPosition(p);
      final u = ok(s0, const RollDice(5, 3));
      expect(u.events, hasLength(2));
      final passed = u.events[1] as TurnPassed;
      expect([
        passed.side,
        passed.dice
      ], [
        S.one,
        const [5, 3]
      ]);
      final s = u.state;
      expect(s.phase, GamePhase.awaitingRoll);
      expect(s.sideToMove, S.two);
      expect(s.position, p);
      expect(s.turnsTaken, {S.one: 1, S.two: 0});
      expect(s.rollIndex, 1);
      expect(s.dice, isEmpty);
    });

    test('wrongPhase for moving actions while awaiting the roll', () {
      final s = _portesToRoll();
      for (final a in const [
        StepAction(Step(8, 5, 3)),
        UndoStep(),
        CommitPlay(),
        Take(),
        Drop(),
      ]) {
        rejects(s, a, ViolationCode.wrongPhase);
      }
    });
  });

  group('moving', () {
    final moving = stateAfter(_portesToRoll(), const RollDice(3, 1));

    test('StepAction applies the step and emits CheckerMoved', () {
      final u = ok(moving, const StepAction(Step(8, 5, 3)));
      final e = u.events.single as CheckerMoved;
      expect(e.side, S.one);
      expect(e.step.step, const Step(8, 5, 3));
      final s = u.state;
      expect(s.phase, GamePhase.moving);
      expect(s.steps, const [Step(8, 5, 3)]);
      expect(s.position.count(S.one, 5), 1);
      expect(s.turnStart, moving.position);
      expect(s.node.nextSteps, contains(const Step(6, 5, 1)));
    });

    test('a step outside the tree is illegalStep', () {
      rejects(moving, const StepAction(Step(13, 12, 1)),
          ViolationCode.illegalStep); // two holds my 12
      rejects(moving, const StepAction(Step(8, 4, 4)),
          ViolationCode.illegalStep); // no die 4
      final s = ok(moving, const StepAction(Step(8, 5, 3))).state;
      rejects(s, const StepAction(Step(6, 3, 3)), ViolationCode.illegalStep);
    });

    test('commit is rejected mid-play', () {
      rejects(moving, const CommitPlay(), ViolationCode.incompletePlay);
      final s = ok(moving, const StepAction(Step(8, 5, 3))).state;
      rejects(s, const CommitPlay(), ViolationCode.incompletePlay);
    });

    test('commit a full play: the opponent is to roll', () {
      final s = play(moving, const [
        StepAction(Step(8, 5, 3)),
        StepAction(Step(6, 5, 1)),
      ]);
      final u = ok(s, const CommitPlay());
      final e = u.events.single as PlayCommitted;
      expect([
        e.side,
        e.steps
      ], [
        S.one,
        const [Step(8, 5, 3), Step(6, 5, 1)],
      ]);
      final next = u.state;
      expect(next.phase, GamePhase.awaitingRoll);
      expect(next.sideToMove, S.two);
      expect(next.position, s.position);
      expect(next.turnStart, s.position);
      expect(next.turnsTaken, {S.one: 1, S.two: 0});
      expect(next.steps, isEmpty);
      expect(next.dice, isEmpty);
      // Side two's first turn follows.
      final two = ok(next, const RollDice(6, 5)).state;
      expect(two.context.firstTurn, isTrue);
      expect(two.rollIndex, 2);
    });

    test('undo back to the turn start', () {
      final s2 = play(moving, const [
        StepAction(Step(13, 10, 3)),
        StepAction(Step(10, 9, 1)),
      ]);
      final u1 = ok(s2, const UndoStep());
      expect((u1.events.single as StepUndone).step.step, const Step(10, 9, 1));
      expect(u1.state.steps, const [Step(13, 10, 3)]);
      expect(u1.state, ok(moving, const StepAction(Step(13, 10, 3))).state);
      final u0 = ok(u1.state, const UndoStep());
      expect(u0.state, moving);
      expect(u0.state.position, moving.turnStart);
      expect(u0.state.context, moving.context);
      rejects(u0.state, const UndoStep(), ViolationCode.nothingToUndo);
    });

    test('undo reverses a hit', () {
      // two's blot on its 21 = my 4.
      final p = pos(one: {8: 1, 13: 14}, two: {21: 1, 1: 14});
      final s0 = ok(_portesToRoll().withPosition(p), const RollDice(4, 3));
      final hit = ok(s0.state, const StepAction(Step(8, 4, 4)));
      expect((hit.events.single as CheckerMoved).step.hit, isTrue);
      expect(hit.state.position.onBar(S.two), 1);
      final u = ok(hit.state, const UndoStep());
      expect((u.events.single as StepUndone).step.hit, isTrue);
      expect(u.state.position, p);
      expect(u.state, s0.state);
    });

    test('G8 a game-ending step goes to gameOver mid-turn', () {
      final p = pos(one: {3: 1, 1: 1}, two: {1: 15});
      final s0 = ok(_portesToRoll().withPosition(p), const RollDice(5, 2));
      final u = play(s0.state, const [StepAction(Step(3, 0, 5))]);
      expect(u.phase, GamePhase.moving, reason: 'one checker left');
      final end = ok(u, const StepAction(Step(1, 0, 2)));
      expect(end.events, hasLength(2));
      expect(end.events[1], isA<GameEnded>());
      expect(end.state.phase, GamePhase.gameOver);
      expect(end.state.result?.winner, S.one);
    });

    test('D8a a mother pin ends the game with dice unplayed', () {
      // two's mother on its 24 (= my 1); 3->1 with the 2 pins it.
      final p = pos(one: {3: 1, 10: 14}, two: {24: 1, 20: 2, 13: 12});
      final s0 =
          GameState.initial(Variant.plakoto, starter: S.one).withPosition(p);
      final s = ok(s0, const RollDice(2, 5)).state;
      final end = ok(s, const StepAction(Step(3, 1, 2)));
      expect(end.state.phase, GamePhase.gameOver);
      expect(end.state.result?.winner, S.one);
      expect(end.state.steps, const [Step(3, 1, 2)]);
    });

    test('wrongPhase for rolls and the cube while moving', () {
      for (final a in const [
        RollDice(3, 1),
        RollOpening(3, 1),
        OfferDouble(),
        Take(),
        Drop(),
      ]) {
        rejects(moving, a, ViolationCode.wrongPhase);
      }
    });
  });
}
