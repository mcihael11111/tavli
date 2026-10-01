import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/positions.dart';

typedef S = Side;

/// [a] must be accepted; returns the new match state.
MatchState step(MatchState m, MatchAction a, {S? by}) {
  final r = reduceMatch(m, a, by: by);
  expect(r, isA<MatchUpdate>(), reason: '$a -> $r');
  return (r as MatchUpdate).state;
}

/// [loser] resigns the current game (A9 scores the threat), then, unless
/// the match is over, the next game starts.
MatchState resignGame(MatchState m, S loser) {
  m = step(m, GameMove(Resign(loser)));
  return m.isOver ? m : step(m, const NextGame());
}

void main() {
  group('MatchConfig', () {
    test('single, to, and Tawla 31 forcing 31', () {
      final single = MatchConfig.single(Variant.portes);
      expect(single.cycle, [Variant.portes]);
      expect(single.target, isNull);
      expect(single.cubeEnabled, isFalse);
      expect(MatchConfig.single(Variant.shortNard).cubeEnabled, isTrue);
      expect(MatchConfig.single(Variant.longNard).cubeEnabled, isFalse);
      expect(
        MatchConfig.single(Variant.longNard, cubeEnabled: true).cubeEnabled,
        isTrue,
      );
      expect(MatchConfig.to(5, MatchConfig.tavliMarathon).target, 5);
      expect(MatchConfig.to(5, [Variant.tawla31]).target, 31);
      expect(MatchConfig.single(Variant.tawla31).target, 31);
      expect(() => MatchConfig.to(0, [Variant.portes]), throwsArgumentError);
      expect(() => MatchConfig.to(3, []), throwsArgumentError);
      expect(() => single.cycle.add(Variant.fevga), throwsUnsupportedError);
    });
  });

  test('Tavli marathon rotation', () {
    var m = MatchState.initial(MatchConfig.to(99, MatchConfig.tavliMarathon));
    final seen = [m.game.variant];
    for (var i = 0; i < 4; i++) {
      m = resignGame(m, i.isEven ? S.one : S.two);
      seen.add(m.game.variant);
    }
    expect(seen, [
      Variant.portes,
      Variant.plakoto,
      Variant.fevga,
      Variant.portes,
      Variant.plakoto,
    ]);
    expect(m.gameIndex, 4);
    expect(m.history, hasLength(4));
  });

  test('D2 previous winner starts in Tavli; opening roll in Tavla', () {
    var m = MatchState.initial(MatchConfig.to(9, MatchConfig.tavliMarathon));
    expect(m.game.phase, GamePhase.opening);
    m = resignGame(m, S.one); // two wins Portes
    expect(m.game.variant, Variant.plakoto);
    expect(m.game.phase, GamePhase.awaitingRoll);
    expect(m.game.sideToMove, S.two);

    var t = MatchState.initial(MatchConfig.to(9, [Variant.tavla]));
    t = resignGame(t, S.one);
    expect(t.game.phase, GamePhase.opening);
    expect(t.game.sideToMove, isNull);
  });

  test('D2 a Plakoto draw leads to an opening roll', () {
    // Both mothers end up pinned: my 3 -> 1 pins two's lone mother while
    // mine is pinned.
    final p = pos(
      one: {24: 1, 3: 1, 6: 13},
      two: {24: 1, 1: 1, 13: 13},
      pinnedOne: {24},
    );
    final config = MatchConfig.to(5, [Variant.plakoto]);
    var m = MatchState(
      config: config,
      scores: const {S.one: 0, S.two: 0},
      gameIndex: 0,
      game: GameState.initial(Variant.plakoto, starter: S.one).withPosition(p),
      history: const [],
      crawfordUsed: false,
      winner: null,
    );
    m = step(m, const GameMove(RollDice(2, 5)));
    final u = reduceMatch(m, const GameMove(StepAction(Step(3, 1, 2))));
    m = (u as MatchUpdate).state;
    expect(u.events.last, isA<GameEnded>());
    expect(m.history.single.kind, ResultKind.draw);
    expect(m.scores, {S.one: 0, S.two: 0});
    m = step(m, const NextGame());
    expect(m.game.phase, GamePhase.opening);
    expect(m.game.sideToMove, isNull);
  });

  test('a draw scores for both sides (Tapa 1 each)', () {
    final p = pos(
      one: {24: 1, 3: 1, 6: 13},
      two: {24: 1, 1: 1, 13: 13},
      pinnedOne: {24},
    );
    var m = MatchState(
      config: MatchConfig.to(5, [Variant.tapa]),
      scores: const {S.one: 2, S.two: 3},
      gameIndex: 3,
      game: GameState.initial(Variant.tapa, starter: S.one).withPosition(p),
      history: const [],
      crawfordUsed: false,
      winner: null,
    );
    m = step(m, const GameMove(RollDice(2, 5)));
    m = step(m, const GameMove(StepAction(Step(3, 1, 2))));
    expect(m.scores, {S.one: 3, S.two: 4});
    expect(m.isOver, isFalse);
  });

  test('the match ends at the target', () {
    // Resigning at the start concedes a gammon (A9): 2 points.
    var m = MatchState.initial(MatchConfig.to(3, [Variant.portes]));
    m = resignGame(m, S.two);
    expect(m.scores, {S.one: 2, S.two: 0});
    expect(m.isOver, isFalse);
    m = resignGame(m, S.two);
    expect(m.scores, {S.one: 4, S.two: 0});
    expect(m.isOver, isTrue);
    expect(m.winner, S.one);
    final r = reduceMatch(m, const NextGame());
    expect((r as RuleViolation).code, ViolationCode.gameOver);
    expect(
        reduceMatch(m, const GameMove(RollDice(3, 1))), isA<RuleViolation>());
  });

  test('a single game is over when its game is', () {
    var m = MatchState.initial(MatchConfig.single(Variant.fevga));
    expect(m.isOver, isFalse);
    m = step(m, const GameMove(Resign(S.one)));
    expect(m.isOver, isTrue);
    expect(m.winner, isNull, reason: 'no target');
    expect(m.history.single.winner, S.two);
    expect((reduceMatch(m, const NextGame()) as RuleViolation).code,
        ViolationCode.gameOver);
  });

  test('the Crawford game is flagged once', () {
    // Long Nard to 5 with the cube: each resignation at the start is a
    // gammon (2). 2-0, 4-0 (match point: Crawford), 4-2, 4-4.
    var m = MatchState.initial(
      MatchConfig.to(5, [Variant.longNard], cubeEnabled: true),
    );
    m = resignGame(m, S.two);
    expect(m.game.crawfordGame, isFalse);
    m = resignGame(m, S.two);
    expect(m.scores[S.one], 4);
    expect(m.game.crawfordGame, isTrue);
    expect(m.crawfordUsed, isTrue);
    m = resignGame(m, S.one);
    expect(m.scores, {S.one: 4, S.two: 2});
    expect(m.game.crawfordGame, isFalse, reason: 'post-Crawford');
    m = resignGame(m, S.one);
    expect(m.scores, {S.one: 4, S.two: 4});
    expect(m.game.crawfordGame, isFalse, reason: 'only once');
  });

  test('Crawford refuses the cube in the Crawford game', () {
    // Short Nard resigned at the start is koks (3), so play to 4.
    var m = MatchState.initial(
      MatchConfig.to(4, [Variant.shortNard], cubeEnabled: true),
    );
    m = resignGame(m, S.two);
    expect(m.scores[S.one], 3);
    expect(m.game.crawfordGame, isTrue);
    m = step(m, const GameMove(RollOpening(2, 1)));
    // One plays its opening; two may not double.
    while (m.game.phase == GamePhase.moving) {
      final n = m.game.node;
      m = step(
        m,
        GameMove(
            n.isComplete ? const CommitPlay() : StepAction(n.nextSteps.first)),
      );
    }
    final r = reduceMatch(m, const GameMove(OfferDouble()));
    expect((r as RuleViolation).code, ViolationCode.cannotDouble);
  });

  test('D21 Tawla 31 reaches 31 across games', () {
    var m = MatchState.initial(MatchConfig.single(Variant.tawla31));
    expect(m.config.target, 31);
    m = resignGame(m, S.two);
    expect(m.scores[S.one], 15);
    expect(m.isOver, isFalse);
    m = resignGame(m, S.two);
    expect(m.isOver, isFalse);
    m = resignGame(m, S.two);
    expect(m.scores[S.one], 45);
    expect(m.isOver, isTrue);
    expect(m.winner, S.one);
    expect(m.history.map((r) => r.points), [15, 15, 15]);
  });

  test('NextGame before the game is over is rejected', () {
    final m = MatchState.initial(MatchConfig.to(3, [Variant.portes]));
    expect((reduceMatch(m, const NextGame()) as RuleViolation).code,
        ViolationCode.wrongPhase);
  });

  test('game moves pass through, with violations and the sender', () {
    final m = MatchState.initial(MatchConfig.to(3, [Variant.portes]));
    expect(
        (reduceMatch(m, const GameMove(RollDice(3, 1))) as RuleViolation).code,
        ViolationCode.wrongPhase);
    final opened = step(m, const GameMove(RollOpening(5, 2)));
    expect(opened.game.sideToMove, S.one);
    final r = reduceMatch(opened, const GameMove(StepAction(Step(13, 8, 5))),
        by: S.two);
    expect((r as RuleViolation).code, ViolationCode.notYourAction);
    expect(
        step(opened, const GameMove(StepAction(Step(13, 8, 5))), by: S.one)
            .game
            .steps,
        hasLength(1));
  });

  test('MatchState equality and immutability', () {
    final a = MatchState.initial(MatchConfig.to(3, [Variant.portes]));
    final b = MatchState.initial(MatchConfig.to(3, [Variant.portes]));
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(resignGame(a, S.one), resignGame(b, S.one));
    expect(a, isNot(resignGame(a, S.one)));
    expect(() => a.scores[S.one] = 3, throwsUnsupportedError);
    expect(
        () => a.history.add(const GameResult(
            winner: null, kind: ResultKind.draw, points: 0, cubeValue: 1)),
        throwsUnsupportedError);
  });
}
