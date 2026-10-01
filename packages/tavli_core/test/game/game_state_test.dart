import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/positions.dart';
import '../support/reducer.dart';

typedef S = Side;

void main() {
  final toRoll = GameState.initial(Variant.portes, starter: S.one);

  group('equality', () {
    test('equal states built two ways are equal; the tree is not compared', () {
      final a = play(toRoll, const [
        RollDice(3, 1),
        StepAction(Step(8, 5, 3)),
        StepAction(Step(6, 5, 1)),
      ]);
      // Another route: a different first step, undone.
      final b = play(toRoll, const [
        RollDice(3, 1),
        StepAction(Step(13, 10, 3)),
        UndoStep(),
        StepAction(Step(8, 5, 3)),
        StepAction(Step(6, 5, 1)),
      ]);
      expect(a.tree, isNot(same(b.tree)));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      // A fresh state whose tree was never built equals one that built it.
      final fresh = ok(toRoll, const RollDice(3, 1)).state;
      final used = ok(toRoll, const RollDice(3, 1)).state..tree.finals;
      expect(fresh, used);
      expect(fresh.hashCode, used.hashCode);
    });

    test('different states differ', () {
      final a = ok(toRoll, const RollDice(3, 1)).state;
      expect(a, isNot(ok(toRoll, const RollDice(1, 3)).state));
      expect(a, isNot(toRoll));
      expect(ok(a, const StepAction(Step(8, 5, 3))).state, isNot(a));
    });
  });

  test('collections are unmodifiable', () {
    final s = play(toRoll, const [RollDice(3, 1), StepAction(Step(8, 5, 3))]);
    expect(() => s.dice.add(1), throwsUnsupportedError);
    expect(() => s.steps.add(const Step(6, 5, 1)), throwsUnsupportedError);
    expect(() => s.turnsTaken[S.one] = 9, throwsUnsupportedError);
    expect(() => s.pendingRemainder.add(1), throwsUnsupportedError);
    expect(() => s.context.diceOfTurn.add(1), throwsUnsupportedError);
    final u = ok(s, const UndoStep());
    expect(
        () => u.events.add(const CubeDropped(S.one)), throwsUnsupportedError);
  });

  test('events are immutable values', () {
    expect(DiceRolled(S.one, const [3, 1]), DiceRolled(S.one, [3, 1]));
    expect(DiceRolled(S.one, const [3, 1]).hashCode,
        DiceRolled(S.one, [3, 1]).hashCode);
    expect(DiceRolled(S.one, const [3, 1]), isNot(TurnPassed(S.one, [3, 1])));
    expect(PlayCommitted(S.two, const [Step(8, 5, 3)]),
        PlayCommitted(S.two, [const Step(8, 5, 3)]));
    expect(const CheckerMoved(S.one, AppliedStep(Step(8, 4, 4), hit: true)),
        const CheckerMoved(S.one, AppliedStep(Step(8, 4, 4), hit: true)));
    expect(const AppliedStep(Step(8, 4, 4), hit: true),
        isNot(const AppliedStep(Step(8, 4, 4))));
    final dice = [5, 5];
    final e = DiceRolled(S.one, dice);
    dice[0] = 6;
    expect(e.dice, [5, 5]);
    expect(() => e.dice.add(1), throwsUnsupportedError);
    expect(() => TurnPassed(S.one, [1, 2]).dice.add(1), throwsUnsupportedError);
    expect(() => PlayCommitted(S.one, []).steps.add(const Step(6, 5, 1)),
        throwsUnsupportedError);
    expect(
        () => RemainderPassed(S.one, [6]).dice.add(1), throwsUnsupportedError);
  });

  test('a replayed update reports equal events', () {
    final a = reduce(toRoll, const RollDice(3, 1)) as GameUpdate;
    final b = reduce(toRoll, const RollDice(3, 1)) as GameUpdate;
    expect(a.events, b.events);
  });

  test('withPosition checks the direction and the phase', () {
    final same = posSame(one: {24: 15}, two: {24: 15});
    expect(() => toRoll.withPosition(same), throwsArgumentError);
    final moving = ok(toRoll, const RollDice(3, 1)).state;
    expect(() => moving.withPosition(moving.position), throwsStateError);
  });

  test('tree and node throw outside a moving phase', () {
    expect(() => toRoll.tree, throwsStateError);
    expect(() => toRoll.node, throwsStateError);
  });
}
