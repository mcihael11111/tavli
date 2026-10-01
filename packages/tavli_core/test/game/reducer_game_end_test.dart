import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/positions.dart';
import '../support/reducer.dart';

typedef S = Side;

void main() {
  group('game end through the reducer', () {
    const plakoto = Variant.plakoto;

    GameState twoToRoll(Variant v, Position p) =>
        GameState.initial(v, starter: S.two).withPosition(p);

    test('D8a mother immediate: two wins 2 mid-turn, dice unplayed', () {
      // two's 3 -> 1 (= my 24) pins my mother; two has left its start.
      final p = pos(one: {24: 1, 6: 14}, two: {3: 1, 13: 14});
      final s = ok(twoToRoll(plakoto, p), const RollDice(2, 5)).state;
      final u = ok(s, const StepAction(Step(3, 1, 2)));
      expect(u.events.last, isA<GameEnded>());
      expect(u.state.phase, GamePhase.gameOver);
      expect(
        u.state.result,
        const GameResult(
            winner: S.two, kind: ResultKind.mother, points: 2, cubeValue: 1),
      );
      expect(u.state.steps, hasLength(1));
      expect(u.state.dice, [2, 5]);
    });

    test('D8b mother deferred until the pinner leaves its start', () {
      // As D8a, but two keeps a checker on its 24 (= my 1).
      final p = pos(one: {24: 1, 6: 14}, two: {3: 1, 24: 1, 13: 13});
      final s = ok(twoToRoll(plakoto, p), const RollDice(2, 4)).state;
      final pinned = ok(s, const StepAction(Step(3, 1, 2))).state;
      expect(pinned.phase, GamePhase.moving);
      expect(pinned.position.isPinned(S.one, 24), isTrue);
      final u = ok(pinned, const StepAction(Step(24, 20, 4)));
      expect(u.state.phase, GamePhase.gameOver);
      expect(u.state.result?.winner, S.two);
      expect(u.state.result?.kind, ResultKind.mother);
      expect(u.state.result?.points, 2);
    });

    test('D8 both mothers pinned: Plakoto draw 0, Tapa 1 each', () {
      // My mother is pinned by two's checker on its 1; two's mother sits
      // alone on its 24 (= my 1). My 3 -> 1 pins it.
      final p = pos(
        one: {24: 1, 3: 1, 6: 13},
        two: {24: 1, 1: 1, 13: 13},
        pinnedOne: {24},
      );
      for (final (v, points) in [
        (Variant.plakoto, 0),
        (Variant.tapa, 1),
        (Variant.mahbusa, 0),
      ]) {
        final s = ok(
          GameState.initial(v, starter: S.one).withPosition(p),
          const RollDice(2, 5),
        ).state;
        final u = ok(s, const StepAction(Step(3, 1, 2)));
        expect(
          u.state.result,
          GameResult(
              winner: null,
              kind: ResultKind.draw,
              points: points,
              cubeValue: 1),
          reason: v.name,
        );
      }
    });

    test('G8 the reducer scores a gammon', () {
      final p = pos(one: {1: 1}, two: {6: 15});
      final s = ok(
              GameState.initial(Variant.portes, starter: S.one).withPosition(p),
              const RollDice(3, 1))
          .state;
      final u = ok(s, const StepAction(Step(1, 0, 3)));
      expect(
          u.state.result,
          const GameResult(
              winner: S.one, kind: ResultKind.gammon, points: 2, cubeValue: 1));
    });
  });

  group('across turns', () {
    const plakoto = Variant.plakoto;

    test('D8b the deferred mother win fires on a later turn', () {
      // Two pins my mother but keeps a checker on its own 24 (= my 1).
      final p = pos(one: {24: 1, 10: 14}, two: {3: 1, 24: 1, 13: 13});
      var s = GameState.initial(plakoto, starter: S.two).withPosition(p);
      s = play(s, const [
        RollDice(2, 4),
        StepAction(Step(3, 1, 2)),
        StepAction(Step(13, 9, 4)),
        CommitPlay(),
      ]);
      expect(s.phase, GamePhase.awaitingRoll);
      expect(s.position.isPinned(S.one, 24), isTrue);
      // My turn passes without changing that (10->4, 10->7).
      s = play(s, const [
        RollDice(6, 3),
        StepAction(Step(10, 4, 6)),
        StepAction(Step(10, 7, 3)),
        CommitPlay(),
      ]);
      expect(s.phase, GamePhase.awaitingRoll);
      // Two's last start checker leaves: two wins 2 at once.
      s = ok(s, const RollDice(4, 1)).state;
      final u = ok(s, const StepAction(Step(24, 20, 4)));
      expect(
          u.state.result,
          const GameResult(
              winner: S.two, kind: ResultKind.mother, points: 2, cubeValue: 1));
    });

    test('D8 the pinner\'s own mother pinned next turn: a draw', () {
      // As above, and my 3 can reach my 1 (= two's 24, its lone mother).
      final p = pos(one: {24: 1, 3: 1, 10: 13}, two: {3: 1, 24: 1, 13: 13});
      for (final (v, points) in const [
        (Variant.plakoto, 0),
        (Variant.tapa, 1),
      ]) {
        var s = GameState.initial(v, starter: S.two).withPosition(p);
        s = play(s, const [
          RollDice(2, 4),
          StepAction(Step(3, 1, 2)),
          StepAction(Step(13, 9, 4)),
          CommitPlay(),
          RollDice(2, 5),
        ]);
        final u = ok(s, const StepAction(Step(3, 1, 2)));
        expect(
          u.state.result,
          GameResult(
              winner: null,
              kind: ResultKind.draw,
              points: points,
              cubeValue: 1),
          reason: v.name,
        );
      }
    });

    test('D21 Tawla 31 scores the loser\'s checkers through the reducer', () {
      final p = posSame(one: {2: 1}, two: {3: 4, 1: 2});
      final s =
          GameState.initial(Variant.tawla31, starter: S.one).withPosition(p);
      final u = ok(
          ok(s, const RollDice(5, 1)).state, const StepAction(Step(2, 0, 5)));
      expect(
        u.state.result,
        const GameResult(
            winner: S.one,
            kind: ResultKind.checkersRemaining,
            points: 6,
            cubeValue: 1),
      );
    });
  });

  group('withPosition rejects finished positions', () {
    test('a pinned mother whose pinner has left its start', () {
      // The reviewer's repro: one's mother pinned by two; two's start empty.
      final p = pos(
        one: {24: 1, 6: 14},
        two: {1: 1, 13: 14},
        pinnedOne: {24},
      );
      final s = GameState.initial(Variant.plakoto, starter: S.one);
      expect(() => s.withPosition(p), throwsArgumentError);
      // The same board with two's checker off my 24 is still in play.
      expect(
        s.withPosition(pos(one: {24: 1, 6: 14}, two: {2: 1, 13: 14})).position,
        isNotNull,
      );
    });

    test('both mothers pinned, or a side with all 15 off', () {
      final both = pos(
        one: {24: 1, 1: 1, 10: 13},
        two: {24: 1, 1: 1, 13: 13},
        pinnedOne: {24},
        pinnedTwo: {24},
      );
      expect(
        () => GameState.initial(Variant.plakoto, starter: S.one)
            .withPosition(both),
        throwsArgumentError,
      );
      for (final p in [
        pos(one: {}, two: {6: 15}),
        pos(one: {6: 15}, two: {}),
      ]) {
        expect(
          () =>
              GameState.initial(Variant.portes, starter: S.one).withPosition(p),
          throwsArgumentError,
        );
      }
    });
  });
}
