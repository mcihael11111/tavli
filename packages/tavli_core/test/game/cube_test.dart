import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/positions.dart';
import '../support/reducer.dart';

typedef S = Side;

/// Short Nard (cube on by default) with [starter] to roll.
GameState _nard({S starter = S.one, bool crawford = false}) =>
    GameState.initial(Variant.shortNard,
        starter: starter, crawfordGame: crawford);

void main() {
  group('availability (D7)', () {
    test('Portes has no cube: cubeUnavailable, even if asked for', () {
      final s = GameState.initial(Variant.portes, starter: S.one);
      expect(s.cube.enabled, isFalse);
      rejects(s, const OfferDouble(), ViolationCode.cubeUnavailable);
      final asked =
          GameState.initial(Variant.portes, starter: S.one, cubeEnabled: true);
      expect(asked.cube.enabled, isFalse);
      rejects(asked, const OfferDouble(), ViolationCode.cubeUnavailable);
    });

    test('Short Nard: enabled by default, can be switched off', () {
      final s = _nard();
      expect(s.cube, const CubeState(enabled: true));
      expect(ok(s, const OfferDouble()).state.phase, GamePhase.cubeOffered);
      final off = GameState.initial(Variant.shortNard,
          starter: S.one, cubeEnabled: false);
      rejects(off, const OfferDouble(), ViolationCode.cubeUnavailable);
    });

    test('Long Nard: available but disabled by default', () {
      final s = GameState.initial(Variant.longNard, starter: S.one);
      expect(s.cube.enabled, isFalse);
      rejects(s, const OfferDouble(), ViolationCode.cubeUnavailable);
      final on = GameState.initial(Variant.longNard,
          starter: S.one, cubeEnabled: true);
      expect(on.cube.enabled, isTrue);
      expect(ok(on, const OfferDouble()).state.phase, GamePhase.cubeOffered);
    });

    test('Shesh Besh: available but disabled by default', () {
      expect(GameState.initial(Variant.sheshBesh).cube.enabled, isFalse);
      expect(
        GameState.initial(Variant.sheshBesh, cubeEnabled: true).cube.enabled,
        isTrue,
      );
    });
  });

  group('OfferDouble', () {
    test('only in awaitingRoll', () {
      final moving = ok(_nard(), const RollDice(3, 1)).state;
      rejects(moving, const OfferDouble(), ViolationCode.wrongPhase);
      rejects(GameState.initial(Variant.shortNard), const OfferDouble(),
          ViolationCode.wrongPhase);
    });

    test('goes to cubeOffered and emits CubeOffered', () {
      final u = ok(_nard(), const OfferDouble());
      expect(u.events, [const CubeOffered(S.one, 2)]);
      expect(u.state.phase, GamePhase.cubeOffered);
      expect(u.state.sideToMove, S.one);
      expect(u.state.cube, const CubeState(enabled: true, offeredBy: S.one));
      for (final a in const [RollDice(3, 1), OfferDouble(), UndoStep()]) {
        rejects(u.state, a, ViolationCode.wrongPhase);
      }
    });

    test('a Crawford game refuses', () {
      rejects(_nard(crawford: true), const OfferDouble(),
          ViolationCode.cannotDouble);
    });

    test('only the owner may redouble; a centered cube either side', () {
      final taken = play(_nard(), const [OfferDouble(), Take()]);
      expect(taken.cube.owner, S.two);
      rejects(taken, const OfferDouble(), ViolationCode.cannotDouble);
      // After one's turn, two (the owner) may redouble to 4.
      final twoToRoll = playAny(ok(taken, const RollDice(3, 1)).state);
      expect(twoToRoll.sideToMove, S.two);
      final u = ok(twoToRoll, const OfferDouble());
      expect(u.events, [const CubeOffered(S.two, 4)]);
      // Centered: the second player may double first.
      expect(ok(_nard(starter: S.two), const OfferDouble()).events,
          [const CubeOffered(S.two, 2)]);
    });

    test('cap at 64', () {
      var s = _nard();
      for (var i = 1; i <= 6; i++) {
        s = play(s, const [OfferDouble(), Take()]);
        expect(s.cube.value, 1 << i);
        // The taker owns the cube and is next to roll after this turn.
        s = playAny(ok(s, const RollDice(3, 1)).state);
        expect(s.sideToMove, s.cube.owner);
      }
      expect(s.cube.value, 64);
      rejects(s, const OfferDouble(), ViolationCode.cannotDouble);
    });
  });

  test('Take: value x2, owner = taker, back to the offerer to roll', () {
    final u =
        ok(ok(_nard(starter: S.two), const OfferDouble()).state, const Take());
    expect(u.events, [const CubeTaken(S.one, 2)]);
    expect(u.state.phase, GamePhase.awaitingRoll);
    expect(u.state.sideToMove, S.two);
    expect(
        u.state.cube, const CubeState(value: 2, owner: S.one, enabled: true));
    // The offerer now rolls normally.
    expect(ok(u.state, const RollDice(6, 5)).state.phase, GamePhase.moving);
  });

  test('Drop: the offerer wins single x the value before doubling', () {
    // Cube at 2 owned by two; two redoubles to 4 and one drops.
    final taken = play(_nard(), const [OfferDouble(), Take()]);
    final twoToRoll = playAny(ok(taken, const RollDice(3, 1)).state);
    final offered = ok(twoToRoll, const OfferDouble()).state;
    final u = ok(offered, const Drop());
    const result = GameResult(
        winner: S.two, kind: ResultKind.single, points: 2, cubeValue: 2);
    expect(u.events, [const CubeDropped(S.one), const GameEnded(result)]);
    expect(u.state.phase, GamePhase.gameOver);
    expect(u.state.result, result);
    expect(u.state.cube.value, 2);
    expect(u.state.cube.offeredBy, isNull);
  });

  test('Take and Drop outside an offer are wrongPhase', () {
    rejects(_nard(), const Take(), ViolationCode.wrongPhase);
    rejects(_nard(), const Drop(), ViolationCode.wrongPhase);
  });

  test('a taken cube multiplies the game result', () {
    // Shesh Besh, cube 2 owned by two; one then bears off its last checker
    // with two having borne off none: a gammon, 2 x 2.
    final taken = play(
        GameState.initial(Variant.sheshBesh, starter: S.one, cubeEnabled: true),
        const [OfferDouble(), Take()]);
    final s = taken.withPosition(pos(one: {1: 1}, two: {6: 15}));
    final rolled = ok(s, const RollDice(3, 1)).state;
    final u = ok(rolled, const StepAction(Step(1, 0, 3)));
    expect(
      u.state.result,
      const GameResult(
          winner: S.one, kind: ResultKind.gammon, points: 4, cubeValue: 2),
    );
  });
}
