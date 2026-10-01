import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/plays.dart';
import '../support/positions.dart';

typedef S = Side;

final _portes = Variant.portes.rules;
final _tavla = Variant.tavla.rules;
final _fevga = Variant.fevga.rules;
final _moultezim = Variant.moultezim.rules;
final _gulBara = Variant.gulBara.rules; // same board, no play filters
const _ctx = TurnContext();

/// Whether [s] holds (>= 1 checker on) every pip in [pips] of [p].
bool holdsAll(Position p, Side s, Iterable<int> pips) =>
    pips.every((q) => p.count(s, q) > 0);

int held(Position p, Side s, Iterable<int> pips) =>
    pips.where((q) => p.count(s, q) > 0).length;

Iterable<int> range(int lo, int hi) => [for (var q = lo; q <= hi; q++) q];

void main() {
  group('D5 no-waste (Tavla)', () {
    test('D5 Tavla 5-2 with checker on 3', () {
      // two's 1 = my 24, so my 1 is open for 3->1.
      final p = pos(one: {3: 1}, two: {1: 15});
      final t = generatePlays(p, S.one, const [5, 2], _tavla, _ctx);
      // 3 off with the 5 (waste 2) beats 3->1, 1 off with the 5 (waste 4).
      expect(sequencesOf(t), [
        [const Step(3, 0, 5)],
      ]);
      final portes = generatePlays(p, S.one, const [5, 2], _portes, _ctx);
      expect(
          sequencesOf(portes),
          unorderedEquals([
            [const Step(3, 0, 5)],
            [const Step(3, 1, 2), const Step(1, 0, 5)],
          ]));
    });

    test('D5 most checkers borne off first', () {
      // one on 5 and 1, dice 6-3: 5 off (6), 1 off (3) bears off two;
      // 5->2 (3), 2 off (6) bears off one. Both use both dice.
      final p = pos(one: {5: 1, 1: 1}, two: {1: 15});
      final allOff = after(p, S.one, _tavla, const [
        Step(5, 0, 6),
        Step(1, 0, 3),
      ]);
      final oneOff = after(p, S.one, _tavla, const [
        Step(5, 2, 3),
        Step(2, 0, 6),
      ]);
      expect(generatePlays(p, S.one, const [6, 3], _portes, _ctx).finals,
          {allOff, oneOff});
      expect(
          generatePlays(p, S.one, const [6, 3], _tavla, _ctx).finals, {allOff});
    });

    test('D5 does not touch plays without bear-offs', () {
      final p = Position.forRules(_tavla);
      expect(
        generatePlays(p, S.one, const [3, 1], _tavla, _ctx).finals,
        generatePlays(p, S.one, const [3, 1], _portes, _ctx).finals,
      );
    });
  });

  group('D12-A Fevga primes', () {
    test('D12a Fevga own start six-prime forbidden', () {
      // Released (a checker on 8). 24->19 (5) + 24->23 (1) would hold all
      // of 19..24; e.g. 8->3, 3->2 would not.
      final p = posSame(
        one: {24: 10, 23: 1, 22: 1, 21: 1, 20: 1, 8: 1},
        two: {24: 15},
      );
      final prime = after(p, S.one, _fevga, const [
        Step(24, 19, 5),
        Step(24, 23, 1),
      ]);
      final open = after(p, S.one, _fevga, const [
        Step(8, 3, 5),
        Step(3, 2, 1),
      ]);
      final free = generatePlays(p, S.one, const [5, 1], _gulBara, _ctx);
      expect(free.finals, contains(prime));
      final t = generatePlays(p, S.one, const [5, 1], _fevga, _ctx);
      expect(t.finals, contains(open));
      expect(t.finals, isNot(contains(prime)));
      expect(t.finals.where((f) => holdsAll(f, S.one, range(19, 24))), isEmpty);
    });

    test('D12a every play completes it: all survive', () {
      // two blocks my 14..18 (= its 2..6); every 5 and 4 keeps 19..24.
      final p = posSame(
        one: {24: 6, 23: 2, 22: 2, 21: 2, 20: 2, 3: 1},
        two: {24: 10, 2: 1, 3: 1, 4: 1, 5: 1, 6: 1},
      );
      final t = generatePlays(p, S.one, const [5, 4], _fevga, _ctx);
      final free = generatePlays(p, S.one, const [5, 4], _gulBara, _ctx);
      expect(t.finals, isNotEmpty);
      expect(t.finals.every((f) => holdsAll(f, S.one, range(19, 24))), isTrue);
      expect(t.finals, free.finals);
    });

    // My 6..11 = two's 18..23; two's head (its 24) = my 12.
    Position sixBefore(Map<int, int> two) => posSame(
          one: {24: 9, 11: 1, 10: 1, 9: 2, 8: 1, 7: 1},
          two: two,
        );
    const completing = [Step(9, 6, 3), Step(24, 23, 1)];

    test('D12b Fevga six in front of occupied opp head', () {
      // two's runner on its 5 (= my 17) keeps two a move (D13 is not why).
      final p = sixBefore({24: 14, 5: 1});
      final prime = after(p, S.one, _fevga, completing);
      final t = generatePlays(p, S.one, const [3, 1], _fevga, _ctx);
      expect(t.hasPlay, isTrue);
      expect(t.finals, isNot(contains(prime)));
      expect(t.finals.where((f) => holdsAll(f, S.one, range(6, 11))), isEmpty);
      final free = generatePlays(p, S.one, const [3, 1], _gulBara, _ctx);
      expect(free.finals, contains(prime));
    });

    test('D12b with the opp head empty the prime is allowed', () {
      final p = sixBefore({5: 15});
      final prime = after(p, S.one, _fevga, completing);
      final t = generatePlays(p, S.one, const [3, 1], _fevga, _ctx);
      expect(t.finals, contains(prime));
    });
  });

  group('D14-B Moultezim', () {
    test('D14 Moultezim max four in opp start quarter', () {
      // Holds 8..11 (four points of 7..12); 8->7 would make a fifth.
      final p = posSame(
        one: {24: 10, 11: 1, 10: 1, 9: 1, 8: 2},
        two: {24: 15},
      );
      final fifth = after(p, S.one, _moultezim, const [
        Step(8, 7, 1),
        Step(24, 18, 6),
      ]);
      final free = generatePlays(p, S.one, const [1, 6], _gulBara, _ctx);
      expect(free.finals, contains(fifth));
      final t = generatePlays(p, S.one, const [1, 6], _moultezim, _ctx);
      expect(t.hasPlay, isTrue);
      expect(t.finals, isNot(contains(fifth)));
      expect(t.finals.every((f) => held(f, S.one, range(7, 12)) <= 4), isTrue);
    });

    test('D14 Moultezim own start six-prime forbidden', () {
      final p = posSame(
        one: {24: 10, 23: 1, 22: 1, 21: 1, 20: 1, 8: 1},
        two: {24: 15},
      );
      final t = generatePlays(p, S.one, const [5, 1], _moultezim, _ctx);
      expect(t.hasPlay, isTrue);
      expect(t.finals.where((f) => holdsAll(f, S.one, range(19, 24))), isEmpty);
    });
  });

  group('D13-A leave a move (Fevga)', () {
    // two: runner on its 20 (= my 8), 14 on an unreleased head, so its only
    // first steps are runner steps to its 19..14 = my 7..2.
    const two = {24: 14, 20: 1};

    test('D13 leave a move', () {
      // 3->2 (1) completes my 2..7 and leaves two no step for any die.
      final p = posSame(
        one: {24: 9, 7: 1, 6: 1, 5: 1, 4: 1, 3: 2},
        two: two,
      );
      final stuck = after(p, S.one, _fevga, const [
        Step(3, 2, 1),
        Step(24, 18, 6),
      ]);
      final free = generatePlays(p, S.one, const [1, 6], _gulBara, _ctx);
      expect(free.finals, contains(stuck));
      final t = generatePlays(p, S.one, const [1, 6], _fevga, _ctx);
      expect(t.hasPlay, isTrue);
      expect(t.finals, isNot(contains(stuck)));
      expect(t.finals.where((f) => holdsAll(f, S.one, range(2, 7))), isEmpty);
    });

    test('D13 every play leaves no move: all survive', () {
      // Each of my 2..7 keeps a checker whatever 6-5 is played.
      final p = posSame(
        one: {24: 3, 7: 3, 6: 2, 5: 2, 4: 2, 3: 2, 2: 1},
        two: two,
      );
      final t = generatePlays(p, S.one, const [6, 5], _fevga, _ctx);
      final free = generatePlays(p, S.one, const [6, 5], _gulBara, _ctx);
      expect(t.hasPlay, isTrue);
      expect(t.finals.every((f) => holdsAll(f, S.one, range(2, 7))), isTrue);
      expect(t.finals, free.finals);
    });
  });
}
