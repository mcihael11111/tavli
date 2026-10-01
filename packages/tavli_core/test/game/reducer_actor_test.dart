import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/reducer.dart';

typedef S = Side;

void main() {
  final opening = GameState.initial(Variant.shortNard);
  final toRoll = GameState.initial(Variant.shortNard, starter: S.one);
  final moving = stateAfter(toRoll, const RollDice(3, 1));
  final offered = stateAfter(toRoll, const OfferDouble());

  test('actorOf each action type', () {
    expect(actorOf(opening, const RollOpening(3, 1)), isNull);
    expect(actorOf(toRoll, const RollDice(3, 1)), S.one);
    expect(actorOf(toRoll, const OfferDouble()), S.one);
    for (final a in const [
      StepAction(Step(8, 5, 3)),
      UndoStep(),
      CommitPlay(),
    ]) {
      expect(actorOf(moving, a), S.one, reason: '$a');
    }
    expect(actorOf(offered, const Take()), S.two);
    expect(actorOf(offered, const Drop()), S.two);
    expect(actorOf(toRoll, const Take()), isNull, reason: 'no offer');
    expect(actorOf(moving, const Resign(S.two)), S.two);
    expect(actorOf(moving, const ClockTimeout(S.one)), S.one);
    expect(actorOf(opening, const Resign(S.one)), S.one);
  });

  test('by: the right side is accepted, the other is notYourAction', () {
    for (final (s, a, actor) in [
      (toRoll, const RollDice(3, 1), S.one),
      (toRoll, const OfferDouble(), S.one),
      (moving, const StepAction(Step(8, 5, 3)), S.one),
      (
        ok(moving, const StepAction(Step(8, 5, 3))).state,
        const UndoStep(),
        S.one
      ),
      (
        play(moving,
            const [StepAction(Step(8, 5, 3)), StepAction(Step(6, 5, 1))]),
        const CommitPlay(),
        S.one
      ),
      (offered, const Take(), S.two),
      (offered, const Drop(), S.two),
      (moving, const Resign(S.two), S.two),
      (moving, const ClockTimeout(S.one), S.one),
    ]) {
      expect(reduce(s, a, by: actor), isA<GameUpdate>(), reason: '$a');
      rejects(s, a, ViolationCode.notYourAction, by: actor.opponent);
    }
  });

  test('Take and Drop from the offering side are notYourAction', () {
    rejects(offered, const Take(), ViolationCode.notYourAction, by: S.one);
    rejects(offered, const Drop(), ViolationCode.notYourAction, by: S.one);
  });

  test('a side cannot resign for the other', () {
    rejects(moving, const Resign(S.one), ViolationCode.notYourAction,
        by: S.two);
  });

  test('either side may send the opening roll', () {
    for (final by in S.values) {
      expect(
          reduce(opening, const RollOpening(5, 2), by: by), isA<GameUpdate>());
    }
  });

  test('without an actor the phase decides (wrongPhase, not notYourAction)',
      () {
    rejects(toRoll, const Take(), ViolationCode.wrongPhase, by: S.one);
  });

  test('after the game ends, gameOver wins over notYourAction', () {
    final over = ok(toRoll, const Resign(S.one)).state;
    rejects(over, const RollDice(3, 1), ViolationCode.gameOver, by: S.two);
  });
}
