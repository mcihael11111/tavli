import 'dart:convert';

import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/positions.dart';

typedef S = Side;

/// [a] must be accepted; returns the update.
MatchUpdate up(MatchState m, MatchAction a, {S? by}) {
  final r = reduceMatch(m, a, by: by);
  expect(r, isA<MatchUpdate>(), reason: '$a -> $r');
  return r as MatchUpdate;
}

/// [a] must be rejected with [code].
void refused(MatchState m, MatchAction a, ViolationCode code, {S? by}) {
  final r = reduceMatch(m, a, by: by);
  expect(r, isA<RuleViolation>(), reason: '$a');
  expect((r as RuleViolation).code, code, reason: r.message);
}

/// Through a JSON string and back, as over the wire.
Object? wire(Object? json) => jsonDecode(jsonEncode(json));

/// What resigning [m]'s current game would score.
GameResult resignResult(MatchState m, S loser) =>
    ((reduce(m.game, Resign(loser)) as GameUpdate).events.last as GameEnded)
        .result;

/// A Plakoto/Tapa board where one's 3 -> 1 (with a 2) pins two's lone
/// mother while one's own is pinned: a draw.
final _drawBoard = pos(
  one: {24: 1, 3: 1, 6: 13},
  two: {24: 1, 1: 1, 13: 13},
  pinnedOne: {24},
);

void main() {
  group('a single game decides the match', () {
    test('its winner is the match winner', () {
      final m = up(MatchState.initial(MatchConfig.single(Variant.fevga)),
              const GameMove(Resign(S.one)))
          .state;
      expect(m.isOver, isTrue);
      expect(m.winner, S.two);
      expect(MatchState.fromJson(wire(m.toJson())), m);
    });

    test('a draw has no winner', () {
      var m = MatchState(
        config: MatchConfig.single(Variant.plakoto),
        scores: const {S.one: 0, S.two: 0},
        gameIndex: 0,
        game: GameState.initial(Variant.plakoto, starter: S.one)
            .withPosition(_drawBoard),
        history: const [],
        crawfordUsed: false,
        winner: null,
      );
      m = up(m, const GameMove(RollDice(2, 5))).state;
      final u = up(m, const GameMove(StepAction(Step(3, 1, 2))));
      expect(u.state.isOver, isTrue);
      expect(u.state.winner, isNull);
      expect(u.events.last, MatchEnded(null, const {S.one: 0, S.two: 0}));
      expect(MatchState.fromJson(wire(u.state.toJson())), u.state);
    });
  });

  group('match events', () {
    test('game events arrive wrapped in InGame', () {
      final m = MatchState.initial(MatchConfig.to(5, [Variant.portes]));
      const a = RollOpening(5, 2);
      final u = up(m, const GameMove(a));
      final game = (reduce(m.game, a) as GameUpdate).events;
      expect(u.events, [for (final e in game) InGame(e)]);
      expect(() => u.events.add(InGame(game.first)), throwsUnsupportedError);
    });

    test('NextGame reports the game it starts', () {
      var m = MatchState.initial(MatchConfig.to(9, MatchConfig.tavliMarathon));
      m = up(m, const GameMove(Resign(S.one))).state;
      expect(up(m, const NextGame()).events,
          [const GameStarted(1, Variant.plakoto, S.two, false)]);

      var t = MatchState.initial(MatchConfig.to(4, [Variant.shortNard]));
      t = up(t, const GameMove(Resign(S.two))).state; // one 3: Crawford
      final u = up(t, const NextGame());
      expect(u.events, [const GameStarted(1, Variant.shortNard, null, true)]);
      expect(u.state.game.crawfordGame, isTrue);
    });

    test('the game that decides the match is followed by MatchEnded', () {
      var m = MatchState.initial(MatchConfig.to(3, [Variant.portes]));
      final first = up(m, const GameMove(Resign(S.two)));
      expect(first.events.whereType<MatchEnded>(), isEmpty);
      m = up(first.state, const NextGame()).state;
      final r = resignResult(m, S.two);
      final u = up(m, const GameMove(Resign(S.two)));
      expect(u.events, [
        InGame(GameEnded(r)),
        MatchEnded(S.one, const {S.one: 4, S.two: 0}),
      ]);
    });

    test('events are values', () {
      final a = MatchEnded(S.one, {S.one: 3, S.two: 1});
      final b = MatchEnded(S.one, {S.two: 1, S.one: 3});
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(MatchEnded(S.two, const {S.one: 3, S.two: 1})));
      expect(() => a.scores[S.one] = 9, throwsUnsupportedError);
      expect(const GameStarted(2, Variant.fevga, null, false),
          isNot(const GameStarted(2, Variant.fevga, S.one, false)));
      expect(InGame(DiceRolled(S.one, const [3, 1])),
          InGame(DiceRolled(S.one, const [3, 1])));
    });
  });

  group('ForfeitMatch', () {
    test('mid-game: the game is resigned, the opponent wins regardless', () {
      final m = MatchState(
        config: MatchConfig.to(9, [Variant.portes]),
        scores: const {S.one: 8, S.two: 0},
        gameIndex: 2,
        game: GameState.initial(Variant.portes, starter: S.one),
        history: const [],
        crawfordUsed: true,
        winner: null,
      );
      final r = resignResult(m, S.one);
      final u = up(m, const ForfeitMatch(S.one));
      final scores = {S.one: 8, S.two: r.points};
      expect(u.events, [InGame(GameEnded(r)), MatchEnded(S.two, scores)]);
      expect(u.state.winner, S.two);
      expect(u.state.isOver, isTrue);
      expect(u.state.scores, scores);
      expect(u.state.history, [r]);
      expect(u.state.forfeitedBy, S.one);
      refused(u.state, const NextGame(), ViolationCode.gameOver);
      refused(u.state, const ForfeitMatch(S.two), ViolationCode.gameOver);
      expect(MatchState.fromJson(wire(u.state.toJson())), u.state);
    });

    test('between games: only MatchEnded; scores stay', () {
      var m = MatchState.initial(MatchConfig.to(9, [Variant.portes]));
      m = up(m, const GameMove(Resign(S.one))).state;
      expect(m.isOver, isFalse);
      final u = up(m, const ForfeitMatch(S.two));
      expect(u.events, [MatchEnded(S.one, m.scores)]);
      expect(u.state.scores, m.scores);
      expect(u.state.history, m.history);
      expect(u.state.winner, S.one);
    });

    test('a single game: forfeiting it ends the match', () {
      final m = MatchState.initial(MatchConfig.single(Variant.portes));
      final u = up(m, const ForfeitMatch(S.two));
      expect(u.events, hasLength(2));
      expect(u.events.last, MatchEnded(S.one, u.state.scores));
      expect(u.state.winner, S.one);
      expect(u.state.history.single.kind, ResultKind.resign);
    });

    test('only by the forfeiting side', () {
      final m = MatchState.initial(MatchConfig.to(3, [Variant.portes]));
      expect(matchActorOf(m, const ForfeitMatch(S.one)), S.one);
      expect(matchActorOf(m, const NextGame()), isNull);
      expect(matchActorOf(m, const GameMove(RollOpening(3, 1))), isNull);
      refused(m, const ForfeitMatch(S.one), ViolationCode.notYourAction,
          by: S.two);
      expect(up(m, const ForfeitMatch(S.one), by: S.one).state.winner, S.two);
    });

    test('JSON: the action, the state and a log', () {
      const a = ForfeitMatch(S.two);
      expect(MatchAction.fromJson(wire(a.toJson())), a);
      expect(a, isNot(const ForfeitMatch(S.one)));
      expect(() => MatchAction.fromJson({'type': 'forfeitMatch'}),
          throwsFormatException);
      final config = MatchConfig.to(5, MatchConfig.tavliMarathon);
      final log = GameLog(config, const [
        GameMove(RollOpening(5, 2)),
        ForfeitMatch(S.two),
      ]);
      final end = replay(GameLog.fromJson(wire(log.toJson())));
      expect(end.winner, S.one);
      expect(end.forfeitedBy, S.two);
      // A forfeit must name the loser of the match.
      final j = end.toJson()..['winner'] = 'two';
      expect(() => MatchState.fromJson(wire(j)), throwsFormatException);
    });
  });
}
