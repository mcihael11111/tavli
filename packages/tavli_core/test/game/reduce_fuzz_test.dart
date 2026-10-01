import 'dart:convert';
import 'dart:math';

import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

/// Games in the default run (about 10 per variant).
const _games = 130;

/// Actions per game before giving up (most random actions are rejected).
const _maxActions = 1500;

/// A random action: mostly plausible for the phase, often not: dice out of
/// range, steps from `basicSteps` that the tree rejects, undo and commit
/// anywhere, cube actions, resigns.
GameAction _randomAction(GameState s, Random r) {
  Side side() => r.nextBool() ? Side.one : Side.two;
  int die() => r.nextInt(20) == 0 ? r.nextInt(10) - 2 : 1 + r.nextInt(6);
  // Game-ending actions are rare, so games run long.
  if (r.nextInt(3000) == 0) return Resign(side());
  if (r.nextInt(3000) == 0) return ClockTimeout(side());
  if (r.nextInt(400) == 0) return const Drop();
  if (r.nextInt(150) == 0) return const OfferDouble();
  final roll = 4 + r.nextInt(96);
  if (roll < 12) return RollOpening(die(), die());
  if (roll < 25) return RollDice(die(), die());
  if (roll < 30) return const Take();
  if (roll < 40) return const UndoStep();
  if (roll < 50) return const CommitPlay();
  if (s.phase == GamePhase.moving) {
    final kind = r.nextInt(10);
    if (kind < 6) {
      final next = s.node.nextSteps.toList();
      if (next.isNotEmpty) return StepAction(next[r.nextInt(next.length)]);
    } else if (kind < 9) {
      final d = 1 + r.nextInt(6);
      final b =
          StepRules(s.variant.rules).basicSteps(s.position, s.sideToMove!, d);
      if (b.isNotEmpty) return StepAction(b[r.nextInt(b.length)]);
    }
  }
  final from = 1 + r.nextInt(25), d = 1 + r.nextInt(6);
  return StepAction(Step(from, max(0, from - d), d));
}

/// State invariants after every accepted action.
void _invariants(GameState s) {
  for (final side in Side.values) {
    expect(s.position.borneOff(side) + s.position.checkersOnBoard(side), 15);
  }
  expect(s.cube.value, inInclusiveRange(1, 64));
  switch (s.phase) {
    case GamePhase.opening:
      expect(s.sideToMove, isNull);
      expect(s.dice, isEmpty);
    case GamePhase.awaitingRoll || GamePhase.cubeOffered:
      expect(s.sideToMove, isNotNull);
      expect(s.dice, isEmpty);
      expect(s.steps, isEmpty);
      expect(s.position, s.turnStart);
      expect(
        s.cube.offeredBy,
        s.phase == GamePhase.cubeOffered ? s.sideToMove : null,
      );
    case GamePhase.moving:
      expect(s.tree.hasPlay, isTrue);
      expect(s.tree.walk(s.steps), isNotNull);
      // Position and context replay from the turn start.
      final rules = s.variant.rules, side = s.sideToMove!;
      final m = s.turnStart.toMutable();
      var ctx = TurnContext(
        firstTurn: s.turnsTaken[side] == 0,
        diceOfTurn: s.dice,
      );
      for (final st in s.steps) {
        ctx = StepValidators(rules)
            .next(ctx, StepRules(rules).apply(m, side, st));
      }
      expect(m.freeze(), s.position);
      expect(ctx, s.context);
    case GamePhase.gameOver:
      expect(s.result, isNotNull);
      expect(s.cube.offeredBy, isNull);
  }
}

/// The events alone take a viewer from the old board to the new one.
void _eventsReplay(GameState before, GameUpdate u) {
  final rules = before.variant.rules;
  var p = before.position;
  for (final e in u.events) {
    if (e is CheckerMoved) {
      final m = p.toMutable();
      expect(StepRules(rules).apply(m, e.side, e.step.step), e.step);
      p = m.freeze();
    } else if (e is StepUndone) {
      final m = p.toMutable();
      StepRules(rules).undo(m, e.side, e.step);
      p = m.freeze();
    }
  }
  expect(p, u.state.position, reason: '${u.events}');
}

void main() {
  test('reduce never throws on random valid and invalid actions', () {
    final r = Random(20261001);
    var accepted = 0, rejected = 0, ended = 0;
    for (var g = 0; g < _games; g++) {
      final v = Variant.values[g % Variant.values.length];
      final cube = r.nextBool() ? true : null;
      var s = GameState.initial(v, cubeEnabled: cube);
      final log = <(GameAction, Side?)>[];
      for (var i = 0; i < _maxActions; i++) {
        final a = _randomAction(s, r);
        final by =
            r.nextInt(4) == 0 ? (r.nextBool() ? Side.one : Side.two) : null;
        expect(
          GameAction.fromJson(jsonDecode(jsonEncode(a.toJson()))),
          a,
        );
        final before = s, hash = s.hashCode;
        final ReduceResult res;
        try {
          res = reduce(s, a, by: by);
        } catch (e) {
          fail('${v.name}: $a by $by threw $e in $s');
        }
        switch (res) {
          case RuleViolation():
            rejected++;
            expect(s.hashCode, hash);
            expect(identical(s, before), isTrue);
          case GameUpdate(:final state):
            accepted++;
            _eventsReplay(before, res);
            log.add((a, by));
            s = state;
            _invariants(s);
        }
        if (s.phase == GamePhase.gameOver) break;
      }
      if (s.phase == GamePhase.gameOver) {
        ended++;
        for (final a in const [
          UndoStep(),
          CommitPlay(),
          RollDice(3, 4),
          Resign(Side.one),
        ]) {
          final v = reduce(s, a);
          expect(v, isA<RuleViolation>());
          expect((v as RuleViolation).code, ViolationCode.gameOver);
        }
      }
      // Determinism: replaying the accepted actions rebuilds the state.
      var t = GameState.initial(v, cubeEnabled: cube);
      for (final (a, by) in log) {
        t = (reduce(t, a, by: by) as GameUpdate).state;
      }
      expect(t, s);
      expect(t.hashCode, s.hashCode);
    }
    printOnFailure('accepted $accepted, rejected $rejected, ended $ended');
    expect(accepted, greaterThan(1000));
    expect(rejected, greaterThan(accepted));
    expect(ended, greaterThan(_games ~/ 4));
  });
}
