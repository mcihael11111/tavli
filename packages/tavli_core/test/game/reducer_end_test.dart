import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/positions.dart';
import '../support/reducer.dart';

typedef S = Side;

const _portes = Variant.portes;

/// A Portes game with side one about to roll.
GameState _portesToRoll() => GameState.initial(_portes, starter: S.one);

void main() {
  group('cube plumbing', () {
    test('a variant without a cube is cubeUnavailable', () {
      rejects(
          _portesToRoll(), const OfferDouble(), ViolationCode.cubeUnavailable);
      // Long Nard's cube is off unless enabled.
      rejects(GameState.initial(Variant.longNard, starter: S.one),
          const OfferDouble(), ViolationCode.cubeUnavailable);
    });

    test('offer, take, and the owner rule (cannotDouble)', () {
      final s = GameState.initial(Variant.shortNard, starter: S.one);
      final offered = ok(s, const OfferDouble());
      final e = offered.events.single as CubeOffered;
      expect([e.by, e.value], [S.one, 2]);
      expect(offered.state.phase, GamePhase.cubeOffered);
      for (final a in const [RollDice(3, 1), OfferDouble(), CommitPlay()]) {
        rejects(offered.state, a, ViolationCode.wrongPhase);
      }
      final taken = ok(offered.state, const Take());
      final t = taken.events.single as CubeTaken;
      expect([t.by, t.newValue], [S.two, 2]);
      expect(taken.state.phase, GamePhase.awaitingRoll);
      expect(taken.state.sideToMove, S.one);
      expect(taken.state.cube.value, 2);
      expect(taken.state.cube.owner, S.two);
      rejects(taken.state, const OfferDouble(), ViolationCode.cannotDouble);
    });

    test('drop: the offerer wins at the current value', () {
      final s = GameState.initial(Variant.longNard,
          starter: S.two, cubeEnabled: true);
      final offered = ok(s, const OfferDouble()).state;
      final u = ok(offered, const Drop());
      expect(u.events[0], isA<CubeDropped>());
      expect((u.events[0] as CubeDropped).by, S.one);
      expect(u.state.phase, GamePhase.gameOver);
      expect(
          u.state.result,
          const GameResult(
              winner: S.two, kind: ResultKind.single, points: 1, cubeValue: 1));
    });

    test('the Crawford game cannot double', () {
      final s = GameState.initial(Variant.shortNard,
          starter: S.one, crawfordGame: true);
      rejects(s, const OfferDouble(), ViolationCode.cannotDouble);
    });
  });

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

  group('Gul Bara', () {
    test('D15 doubles cascade from the fourth roll of the game', () {
      var s = GameState.initial(Variant.gulBara, starter: S.one);
      for (final d in const [3, 4, 2]) {
        s = ok(s, RollDice(d, d)).state;
        expect(s.cascadeMode, isFalse);
        expect(s.dice, [d, d, d, d]);
        s = playAny(s);
      }
      s = ok(s, const RollDice(5, 5)).state;
      expect(s.rollIndex, 4);
      expect(s.cascadeMode, isTrue);
      expect(s.dice, cascadeQueue(5));
      expect(s.tree.isLazy, isTrue);
    });

    test('a cascade remainder does not block the turn (D16-B is Task 12)', () {
      var s = GameState.initial(Variant.gulBara, starter: S.one);
      for (final d in const [3, 4, 2]) {
        s = playAny(ok(s, RollDice(d, d)).state);
      }
      expect(s.sideToMove, S.two);
      // One blocks two's 18, 13, 8 and 3, so no 6 plays after the 5s.
      final p = posSame(
        two: {24: 15},
        one: {6: 2, 1: 2, 20: 2, 15: 2, 24: 7},
      );
      s = ok(s.withPosition(p), const RollDice(5, 5)).state;
      expect(s.tree.diceUsed, 4);
      expect(s.tree.remainder, [6, 6, 6, 6]);
      final next = playAny(s);
      expect(next.phase, GamePhase.awaitingRoll);
      expect(next.sideToMove, S.one);
    });
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
