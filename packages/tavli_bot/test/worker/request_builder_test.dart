import 'dart:math';

import 'package:tavli_bot/tavli_bot.dart';
import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

/// A state to ask about, with the state at the start of its play (the same
/// state when no step has been taken).
typedef _Sample = ({GameState s, GameState turnStart});

GameState _apply(GameState s, GameAction a) => switch (reduce(s, a)) {
      GameUpdate(:final state) => state,
      RuleViolation() && final v => throw StateError('$a in $s: $v'),
    };

GameState? _try(GameState s, GameAction a) => switch (reduce(s, a)) {
      GameUpdate(:final state) => state,
      RuleViolation() => null,
    };

/// Random legal games of [v]: samples at every turn start, after random
/// step prefixes (mid-turn, including Gul Bara remainder turns), before
/// rolls (cube offers) and at offered doubles. Plays games until
/// [minMoving] moving samples were taken (and, for Gul Bara, [minRemainder]
/// remainder-turn samples), at most [maxGames] games of [maxTurns] turns.
List<_Sample> _samples(
  Variant v,
  Random rng, {
  int minMoving = 60,
  int minRemainder = 0,
  int maxGames = 60,
  int maxTurns = 60,
}) {
  final out = <_Sample>[];
  var moving = 0, remainder = 0;
  for (var g = 0; g < maxGames; g++) {
    if (moving >= minMoving && remainder >= minRemainder) break;
    var s = GameState.initial(v, cubeEnabled: v.rules.cube.available);
    for (var turn = 0; turn < maxTurns; turn++) {
      if (s.phase == GamePhase.gameOver) break;
      switch (s.phase) {
        case GamePhase.opening:
          s = _apply(s, RollOpening(rng.nextInt(6) + 1, rng.nextInt(6) + 1));
        case GamePhase.awaitingRoll:
          final offered = _try(s, const OfferDouble());
          if (offered != null) {
            out.add((s: s, turnStart: s));
            if (rng.nextDouble() < 0.2) {
              out.add((s: offered, turnStart: offered));
              s = _apply(offered, const Take());
            }
          }
          s = _apply(s, RollDice(rng.nextInt(6) + 1, rng.nextInt(6) + 1));
        case GamePhase.moving:
          final start = s;
          out.add((s: s, turnStart: start));
          moving++;
          if (s.remainderTurn) remainder++;
          while (s.phase == GamePhase.moving) {
            final node = s.node;
            final next = node.nextSteps.toList();
            if (node.isComplete && (next.isEmpty || rng.nextBool())) {
              s = _apply(s, const CommitPlay());
              break;
            }
            s = _apply(s, StepAction(next[rng.nextInt(next.length)]));
            if (s.phase == GamePhase.moving && rng.nextDouble() < 0.4) {
              out.add((s: s, turnStart: start));
              moving++;
            }
          }
        case GamePhase.cubeOffered || GamePhase.gameOver:
          throw StateError('unexpected ${s.phase}');
      }
    }
  }
  expect(moving, greaterThanOrEqualTo(minMoving), reason: v.name);
  expect(remainder, greaterThanOrEqualTo(minRemainder), reason: v.name);
  return out;
}

List<BotRequestKind> _kindsFor(GameState s) => switch (s.phase) {
      GamePhase.moving => [BotRequestKind.choosePlay, BotRequestKind.analyze],
      GamePhase.awaitingRoll => [BotRequestKind.offerDouble],
      GamePhase.cubeOffered => [BotRequestKind.takeDouble],
      _ => const [],
    };

void main() {
  for (final midTurn in [false, true]) {
    for (final v in Variant.values) {
      final label = midTurn ? ' (mid-turn)' : '';
      test('${v.name}: every kind decides on random reachable states$label',
          () {
        final rng = Random(1000 + v.index);
        final samples = _samples(v, rng,
                minRemainder: v.rules.cascade == null ? 0 : 1, maxGames: 200)
            .where((x) => midTurn || x.s.steps.isEmpty);
        final seen = <BotRequestKind>{};
        var id = 0;
        for (final (:s, :turnStart) in samples) {
          for (final kind in _kindsFor(s)) {
            seen.add(kind);
            final r = BotRequests.fromState(s,
                kind: kind, level: BotLevel.easy, id: id++, seed: id);
            final reply = Bot.decide(r);
            expect(reply, isNot(isA<ErrorReply>()), reason: '$r\n$s\n$reply');
            expect(reply.id, r.id);
            switch (kind) {
              case BotRequestKind.choosePlay:
                final steps = (reply as PlayReply).steps;
                expect(_try(turnStart, SubmitPlay(steps)), isNotNull,
                    reason: '$steps from $turnStart');
              case BotRequestKind.analyze:
                expect(reply, isA<AnalysisReply>());
              case BotRequestKind.offerDouble || BotRequestKind.takeDouble:
                expect(reply, isA<DecisionReply>());
            }
          }
        }
        expect(seen,
            containsAll([BotRequestKind.choosePlay, BotRequestKind.analyze]),
            reason: v.name);
        if (v.rules.cube.available) {
          expect(
              seen,
              containsAll(
                  [BotRequestKind.offerDouble, BotRequestKind.takeDouble]));
        }
      });
    }
  }

  group('fields', () {
    GameState rolled(Variant v, List<int> opening, [List<int>? roll]) {
      var s = _apply(GameState.initial(v, cubeEnabled: true),
          RollOpening(opening[0], opening[1]));
      if (roll != null) s = _apply(s, RollDice(roll[0], roll[1]));
      return s;
    }

    test('mid-turn: turn start, dice, steps for analyze only', () {
      final s0 = rolled(Variant.portes, [3, 1]);
      expect(s0.phase, GamePhase.moving);
      final step = s0.node.nextSteps.first;
      final s1 = _apply(s0, StepAction(step));
      for (final kind in [BotRequestKind.choosePlay, BotRequestKind.analyze]) {
        final r = BotRequests.fromState(s1,
            kind: kind,
            level: BotLevel.medium,
            id: 7,
            seed: 9,
            budget: const Duration(milliseconds: 5),
            supersedes: 6);
        expect(r.position, s0.turnStart);
        expect(r.side, s0.sideToMove);
        expect(r.dice, s0.dice);
        expect(r.cascade, isFalse);
        expect(r.context, s0.context);
        expect(r.steps, kind == BotRequestKind.analyze ? [step] : isEmpty);
        expect((r.id, r.seed, r.level, r.supersedes, r.budget),
            (7, 9, BotLevel.medium, 6, const Duration(milliseconds: 5)));
      }
    });

    test('at the turn start: the current state', () {
      final s0 = rolled(Variant.longNard, [6, 5]);
      for (final kind in [BotRequestKind.choosePlay, BotRequestKind.analyze]) {
        final r = BotRequests.fromState(s0,
            kind: kind, level: BotLevel.easy, id: 1, seed: 1);
        expect(r.position, s0.position);
        expect(r.dice, s0.dice);
        expect(r.context, s0.context);
        expect(r.steps, isEmpty);
      }
    });

    test('cube: offer asks the side to move, take the side offered to', () {
      final v = Variant.values.firstWhere((v) => v.rules.cube.available);
      var s = rolled(v, [3, 1]);
      s = _apply(s, SubmitPlay(s.tree.plays().first.steps));
      expect(s.phase, GamePhase.awaitingRoll);
      final offer = BotRequests.fromState(s,
          kind: BotRequestKind.offerDouble,
          level: BotLevel.hard,
          id: 1,
          seed: 1);
      expect(offer.side, s.sideToMove);
      expect(offer.dice, isEmpty);
      expect(offer.position, s.position);
      expect(offer.cube, s.cube);
      final offered = _apply(s, const OfferDouble());
      final take = BotRequests.fromState(offered,
          kind: BotRequestKind.takeDouble,
          level: BotLevel.hard,
          id: 2,
          seed: 1);
      expect(take.side, s.sideToMove!.opponent);
      expect(take.cube.offeredBy, s.sideToMove);
      expect(Bot.decide(take), isA<DecisionReply>());
    });

    test('crawfordGame is carried', () {
      final v = Variant.values.firstWhere((v) => v.rules.cube.available);
      final s = GameState.initial(v,
          starter: Side.one, crawfordGame: true, cubeEnabled: true);
      final r = BotRequests.fromState(s,
          kind: BotRequestKind.offerDouble,
          level: BotLevel.easy,
          id: 1,
          seed: 1);
      expect(r.crawfordGame, isTrue);
    });

    test('a kind outside its phase throws ArgumentError', () {
      final opening = GameState.initial(Variant.portes);
      final moving = rolled(Variant.portes, [3, 1]);
      for (final (s, kind) in [
        (opening, BotRequestKind.choosePlay),
        (opening, BotRequestKind.offerDouble),
        (moving, BotRequestKind.offerDouble),
        (moving, BotRequestKind.takeDouble),
      ]) {
        expect(
            () => BotRequests.fromState(s,
                kind: kind, level: BotLevel.easy, id: 1, seed: 1),
            throwsArgumentError,
            reason: '$kind in ${s.phase}');
      }
    });
  });
}
