import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/positions.dart';
import '../support/steps.dart';

void main() {
  group('Step', () {
    test('value equality includes the die', () {
      expect(const Step(3, 0, 3), const Step(3, 0, 3));
      expect(const Step(3, 0, 3).hashCode, const Step(3, 0, 3).hashCode);
      expect(const Step(3, 0, 5), isNot(const Step(3, 0, 6)));
    });

    test('JSON round-trip', () {
      for (final s in const [Step(24, 18, 6), Step(25, 22, 3), Step(3, 0, 6)]) {
        expect(Step.fromJson(s.toJson()), s);
      }
      expect(const Step(8, 5, 3).toJson(), {'from': 8, 'to': 5, 'die': 3});
    });

    test('fromJson rejects bad payloads with FormatException', () {
      for (final j in <Map<String, Object?>>[
        {},
        {'from': 8, 'to': 5},
        {'from': '8', 'to': 5, 'die': 3},
        {'from': 8, 'to': 5, 'die': 7},
        {'from': 8, 'to': 4, 'die': 3}, // to != from - die
        {'from': 26, 'to': 23, 'die': 3},
        {'from': 0, 'to': 0, 'die': 1},
        {'from': 3, 'to': -3, 'die': 6}, // bear-off target is 0
      ]) {
        expect(() => Step.fromJson(j), throwsFormatException, reason: '$j');
      }
    });
  });

  group('basic steps (hitting)', () {
    test('G2 basic move: standard start, die 6', () {
      final p = Position.start(Layout.standard2535, Direction.opposing);
      final steps = stepsOf(hitRules, p, S.one, 6);
      expect(steps, contains(const Step(24, 18, 6)));
      // 24->18, 13->7, 8->2 are open; 6->0 is no bear-off (G5).
      expect(steps, {
        const Step(24, 18, 6),
        const Step(13, 7, 6),
        const Step(8, 2, 6),
      });
      // Works through a MutablePosition too.
      expect(stepsOf(hitRules, p.toMutable(), S.one, 6), steps);
    });

    test('§4.1 hit: 8->5 hits the blot on two:20, undo restores', () {
      final p = pos(one: {8: 1}, two: {20: 1});
      expect(stepsOf(hitRules, p, S.one, 3), {const Step(8, 5, 3)});
      final a = roundTrip(
        hitRules,
        p,
        S.one,
        const Step(8, 5, 3),
        after: pos(one: {5: 1}, two: {}, barTwo: 1),
      );
      expect(a.hit, isTrue);
      expect(a.pinned || a.unpinned || a.bearOff, isFalse);
      final m = p.toMutable();
      hitRules.apply(m, S.one, const Step(8, 5, 3));
      expect(m.onBar(S.two), 1);
    });

    test('G2 blocked: two holds the point with 2', () {
      final p = pos(one: {8: 1}, two: {20: 2});
      expect(stepsOf(hitRules, p, S.one, 3), isEmpty);
    });

    test('G2 own stack is open', () {
      final p = pos(one: {8: 1, 5: 3}, two: {});
      expect(stepsOf(hitRules, p, S.one, 3), contains(const Step(8, 5, 3)));
    });

    test('§4.1 bar first: every legal step enters from 25', () {
      final p = pos(
        one: {24: 1, 13: 5, 8: 3, 6: 5},
        two: {6: 5, 2: 2, 4: 1, 13: 5},
        barOne: 1,
      );
      final all = allStepsOf(hitRules, p, S.one);
      expect(all, isNotEmpty);
      expect(all.every((s) => s.from == 25), isTrue, reason: '$all');
      expect(stepsOf(hitRules, p, S.one, 3), {const Step(25, 22, 3)});
      expect(stepsOf(hitRules, p, S.one, 2), isEmpty); // my 23 = two's 2 (2)
      expect(stepsOf(hitRules, p, S.one, 6), isEmpty); // my 19 = two's 6 (5)
    });

    test('§4.1 bar entry: plain and hitting entry undo exactly', () {
      final p = pos(
        one: {13: 5, 8: 3, 6: 5},
        two: {6: 5, 4: 1, 13: 5},
        barOne: 2,
      );
      final plain = roundTrip(
        hitRules,
        p,
        S.one,
        const Step(25, 22, 3),
        after: pos(
          one: {22: 1, 13: 5, 8: 3, 6: 5},
          two: {6: 5, 4: 1, 13: 5},
          barOne: 1,
        ),
      );
      expect(plain.hit, isFalse);
      final hit = roundTrip(
        hitRules,
        p,
        S.one,
        const Step(25, 21, 4),
        after: pos(
          one: {21: 1, 13: 5, 8: 3, 6: 5},
          two: {6: 5, 13: 5},
          barOne: 1,
          barTwo: 1,
        ),
      );
      expect(hit.hit, isTrue);
    });

    test('§4.1 bar entry by side two hits side one', () {
      final p = pos(one: {21: 1, 6: 2}, two: {6: 2}, barTwo: 1);
      // two's entry with 4 lands on its 21 = my 4: empty.
      expect(stepsOf(hitRules, p, S.two, 4), {const Step(25, 21, 4)});
      // two's entry with 1 lands on its 24 = my 1: empty. With 6 its 19 =
      // my 6 (2 of mine): closed.
      expect(stepsOf(hitRules, p, S.two, 6), isEmpty);
      final a = roundTrip(hitRules, p, S.two, const Step(25, 21, 4));
      expect(a.hit, isFalse);
      final p2 = pos(one: {4: 1, 6: 2}, two: {6: 2}, barTwo: 1);
      final a2 = roundTrip(
        hitRules,
        p2,
        S.two,
        const Step(25, 21, 4),
        after: pos(one: {6: 2}, two: {21: 1, 6: 2}, barOne: 1),
      );
      expect(a2.hit, isTrue);
    });
  });

  group('blocking (same direction)', () {
    test('§4.3 block: a single checker closes the point', () {
      // two's 24 (head) = my 12; two's 1 = my 13.
      final p = posSame(one: {24: 14, 16: 1}, two: {24: 1, 20: 14});
      expect(
          stepsOf(blockRules, p, S.one, 4).where((s) => s.from == 16), isEmpty);
      expect(stepsOf(blockRules, p, S.one, 3), contains(const Step(16, 13, 3)));
      roundTrip(blockRules, p, S.one, const Step(16, 13, 3));
    });

    test('§4.3 block: occupied my 13 (two:1) is closed too', () {
      final p = posSame(one: {24: 14, 16: 1}, two: {1: 1, 20: 14});
      expect(
          stepsOf(blockRules, p, S.one, 3).where((s) => s.from == 16), isEmpty);
    });
  });
  group('undo is the exact inverse', () {
    test('every basic step of every variant start and sample positions', () {
      final samples = <(VariantRules, Position)>[
        for (final v in Variant.values) (v.rules, Position.forRules(v.rules)),
        (
          Variant.portes.rules,
          pos(one: {8: 1, 6: 2}, two: {20: 1, 21: 1}, barTwo: 1)
        ),
        (
          Variant.plakoto.rules,
          pos(
            one: {6: 1, 5: 1, 24: 13},
            two: {19: 1, 22: 1, 21: 1, 24: 12},
            pinnedTwo: {19},
          ),
        ),
      ];
      var checked = 0;
      for (final (rules, p) in samples) {
        final r = StepRules(rules);
        for (final s in Side.values) {
          for (var d = 1; d <= 6; d++) {
            for (final step in r.basicSteps(p, s, d)) {
              final m = p.toMutable();
              final a = r.apply(m, s, step);
              m.freeze(); // validates invariants in debug builds
              r.undo(m, s, a);
              expect(m.freeze(), p, reason: '$step on $p');
              checked++;
            }
          }
        }
      }
      expect(checked, greaterThan(50));
    });
  });
}
