import 'dart:math';

import 'package:tavli_bot/tavli_bot.dart';
import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/positions.dart';

const _one = Side.one;

/// A labelled pair: [better] is better for side one than [worse].
typedef Pair = ({String why, Position better, Position worse});

/// Every pair ranks as labelled, and each position is antisymmetric and
/// mirrors to the opposite equity (±0.05).
void expectPairs(Evaluator e, VariantRules r, List<Pair> pairs) {
  for (final c in pairs) {
    final b = e.evaluate(c.better, _one, r), w = e.evaluate(c.worse, _one, r);
    expect(b.equity, greaterThan(w.equity), reason: '${c.why}\n$b\n$w');
    for (final p in [c.better, c.worse]) {
      expectAntisymmetric(e, p, r, reason: c.why);
      expect(e.evaluate(mirror(p), _one, r).equity,
          closeTo(-e.evaluate(p, _one, r).equity, 0.05),
          reason: c.why);
    }
  }
}

/// Variants by family (contact type).
List<Variant> _family(Contact c) => [
      for (final v in Variant.values)
        if (v.rules.contact == c) v
    ];

void main() {
  group('hitting (Portes)', () {
    final r = Variant.portes.rules;
    const e = HittingEvaluator();
    // Their usual layout: 24 (my 1), 13 (my 12), 8 (my 17), 6 (my 19).
    final them = {24: 2, 13: 5, 8: 3, 6: 5};
    test('labelled pairs', () {
      expectPairs(e, r, [
        (
          why: 'a made 5-point beats a blot on the 5-point (their 24 has a '
              'direct 4 at it)',
          better: posOpp({24: 2, 13: 4, 8: 3, 6: 4, 5: 2}, them),
          worse: posOpp({24: 2, 13: 5, 8: 3, 6: 4, 5: 1}, them),
        ),
        (
          why: 'their checker on the bar against my closed board beats the '
              'same checker safe on their 13',
          better: posOpp(
              {6: 3, 5: 2, 4: 2, 3: 2, 2: 2, 1: 2, 13: 2}, {13: 5, 8: 4, 6: 5},
              barTwo: 1),
          worse: posOpp(
              {6: 3, 5: 2, 4: 2, 3: 2, 2: 2, 1: 2, 13: 2}, {13: 6, 8: 4, 6: 5}),
        ),
        (
          why: 'an anchor on their 5-point beats two split blots in their '
              'board',
          better: posOpp({20: 2, 13: 5, 8: 3, 6: 5}, {13: 5, 8: 3, 7: 2, 6: 5}),
          worse: posOpp(
              {21: 1, 20: 1, 13: 5, 8: 3, 6: 5}, {13: 5, 8: 3, 7: 2, 6: 5}),
        ),
        (
          why: 'a 5-point prime (9..5) beats broken points (11, 9, 7, 6, '
              '3) with about the same pips',
          better: posOpp({24: 2, 13: 3, 9: 2, 8: 2, 7: 2, 6: 2, 5: 2}, them),
          worse: posOpp({24: 2, 13: 3, 11: 2, 9: 2, 7: 2, 6: 2, 3: 2}, them),
        ),
        (
          why: 'seven pips ahead with the same points (a checker safely '
              '13 -> 6)',
          better: posOpp({24: 2, 13: 4, 8: 3, 6: 6}, them),
          worse: posOpp({24: 2, 13: 5, 8: 3, 6: 5}, them),
        ),
        (
          why: 'me on the bar against a 3-point board is worse than both '
              'back checkers on their 1',
          better: posOpp(
              {24: 2, 13: 5, 8: 3, 6: 5}, {13: 5, 8: 3, 6: 3, 5: 2, 4: 2}),
          worse: posOpp(
              {24: 1, 13: 5, 8: 3, 6: 5}, {13: 5, 8: 3, 6: 3, 5: 2, 4: 2},
              barOne: 1),
        ),
      ]);
    });
  });

  group('pinning (Plakoto)', () {
    final r = Variant.plakoto.rules;
    const e = PinningEvaluator();
    test('labelled pairs', () {
      expectPairs(e, r, [
        (
          why: 'their checker pinned in my home (my 5) beats it free there',
          better:
              posOpp({24: 10, 6: 4, 5: 1}, {24: 14, 20: 1}, pinnedTwo: {20}),
          worse: posOpp({24: 10, 6: 5}, {24: 14, 20: 1}),
        ),
        (
          why: 'my mother alone on my 24 with their checker 3 behind it '
              '(a direct pin, which ends the game) is worse than two '
              'checkers at home',
          better: posOpp({24: 2, 6: 13}, {4: 1, 6: 13, 24: 1}),
          worse: posOpp({24: 1, 18: 1, 6: 13}, {4: 1, 6: 13, 24: 1}),
        ),
        (
          why: 'my checker pinned under theirs (my 20) is worse than free',
          better: posOpp({24: 13, 20: 1, 6: 1}, {6: 1, 24: 14}),
          worse: posOpp({24: 13, 20: 1, 6: 1}, {5: 1, 24: 14}, pinnedOne: {20}),
        ),
        (
          why: 'two of theirs pinned beats one',
          better: posOpp({24: 12, 6: 1, 5: 1, 4: 1}, {24: 13, 20: 1, 21: 1},
              pinnedTwo: {20, 21}),
          worse: posOpp({24: 12, 6: 1, 5: 1, 3: 1}, {24: 13, 20: 1, 21: 1},
              pinnedTwo: {20}),
        ),
        (
          why: 'a pin deep in my home (their 23, far from their home) '
              'beats one on their 14',
          better:
              posOpp({24: 13, 6: 1, 2: 1}, {24: 14, 23: 1}, pinnedTwo: {23}),
          worse:
              posOpp({24: 13, 6: 1, 11: 1}, {24: 14, 14: 1}, pinnedTwo: {14}),
        ),
        (
          why: 'two made home points beat four loose checkers (fewer pips '
              'too)',
          better: posOpp({24: 11, 6: 2, 5: 2}, {24: 15}),
          worse: posOpp({24: 11, 8: 1, 7: 1, 6: 1, 5: 1}, {24: 15}),
        ),
      ]);
    });
  });

  group('running', () {
    test('labelled pairs (Fevga)', () {
      final r = Variant.fevga.rules;
      const e = RunningEvaluator();
      expectPairs(e, r, [
        (
          why: 'a 5-point blockade on my 11..7 (their 23..19, right in front '
              'of their head) beats scattered points with the same pips',
          better: posSame({24: 10, 11: 1, 10: 1, 9: 1, 8: 1, 7: 1}, {24: 15}),
          worse: posSame({24: 10, 13: 1, 11: 1, 9: 1, 7: 1, 5: 1}, {24: 15}),
        ),
        (
          why: 'their 5-block on my 21..17 in front of my runner is worse '
              'for me than their checkers scattered with the same pips',
          better:
              posSame({24: 14, 22: 1}, {24: 10, 11: 1, 9: 1, 7: 1, 5: 1, 3: 1}),
          worse:
              posSame({24: 14, 22: 1}, {24: 10, 9: 1, 8: 1, 7: 1, 6: 1, 5: 1}),
        ),
        (
          why: 'my runner past their head (released) beats it still near '
              'my start',
          better: posSame({24: 14, 11: 1}, {24: 15}),
          worse: posSame({24: 14, 20: 1}, {24: 15}),
        ),
        (
          why: 'ten pips ahead with the same shape',
          better: posSame({24: 13, 16: 1, 15: 1}, {24: 13, 21: 1, 20: 1}),
          worse: posSame({24: 13, 21: 1, 20: 1}, {24: 13, 21: 1, 20: 1}),
        ),
        (
          why: 'more borne off in the home stretch',
          better: posSame({6: 5, 5: 5}, {6: 5, 5: 5, 4: 2, 14: 1}),
          worse: posSame({6: 5, 5: 5, 1: 1}, {6: 5, 5: 5, 4: 2, 14: 1}),
        ),
      ]);
    });

    test('labelled pairs (Long Nard)', () {
      final r = Variant.longNard.rules;
      const e = RunningEvaluator();
      expectPairs(e, r, [
        (
          why: 'five checkers off the head (later in the game) beats two '
              'runners far ahead, at equal pips',
          better:
              posSame({24: 10, 20: 1, 18: 1, 16: 1, 14: 1, 13: 1}, {24: 15}),
          worse: posSame({24: 13, 5: 1, 4: 1}, {24: 15}),
        ),
      ]);
    });
  });

  group('all families', () {
    test('start positions give equity in -0.15..+0.15', () {
      for (final v in Variant.values) {
        final e = evaluatorFor(v.rules);
        final p = Position.forRules(v.rules);
        for (final s in Side.values) {
          expect(
              e.evaluate(p, s, v.rules).equity, inInclusiveRange(-0.15, 0.15),
              reason: '$v $s');
        }
      }
    });

    test('family evaluators are exactly antisymmetric on random positions', () {
      final rng = Random(17);
      final byContact = {
        Contact.hit: const HittingEvaluator(),
        Contact.pin: const PinningEvaluator(),
        Contact.block: const RunningEvaluator(),
      };
      byContact.forEach((c, e) {
        for (final v in _family(c)) {
          for (final p in randomPositions(v, 40, rng)) {
            expectAntisymmetric(e, p, v.rules, reason: '$v');
            expectAntisymmetric(evaluatorFor(v.rules), p, v.rules,
                reason: '$v dispatch');
          }
        }
      });
    });

    test(
        'dispatch: race positions use the race evaluator, others the '
        'family', () {
      final r = Variant.portes.rules;
      final e = evaluatorFor(r);
      expect(e, isA<DispatchEvaluator>());
      final race = posOpp({6: 10, 4: 5}, {7: 10, 6: 5});
      final contact =
          posOpp({24: 2, 13: 5, 8: 3, 6: 5}, {24: 2, 13: 5, 8: 3, 6: 5});
      String s(EvalResult x) => '$x';
      expect(s(e.evaluate(race, _one, r)),
          s(const RaceEvaluator().evaluate(race, _one, r)));
      expect(s(e.evaluate(contact, _one, r)),
          s(const HittingEvaluator().evaluate(contact, _one, r)));
      expect(
          evaluatorFor(Variant.plakoto.rules).family, isA<PinningEvaluator>());
      expect(
          evaluatorFor(Variant.gulBara.rules).family, isA<RunningEvaluator>());
    });
  });
}
