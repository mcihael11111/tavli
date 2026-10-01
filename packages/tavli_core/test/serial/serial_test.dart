import 'dart:convert';
import 'dart:math';

import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/random_play.dart';
import '../support/reducer.dart';

typedef S = Side;

/// Through a JSON string and back, as over the wire.
Object? wire(Object? json) => jsonDecode(jsonEncode(json));

/// Plays a match of [config] with random legal actions to its end (at
/// most [maxGames] games); returns the log and the live final state.
(GameLog, MatchState) playMatch(MatchConfig config, Random r,
    {int maxGames = 2}) {
  var m = MatchState.initial(config);
  var log = GameLog(config, const []);
  while (true) {
    final GameAction? g = randomLegalAction(m.game, r);
    final MatchAction a;
    if (g != null) {
      a = GameMove(g);
    } else if (!m.isOver && m.gameIndex + 1 < maxGames) {
      a = const NextGame();
    } else {
      return (log, m);
    }
    final res = reduceMatch(m, a);
    if (res is MatchUpdate) {
      m = res.state;
      log = log.add(a);
    }
  }
}

void main() {
  test('every MatchAction round-trips, with every GameAction inside', () {
    for (final a in const <MatchAction>[
      NextGame(),
      GameMove(RollOpening(5, 2)),
      GameMove(RollDice(6, 6)),
      GameMove(StepAction(Step(3, 0, 5))),
      GameMove(UndoStep()),
      GameMove(CommitPlay()),
      GameMove(OfferDouble()),
      GameMove(Take()),
      GameMove(Drop()),
      GameMove(Resign(S.one)),
      GameMove(ClockTimeout(S.two)),
    ]) {
      expect(MatchAction.fromJson(wire(a.toJson())), a);
    }
    for (final bad in <Object?>[
      null,
      {'type': 'gameMove'},
      {'type': 'gameMove', 'action': 3},
      {'type': 'later'},
    ]) {
      expect(() => MatchAction.fromJson(bad), throwsFormatException);
    }
  });

  test('a mid-turn state round-trips with equal next steps', () {
    final s = play(GameState.initial(Variant.portes, starter: S.one), const [
      RollDice(3, 1),
      StepAction(Step(13, 10, 3)),
    ]);
    final back = GameState.fromJson(wire(s.toJson()));
    expect(back, s);
    expect(back.hashCode, s.hashCode);
    expect(back.position, s.position);
    expect(back.context, s.context);
    expect(back.node.nextSteps.toList(), s.node.nextSteps.toList());
    expect(back.node.nextSteps, contains(const Step(10, 9, 1)));
  });

  test('replay of a scripted Plakoto game equals the live-built state', () {
    final (log, live) =
        playMatch(MatchConfig.single(Variant.plakoto), Random(11));
    expect(live.game.phase, GamePhase.gameOver);
    expect(log.actions.length, greaterThan(50));
    final back = GameLog.fromJson(wire(log.toJson()));
    expect(back.actions, log.actions);
    expect(back.config, log.config);
    final replayed = replay(back);
    expect(replayed, live);
    expect(MatchState.fromJson(wire(live.toJson())), live);
  });

  test('every state of random matches round-trips (all variants)', () {
    final r = Random(5);
    var states = 0;
    for (final v in Variant.values) {
      final config = MatchConfig.to(3, [v], cubeEnabled: true);
      var m = MatchState.initial(config);
      var log = GameLog(config, const []);
      for (var i = 0; i < 400; i++) {
        final g = randomLegalAction(m.game, r);
        final MatchAction a = g == null ? const NextGame() : GameMove(g);
        final res = reduceMatch(m, a);
        if (res is! MatchUpdate) {
          if (m.isOver) break;
          continue;
        }
        m = res.state;
        log = log.add(a);
        states++;
        expect(GameState.fromJson(wire(m.game.toJson())), m.game);
        expect(MatchState.fromJson(wire(m.toJson())), m);
      }
      expect(replay(GameLog.fromJson(wire(log.toJson()))), m, reason: '$v');
    }
    expect(states, greaterThan(2000));
  });

  group('schema version', () {
    final m = MatchState.initial(MatchConfig.single(Variant.portes));
    for (final (name, json, read) in [
      ('GameLog', GameLog(m.config, const []).toJson(), GameLog.fromJson),
      ('GameState', m.game.toJson(), GameState.fromJson),
      ('MatchState', m.toJson(), MatchState.fromJson),
    ]) {
      test('$name: an unknown schema version throws', () {
        expect(read(json), isNotNull);
        for (final v in [0, 2, '1', null]) {
          expect(
              () => read({...json, 'schemaVersion': v}), throwsFormatException,
              reason: '$v');
        }
      });
    }
    test('the barrel exposes version 1', () {
      expect(tavliCoreSchemaVersion, 1);
    });
  });

  test('replay rejects a corrupt log with a FormatException', () {
    final log = GameLog(MatchConfig.single(Variant.portes), const [
      GameMove(RollDice(3, 1)), // still in the opening
    ]);
    expect(() => replay(log), throwsFormatException);
  });

  test('inconsistent states are rejected', () {
    final s = play(GameState.initial(Variant.portes, starter: S.one), const [
      RollDice(3, 1),
      StepAction(Step(13, 10, 3)),
    ]);
    final j = s.toJson();
    for (final (key, value) in [
      ('steps', [const Step(13, 12, 1).toJson()]), // not in the tree
      ('dice', [3, 3]), // not a roll shape
      ('phase', 'awaitingRoll'), // dice outside moving
      ('sideToMove', null),
      ('cascadeMode', true), // Portes has no cascade
      ('remainderTurn', true),
      (
        'result',
        {
          'winner': 'one',
          'kind': 'single',
          'points': 1,
          'cubeValue': 1,
        }
      ),
      ('cube', {'value': 2, 'owner': null, 'offeredBy': null, 'enabled': true}),
      ('variant', 'fevga'), // wrong direction for the board
    ]) {
      expect(
          () => GameState.fromJson({...j, key: value}), throwsFormatException,
          reason: key);
    }
  });
}
