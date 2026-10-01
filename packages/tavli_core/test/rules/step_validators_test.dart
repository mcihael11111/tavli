import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/positions.dart';
import '../support/steps.dart';

final _longNard = Variant.longNard.rules;
final _ln = StepValidators(_longNard);
final _lnSteps = StepRules(_longNard);

/// Applies [step] on [m] (asserting it is basically legal and allowed
/// before), and returns the context for the next step.
TurnContext _play(
  StepRules r,
  StepValidators v,
  MutablePosition m,
  Step step,
  TurnContext ctx,
) {
  expect(r.basicSteps(m, S.one, step.die), contains(step));
  expect(v.allowsBefore(m, S.one, step, ctx), isTrue, reason: '$step');
  final a = r.apply(m, S.one, step);
  expect(v.allowsAfter(m, S.one, a, ctx), isTrue, reason: '$step');
  return v.next(ctx, a);
}

void main() {
  group('head rule', () {
    test('D18 one head checker per turn (Long Nard 5-3)', () {
      final m = Position.forRules(_longNard).toMutable();
      final ctx0 = TurnContext(firstTurn: true, diceOfTurn: [5, 3]);
      final ctx1 = _play(_lnSteps, _ln, m, const Step(24, 19, 5), ctx0);
      expect(ctx1.headDepartures, 1);
      expect(_ln.allowsBefore(m, S.one, const Step(24, 21, 3), ctx1), isFalse);
      expect(_ln.allowsBefore(m, S.one, const Step(19, 16, 3), ctx1), isTrue);
    });

    test('D18 first-turn 6-6 allows two off the head, not three', () {
      final m = Position.forRules(_longNard).toMutable();
      var ctx = TurnContext(firstTurn: true, diceOfTurn: [6, 6, 6, 6]);
      ctx = _play(_lnSteps, _ln, m, const Step(24, 18, 6), ctx);
      ctx = _play(_lnSteps, _ln, m, const Step(24, 18, 6), ctx);
      expect(ctx.headDepartures, 2);
      expect(_ln.allowsBefore(m, S.one, const Step(24, 18, 6), ctx), isFalse);
    });

    test('D18 first-turn 3-3 and 4-4 also allow two', () {
      for (final d in [3, 4]) {
        final ctx = TurnContext(
          firstTurn: true,
          diceOfTurn: [d, d, d, d],
          headDepartures: 1,
        );
        final p = Position.forRules(_longNard);
        expect(_ln.allowsBefore(p, S.one, Step(24, 24 - d, d), ctx), isTrue);
        final ctx2 = TurnContext(
          firstTurn: true,
          diceOfTurn: [d, d],
          headDepartures: 2,
        );
        expect(_ln.allowsBefore(p, S.one, Step(24, 24 - d, d), ctx2), isFalse);
      }
    });

    test('D18 first-turn 5-5 allows only one', () {
      final p = Position.forRules(_longNard);
      const step = Step(24, 19, 5);
      final ctx0 = TurnContext(firstTurn: true, diceOfTurn: [5, 5, 5, 5]);
      expect(_ln.allowsBefore(p, S.one, step, ctx0), isTrue);
      final ctx1 = TurnContext(
        firstTurn: true,
        diceOfTurn: [5, 5, 5, 5],
        headDepartures: 1,
      );
      expect(_ln.allowsBefore(p, S.one, step, ctx1), isFalse);
    });

    test('D18 later-turn 6-6 allows only one', () {
      final p = posSame(one: {24: 14, 10: 1}, two: {24: 15});
      final ctx = TurnContext(diceOfTurn: [6, 6, 6, 6], headDepartures: 1);
      expect(_ln.allowsBefore(p, S.one, const Step(24, 18, 6), ctx), isFalse);
      expect(_ln.allowsBefore(p, S.one, const Step(10, 4, 6), ctx), isTrue);
    });

    test('D18 head departures are only counted under a head rule', () {
      final fevga = StepValidators(Variant.fevga.rules);
      const a = AppliedStep(Step(24, 20, 4));
      expect(fevga.next(TurnContext(), a).headDepartures, 0);
      expect(_ln.next(TurnContext(), a).headDepartures, 1);
      expect(_ln.next(TurnContext(), const AppliedStep(Step(20, 16, 4))),
          isA<TurnContext>().having((c) => c.headDepartures, 'head', 0));
    });
  });

  group('sole runner', () {
    final fevga = StepValidators(Variant.fevga.rules);
    final ctx = TurnContext();

    test('§4.3 advancement Fevga runner', () {
      final start = Position.forRules(Variant.fevga.rules);
      expect(
          fevga.allowsBefore(start, S.one, const Step(24, 20, 4), ctx), isTrue);

      final running = posSame(one: {24: 14, 20: 1}, two: {24: 15});
      expect(fevga.allowsBefore(running, S.one, const Step(24, 21, 3), ctx),
          isFalse);
      expect(fevga.allowsBefore(running, S.one, const Step(20, 17, 3), ctx),
          isTrue);

      final notYet = posSame(one: {24: 14, 13: 1}, two: {24: 15});
      expect(fevga.allowsBefore(notYet, S.one, const Step(24, 21, 3), ctx),
          isFalse);

      final released = posSame(one: {24: 14, 11: 1}, two: {24: 15});
      expect(fevga.allowsBefore(released, S.one, const Step(24, 21, 3), ctx),
          isTrue);
      expect(fevga.allowsBefore(released, S.one, const Step(11, 8, 3), ctx),
          isTrue);
    });

    test('§4.3 advancement is stateless: released mid-turn by the runner', () {
      final m = posSame(one: {24: 14, 14: 1}, two: {24: 15}).toMutable();
      final r = StepRules(Variant.fevga.rules);
      expect(fevga.allowsBefore(m, S.one, const Step(24, 21, 3), ctx), isFalse);
      r.apply(m, S.one, const Step(14, 11, 3));
      expect(fevga.allowsBefore(m, S.one, const Step(24, 21, 3), ctx), isTrue);
    });

    test('D21 advancement Tawla31 threshold 18', () {
      final t31 = StepValidators(Variant.tawla31.rules);
      final at19 = posSame(one: {24: 14, 19: 1}, two: {24: 15});
      expect(
          t31.allowsBefore(at19, S.one, const Step(24, 21, 3), ctx), isFalse);
      expect(t31.allowsBefore(at19, S.one, const Step(19, 16, 3), ctx), isTrue);
      final at18 = posSame(one: {24: 14, 18: 1}, two: {24: 15});
      expect(t31.allowsBefore(at18, S.one, const Step(24, 21, 3), ctx), isTrue);
    });

    test('§4.3 advancement with two checkers off an unreleased head', () {
      // Unreachable in play (the head empties one checker at a time and the
      // runner must pass the threshold first). Conservative reading: the head
      // stays locked; any checker already off it may move.
      final p = posSame(one: {24: 13, 20: 1, 19: 1}, two: {24: 15});
      expect(fevga.allowsBefore(p, S.one, const Step(24, 21, 3), ctx), isFalse);
      expect(fevga.allowsBefore(p, S.one, const Step(20, 17, 3), ctx), isTrue);
      expect(fevga.allowsBefore(p, S.one, const Step(19, 16, 3), ctx), isTrue);
    });

    test('D17 Gul Bara has no runner rule', () {
      final gul = StepValidators(Variant.gulBara.rules);
      final p = posSame(one: {24: 14, 20: 1}, two: {24: 15});
      expect(gul.allowsBefore(p, S.one, const Step(24, 21, 3), ctx), isTrue);
    });
  });

  group('six-block trap', () {
    // My pips 6..11 = two's pips 18..23 (same direction).
    final before = posSame(
      one: {24: 9, 11: 1, 10: 1, 9: 1, 8: 2, 7: 1},
      two: {24: 15},
    );

    /// Whether [v] allows 8->6 (die 2), asserting the step is generatable.
    bool afterSix(StepValidators v, Position p) {
      final m = p.toMutable();
      expect(_lnSteps.basicSteps(m, S.one, 2), contains(const Step(8, 6, 2)));
      final a = _lnSteps.apply(m, S.one, const Step(8, 6, 2));
      return v.allowsAfter(m, S.one, a, TurnContext());
    }

    test('D19 trap illegal mid-turn: all 15 behind, none off', () {
      expect(afterSix(_ln, before), isFalse);
    });

    test('D19 checksAfter only where a per-step trap rule exists', () {
      expect(_ln.checksAfter, isTrue);
      for (final v in Variant.values.where((v) => v != Variant.longNard)) {
        expect(StepValidators(v.rules).checksAfter, isFalse, reason: '$v');
      }
    });

    test('D19 my pips 10..15 do not wrap into a run (12/13 boundary)', () {
      // My 10, 11, 12 = two's 22, 23, 24; my 13, 14, 15 = two's 1, 2, 3.
      // Not consecutive along two's path, so never a six-block.
      // two sits on its 21 (= my 9), behind its 22..24.
      final p = posSame(
        one: {24: 9, 16: 1, 14: 1, 13: 1, 12: 1, 11: 1, 10: 1},
        two: {21: 15},
      );
      final m = p.toMutable();
      const step = Step(16, 15, 1);
      expect(_lnSteps.basicSteps(m, S.one, 1), contains(step));
      final a = _lnSteps.apply(m, S.one, step);
      expect(_ln.allowsAfter(m, S.one, a, TurnContext()), isTrue);
    });

    test('D19 applies to side two (mirror of the mid-turn trap)', () {
      final p = posSame(
        one: {24: 15},
        two: {24: 9, 11: 1, 10: 1, 9: 1, 8: 2, 7: 1},
      );
      final m = p.toMutable();
      const step = Step(8, 6, 2);
      expect(_lnSteps.basicSteps(m, S.two, 2), contains(step));
      final a = _lnSteps.apply(m, S.two, step);
      expect(_ln.allowsAfter(m, S.two, a, TurnContext()), isFalse);
    });

    test('D19 a non-completing step is allowed', () {
      final m = before.toMutable();
      final a = _lnSteps.apply(m, S.one, const Step(8, 5, 3));
      expect(_ln.allowsAfter(m, S.one, a, TurnContext()), isTrue);
    });

    test('D19 allowed with one opposing checker in front', () {
      // two's 17 = my 5, in front of two's 18..23.
      final p = posSame(
        one: {24: 9, 11: 1, 10: 1, 9: 1, 8: 2, 7: 1},
        two: {24: 14, 17: 1},
      );
      expect(afterSix(_ln, p), isTrue);
    });

    test('D19 allowed with one opposing checker borne off', () {
      final p = posSame(
        one: {24: 9, 11: 1, 10: 1, 9: 1, 8: 2, 7: 1},
        two: {24: 14},
      );
      expect(afterSix(_ln, p), isTrue);
    });

    test('D19 a seven-run is judged by its lowest window', () {
      // My 5..11 = two's 17..23; two all behind on its 24.
      final p = posSame(
        one: {24: 8, 11: 1, 10: 1, 9: 1, 8: 2, 7: 1, 5: 1},
        two: {24: 15},
      );
      expect(afterSix(_ln, p), isFalse);
      // two's 16 (= my 4) is in front of the whole run.
      final p2 = posSame(
        one: {24: 8, 11: 1, 10: 1, 9: 1, 8: 2, 7: 1, 5: 1},
        two: {24: 14, 16: 1},
      );
      expect(afterSix(_ln, p2), isTrue);
    });

    test('D19 is Long Nard only (Fevga primes are play filters)', () {
      final fevga = StepValidators(Variant.fevga.rules);
      expect(afterSix(fevga, before), isTrue);
    });
  });

  group('hit-and-run', () {
    final tavlaSteps = StepRules(Variant.tavla.rules);
    final tavla = StepValidators(Variant.tavla.rules);
    // two's 21 = my 4 (a blot in my home).
    final p = pos(one: {6: 2, 8: 1, 13: 12}, two: {21: 1, 1: 14});
    const hitStep = Step(6, 4, 2);

    test('D4 no hit-and-run: a hit point in home may not be left', () {
      final m = p.toMutable();
      final a = tavlaSteps.apply(m, S.one, hitStep);
      expect(a.hit, isTrue);
      final ctx = tavla.next(TurnContext(), a);
      expect(ctx.homeHitMask, 1 << 4);
      expect(tavlaSteps.basicSteps(m, S.one, 1), contains(const Step(4, 3, 1)));
      expect(tavla.allowsBefore(m, S.one, const Step(4, 3, 1), ctx), isFalse);
      // Covering the hitter is allowed.
      expect(tavla.allowsBefore(m, S.one, const Step(6, 4, 2), ctx), isTrue);
      expect(tavla.allowsBefore(m, S.one, const Step(8, 4, 4), ctx), isTrue);
      // Other points are unaffected.
      expect(tavla.allowsBefore(m, S.one, const Step(13, 9, 4), ctx), isTrue);
    });

    test('A2 D4 all home: no bear-off from the hit point', () {
      // All 15 of mine home; two's blot on its 21 (= my 4) entered my home.
      final q = pos(one: {6: 4, 5: 4, 3: 4, 2: 3}, two: {21: 1, 1: 14});
      final m = q.toMutable();
      final a = tavlaSteps.apply(m, S.one, hitStep);
      expect(a.hit, isTrue);
      final ctx = tavla.next(TurnContext(diceOfTurn: [2, 4]), a);
      const off = Step(4, 0, 4);
      expect(tavlaSteps.basicSteps(m, S.one, 4), contains(off));
      expect(tavla.allowsBefore(m, S.one, off, ctx), isFalse);
      expect(tavla.allowsBefore(m, S.one, const Step(6, 2, 4), ctx), isTrue);
    });

    test('D4 applies to side two', () {
      // one's 21 = two's 4.
      final q = pos(one: {21: 1, 1: 14}, two: {6: 2, 8: 1, 13: 12});
      final m = q.toMutable();
      final a = tavlaSteps.apply(m, S.two, hitStep);
      expect(a.hit, isTrue);
      final ctx = tavla.next(TurnContext(), a);
      expect(ctx.homeHitMask, 1 << 4);
      expect(tavla.allowsBefore(m, S.two, const Step(4, 3, 1), ctx), isFalse);
      expect(tavla.allowsBefore(m, S.two, const Step(8, 4, 4), ctx), isTrue);
    });

    test('D3 Portes allows hit-and-run and records no home hit', () {
      final portes = StepValidators(Variant.portes.rules);
      final m = p.toMutable();
      final a = hitRules.apply(m, S.one, hitStep);
      final ctx = portes.next(TurnContext(), a);
      expect(ctx, TurnContext(), reason: 'no D4 rule, no split');
      expect(portes.allowsBefore(m, S.one, const Step(4, 3, 1), ctx), isTrue);
    });

    test('D4 a hit outside home does not restrict', () {
      // two's 18 = my 7.
      final q = pos(one: {13: 1, 8: 14}, two: {18: 1, 1: 14});
      final m = q.toMutable();
      final a = tavlaSteps.apply(m, S.one, const Step(13, 7, 6));
      expect(a.hit, isTrue);
      final ctx = tavla.next(TurnContext(), a);
      expect(ctx.homeHitMask, 0);
      expect(tavla.allowsBefore(m, S.one, const Step(7, 4, 3), ctx), isTrue);
    });
  });
}
