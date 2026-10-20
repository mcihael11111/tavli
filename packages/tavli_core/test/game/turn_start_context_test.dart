import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/reducer.dart';

void main() {
  group('GameState.turnStartContext', () {
    // Long Nard: a head rule, so a head step changes the context.
    final toRoll = GameState.initial(Variant.longNard, starter: Side.one);

    test('is the context before the steps; replaying them gives context', () {
      final rolled = ok(toRoll, const RollDice(6, 5)).state;
      expect(rolled.turnStartContext, rolled.context);
      expect(rolled.turnStartContext.firstTurn, isTrue);
      expect(rolled.turnStartContext.diceOfTurn, [6, 5]);

      final stepped = ok(rolled, StepAction(rolled.node.nextSteps.first)).state;
      expect(stepped.turnStartContext, rolled.turnStartContext);
      expect(stepped.context, isNot(stepped.turnStartContext));

      final rules = Variant.longNard.rules;
      final m = stepped.turnStart.toMutable();
      var ctx = stepped.turnStartContext;
      for (final s in stepped.steps) {
        ctx = StepValidators(rules)
            .next(ctx, StepRules(rules).apply(m, Side.one, s));
      }
      expect(ctx, stepped.context);
    });

    test('generates the same tree as the state', () {
      final s = ok(toRoll, const RollDice(3, 3)).state;
      final t = generatePlays(s.turnStart, s.sideToMove!, s.dice,
          s.variant.rules, s.turnStartContext);
      expect(t.finals, s.tree.finals);
    });

    test('is not the first turn once the side has played', () {
      final s = playAny(ok(toRoll, const RollDice(6, 5)).state);
      final next = ok(s, const RollDice(4, 2)).state;
      expect(next.sideToMove, Side.two);
      expect(next.turnStartContext.firstTurn, isTrue);
      final back = ok(playAny(next), const RollDice(4, 2)).state;
      expect(back.sideToMove, Side.one);
      expect(back.turnStartContext.firstTurn, isFalse);
    });

    test('survives a JSON round trip (derived, not stored)', () {
      final rolled = ok(toRoll, const RollDice(6, 5)).state;
      final s = ok(rolled, StepAction(rolled.node.nextSteps.first)).state;
      final json = s.toJson();
      expect(json.containsKey('turnStartContext'), isFalse);
      expect(GameState.fromJson(json).turnStartContext, s.turnStartContext);
    });
  });
}
