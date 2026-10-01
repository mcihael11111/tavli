import 'dart:convert';
import 'dart:math';

import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/random_play.dart';
import '../support/reducer.dart';

typedef S = Side;

/// Portes, one to play 3-1 from the start.
GameState _portes31() =>
    ok(GameState.initial(Variant.portes, starter: S.one), const RollDice(3, 1))
        .state;

/// [steps] played one [StepAction] at a time, then committed unless a
/// step ended the game: the state and every event on the way.
GameUpdate _stepwise(GameState s, List<Step> steps) {
  final events = <GameEvent>[];
  for (final st in steps) {
    final u = ok(s, StepAction(st));
    s = u.state;
    events.addAll(u.events);
  }
  if (s.phase != GamePhase.gameOver) {
    final u = ok(s, const CommitPlay());
    s = u.state;
    events.addAll(u.events);
  }
  return GameUpdate(s, events);
}

/// A random complete play of [s]'s tree (stopping at a game end).
List<Step> _randomPlay(GameState s, Random r) {
  final out = <Step>[];
  var node = s.node;
  var cur = s;
  while (!node.isComplete && cur.phase != GamePhase.gameOver) {
    final next = node.nextSteps.toList();
    final st = next[r.nextInt(next.length)];
    out.add(st);
    node = node.child(st)!;
    cur = ok(cur, StepAction(st)).state;
  }
  return out;
}

void main() {
  test('a legal play equals the same steps and commit one by one', () {
    final s = _portes31();
    const steps = [Step(8, 5, 3), Step(6, 5, 1)];
    final u = ok(s, SubmitPlay(steps));
    final want = _stepwise(s, steps);
    expect(u.state, want.state);
    expect(u.events, want.events);
    expect(u.events.last, PlayCommitted(S.one, steps));
    expect(u.state.sideToMove, S.two);
  });

  test('an incomplete play is rejected and nothing changes', () {
    rejects(_portes31(), SubmitPlay(const [Step(8, 5, 3)]),
        ViolationCode.incompletePlay);
    rejects(_portes31(), SubmitPlay(const []), ViolationCode.incompletePlay);
  });

  test('an illegal step anywhere in the play is rejected', () {
    final s = _portes31();
    rejects(s, SubmitPlay(const [Step(8, 4, 4), Step(6, 5, 1)]),
        ViolationCode.illegalStep);
    rejects(s, SubmitPlay(const [Step(8, 5, 3), Step(8, 5, 3)]),
        ViolationCode.illegalStep);
    rejects(s, SubmitPlay(const [Step(8, 5, 3), Step(6, 5, 1), Step(6, 5, 1)]),
        ViolationCode.illegalStep);
  });

  group('a game-ending step', () {
    GameState lastChecker() => ok(
          GameState.initial(Variant.portes, starter: S.one).withPosition(
            Position.fromPips(
              one: const {1: 1},
              two: const {6: 15},
              direction: Direction.opposing,
            ),
          ),
          const RollDice(3, 1),
        ).state;

    test('ends the game like a StepAction; no commit follows', () {
      final s = lastChecker();
      const steps = [Step(1, 0, 3)];
      final u = ok(s, SubmitPlay(steps));
      final want = _stepwise(s, steps);
      expect(u.state, want.state);
      expect(u.events, want.events);
      expect(u.state.phase, GamePhase.gameOver);
      expect(u.events.last, isA<GameEnded>());
    });

    test('must be the last step', () {
      rejects(
        lastChecker(),
        SubmitPlay(const [Step(1, 0, 3), Step(1, 0, 1)]),
        ViolationCode.illegalStep,
      );
    });
  });

  test('only at the start of a moving phase, by the side to move', () {
    final s = _portes31();
    rejects(GameState.initial(Variant.portes, starter: S.one),
        SubmitPlay(const [Step(8, 5, 3)]), ViolationCode.wrongPhase);
    rejects(ok(s, const StepAction(Step(8, 5, 3))).state,
        SubmitPlay(const [Step(6, 5, 1)]), ViolationCode.wrongPhase);
    final play = SubmitPlay(const [Step(8, 5, 3), Step(6, 5, 1)]);
    expect(actorOf(s, play), S.one);
    rejects(s, play, ViolationCode.notYourAction, by: S.two);
    expect(reduce(s, play, by: S.one), isA<GameUpdate>());
  });

  test('random plays of every variant equal step-by-step play', () {
    final r = Random(11);
    var plays = 0;
    for (final v in Variant.values) {
      var s = GameState.initial(v, cubeEnabled: true);
      for (var i = 0; i < 300 && s.phase != GamePhase.gameOver; i++) {
        if (s.phase == GamePhase.moving && s.steps.isEmpty) {
          final steps = _randomPlay(s, r);
          final u = ok(s, SubmitPlay(steps));
          final want = _stepwise(s, steps);
          expect(u.state, want.state, reason: '${v.name} $steps');
          expect(u.events, want.events, reason: '${v.name} $steps');
          s = u.state;
          plays++;
        } else {
          final res = reduce(s, randomLegalAction(s, r)!);
          if (res is GameUpdate) s = res.state;
        }
      }
    }
    expect(plays, greaterThan(100));
  });

  group('JSON', () {
    test('round-trips, and malformed steps are FormatException', () {
      final a = SubmitPlay(const [Step(8, 5, 3), Step(6, 5, 1)]);
      final back = GameAction.fromJson(jsonDecode(jsonEncode(a.toJson())));
      expect(back, a);
      expect(back.hashCode, a.hashCode);
      expect(a.toJson()['type'], 'submitPlay');
      expect(GameAction.fromJson(SubmitPlay(const []).toJson()),
          SubmitPlay(const []));
      expect(SubmitPlay(const [Step(8, 5, 3)]), isNot(a));
      // A copy: changing the caller's list later changes nothing.
      final mine = [const Step(8, 5, 3)];
      final copy = SubmitPlay(mine);
      mine.add(const Step(6, 5, 1));
      expect(copy.steps, hasLength(1));
      expect(() => a.steps.add(const Step(6, 5, 1)), throwsUnsupportedError);
      for (final bad in <Object?>[
        null,
        3,
        [3],
        [
          {'from': 3, 'to': 1, 'die': 5},
        ],
      ]) {
        expect(
          () => GameAction.fromJson({'type': 'submitPlay', 'steps': bad}),
          throwsFormatException,
          reason: '$bad',
        );
      }
    });

    test('a log of submitted plays replays to the live state', () {
      final config = MatchConfig.single(Variant.plakoto);
      var m = MatchState.initial(config);
      var log = GameLog(config, const []);
      final r = Random(3);
      for (var i = 0; i < 200 && !m.isOver; i++) {
        final g = m.game;
        final a = g.phase == GamePhase.moving
            ? SubmitPlay(_randomPlay(g, r))
            : randomLegalAction(g, r)!;
        final res = reduceMatch(m, GameMove(a));
        if (res is MatchUpdate) {
          m = res.state;
          log = log.add(GameMove(a));
        }
      }
      expect(log.actions.whereType<GameMove>().map((g) => g.action),
          contains(isA<SubmitPlay>()));
      final back = GameLog.fromJson(jsonDecode(jsonEncode(log.toJson())));
      expect(replay(back), m);
    });
  });
}
