import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/positions.dart';
import '../support/reducer.dart';

typedef S = Side;

const _portes = Variant.portes;

/// A Portes game with side one about to roll.
GameState _portesToRoll() => GameState.initial(_portes, starter: S.one);

void main() {
  group('resign and timeout', () {
    test('resign in opening: the opponent wins 1 x cube, kind resign', () {
      final u = ok(GameState.initial(_portes), const Resign(S.one));
      expect(u.state.phase, GamePhase.gameOver);
      expect(
        u.state.result,
        const GameResult(
            winner: S.two, kind: ResultKind.resign, points: 1, cubeValue: 1),
      );
      expect(u.events, [GameEnded(u.state.result!)]);
    });

    test('resign and timeout while awaiting the roll', () {
      final s = _portesToRoll();
      expect(
          ok(s, const Resign(S.one)).state.result,
          const GameResult(
              winner: S.two, kind: ResultKind.resign, points: 1, cubeValue: 1));
      expect(
          ok(s, const ClockTimeout(S.two)).state.result,
          const GameResult(
              winner: S.one,
              kind: ResultKind.timeout,
              points: 1,
              cubeValue: 1));
    });

    test('resign or timeout during an offer: the offer lapses', () {
      final offered = ok(GameState.initial(Variant.shortNard, starter: S.one),
              const OfferDouble())
          .state;
      expect(offered.cube.offeredBy, S.one);
      for (final (a, kind) in const [
        (Resign(S.two), ResultKind.resign),
        (ClockTimeout(S.two), ResultKind.timeout),
      ]) {
        final end = ok(offered, a).state;
        expect(end.phase, GamePhase.gameOver);
        expect(end.cube.offeredBy, isNull);
        expect(end.cube.value, 1, reason: 'the double was never taken');
        expect(end.result,
            GameResult(winner: S.one, kind: kind, points: 1, cubeValue: 1));
      }
    });

    test('timeout while moving, with the cube at 2', () {
      final s = play(GameState.initial(Variant.shortNard, starter: S.one),
          const [OfferDouble(), Take(), RollDice(3, 1)]);
      expect(s.phase, GamePhase.moving);
      final u = ok(s, const ClockTimeout(S.one));
      expect(
          u.state.result,
          const GameResult(
              winner: S.two,
              kind: ResultKind.timeout,
              points: 2,
              cubeValue: 2));
    });

    test('every action after the game is over is gameOver', () {
      final over = ok(_portesToRoll(), const Resign(S.two)).state;
      for (final a in const [
        RollOpening(3, 1),
        RollDice(3, 1),
        StepAction(Step(8, 5, 3)),
        UndoStep(),
        CommitPlay(),
        OfferDouble(),
        Take(),
        Drop(),
        Resign(S.one),
        ClockTimeout(S.two),
      ]) {
        rejects(over, a, ViolationCode.gameOver);
      }
    });
  });

  test('D1-A an opening winner with no legal play passes the turn', () {
    // Side two holds my 19..24: my bar checker cannot enter with 5-3.
    final p = pos(
      one: {6: 14},
      barOne: 1,
      two: {1: 2, 2: 2, 3: 2, 4: 2, 5: 2, 6: 5},
    );
    final u =
        ok(GameState.initial(_portes).withPosition(p), const RollOpening(5, 3));
    expect(u.events, [
      const OpeningRolled(5, 3, S.one),
      TurnPassed(S.one, const [5, 3]),
    ]);
    expect(u.state.phase, GamePhase.awaitingRoll);
    expect(u.state.sideToMove, S.two);
    expect(u.state.turnsTaken, {S.one: 1, S.two: 0});
    expect(u.state.rollIndex, 1);
    expect(u.state.position, p);
  });

  group('Long Nard D18 through the reducer', () {
    test('D18 firstTurn propagates to the head exception', () {
      // One wins the opening and plays 5-3 with one head checker.
      final opened =
          ok(GameState.initial(Variant.longNard), const RollOpening(5, 3))
              .state;
      expect(opened.sideToMove, S.one);
      expect(opened.context.firstTurn, isTrue);
      final afterOne = play(opened, const [
        StepAction(Step(24, 19, 5)),
        StepAction(Step(19, 16, 3)),
        CommitPlay(),
      ]);
      // Two's first turn: 6-6 lets two checkers leave the head.
      final two = ok(afterOne, const RollDice(6, 6)).state;
      expect(two.context.firstTurn, isTrue);
      final twoAfter = ok(two, const StepAction(Step(24, 18, 6))).state;
      expect(twoAfter.node.nextSteps, contains(const Step(24, 18, 6)));
      final twoDone = play(twoAfter, const [
        StepAction(Step(24, 18, 6)),
        CommitPlay(),
      ]);
      // One's second turn: 6-6 allows only one head checker.
      final one = ok(twoDone, const RollDice(6, 6)).state;
      expect(one.context.firstTurn, isFalse);
      final oneAfter = ok(one, const StepAction(Step(24, 18, 6))).state;
      expect(oneAfter.node.nextSteps, isNot(contains(const Step(24, 18, 6))));
    });
  });
}
