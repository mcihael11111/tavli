import 'dart:math';

import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/asserts.dart';
import '../support/positions.dart';

void main() {
  group('MutablePosition', () {
    test('mutate-then-freeze equals a fromPips-built position', () {
      final m =
          Position.start(Layout.standard2535, Direction.opposing).toMutable();
      m.move(Side.one, 24, 18);
      m.move(Side.one, 8, 5);
      m.move(Side.two, 13, 10);
      expect(
        m.freeze(),
        pos(
          one: {24: 1, 18: 1, 13: 5, 8: 2, 6: 5, 5: 1},
          two: {24: 2, 13: 4, 10: 1, 8: 3, 6: 5},
        ),
      );
    });

    test('hit and bear-off through the mutable API', () {
      final m = pos(one: {8: 1, 2: 1}, two: {20: 1}).toMutable();
      m.move(Side.one, 8, 5);
      m.move(Side.two, 20, 25);
      m.move(Side.one, 2, 0);
      final p = m.freeze();
      expect(p, pos(one: {5: 1}, two: {}, barTwo: 1));
      expect(p.borneOff(Side.one), 14);
      expect(p.onBar(Side.two), 1);
    });

    test('pin bits round-trip through the mutable API', () {
      final m = pos(one: {8: 1}, two: {19: 1}).toMutable();
      m.move(Side.one, 8, 6);
      m.setPinned(Side.two, 19, true);
      expect(m.isPinned(Side.two, 19), isTrue);
      expect(
        m.freeze(),
        pos(one: {6: 1}, two: {19: 1}, pinnedTwo: {19}),
      );
      m.setPinned(Side.two, 19, false);
      m.move(Side.one, 6, 8);
      expect(m.freeze(), pos(one: {8: 1}, two: {19: 1}));
    });

    test('freeze is a snapshot and toMutable does not alias', () {
      final p = Position.start(Layout.stackOpposing, Direction.opposing);
      final m = p.toMutable();
      final frozen = m.freeze();
      m.move(Side.one, 24, 20);
      expect(frozen, p);
      expect(p.count(Side.one, 24), 15);
      expect(m.count(Side.one, 24), 14);
      expect(m.toMutable().freeze(), m.freeze());
    });

    test('mutable read helpers match the frozen position', () {
      final m = pos(one: {7: 1, 3: 13}, two: {1: 2}, barTwo: 1).toMutable();
      final p = m.freeze();
      for (final s in Side.values) {
        expect(m.pipCount(s), p.pipCount(s));
        expect(m.allHome(s), p.allHome(s));
        expect(m.borneOff(s), p.borneOff(s));
        expect(m.onBar(s), p.onBar(s));
        expect(m.checkersOnBoard(s), p.checkersOnBoard(s));
      }
      m.move(Side.one, 7, 4);
      expect(m.allHome(Side.one), isTrue);
    });

    test('add/remove reject pips outside 0..25 with RangeError', () {
      final m = pos(one: {}, two: {}).toMutable();
      expect(() => m.add(Side.one, -1), throwsRangeError);
      expect(() => m.remove(Side.two, 26), throwsRangeError);
      expect(() => m.count(Side.one, 26), throwsRangeError);
    });

    test('freeze validates in debug builds: pin bit with no pinner', () {
      if (!assertsOn) return;
      final m = pos(one: {3: 1}, two: {}).toMutable()
        ..setPinned(Side.one, 3, true);
      expect(m.freeze, throwsArgumentError);
    });

    test('freeze validates in debug builds: side not totalling 15', () {
      if (!assertsOn) return;
      final m = pos(one: {3: 1}, two: {}).toMutable()..add(Side.one, 5);
      expect(m.freeze, throwsArgumentError);
    });

    test('freeze validates in debug builds: shared unpinned point', () {
      if (!assertsOn) return;
      final m = pos(one: {8: 1}, two: {19: 1}).toMutable()
        ..move(Side.one, 8, 6);
      expect(m.freeze, throwsArgumentError);
    });
  });

  group('MutablePosition Zobrist hash', () {
    int fresh(MutablePosition m) => m.freeze().toMutable().zobristHash;

    test('stays equal to a from-scratch hash under random make/unmake', () {
      final r = Random(5);
      final rules = Variant.plakoto.rules;
      final steps = StepRules(rules);
      for (final p in [
        Position.forRules(rules),
        pos(one: {8: 1, 6: 3}, two: {18: 1, 1: 2}),
      ]) {
        final m = p.toMutable();
        final applied = <(Side, AppliedStep)>[];
        for (var i = 0; i < 400; i++) {
          final side = r.nextBool() ? Side.one : Side.two;
          final moves = steps.basicSteps(m, side, 1 + r.nextInt(6));
          if (moves.isNotEmpty && (applied.isEmpty || r.nextInt(3) > 0)) {
            final a = steps.apply(m, side, moves[r.nextInt(moves.length)]);
            applied.add((side, a));
          } else if (applied.isNotEmpty) {
            final (s, a) = applied.removeLast();
            steps.undo(m, s, a);
          }
          expect(m.zobristHash, fresh(m));
          expect(m.zobristHash, inInclusiveRange(0, (1 << 30) - 1));
        }
        while (applied.isNotEmpty) {
          final (s, a) = applied.removeLast();
          steps.undo(m, s, a);
        }
        expect(m.zobristHash, p.toMutable().zobristHash);
        expect(m.sameBoardAs(p), isTrue);
      }
    });

    test('equal boards hash equal whatever the move order', () {
      final a = Position.forRules(Variant.portes.rules).toMutable()
        ..move(Side.one, 24, 18)
        ..move(Side.one, 13, 10);
      final b = Position.forRules(Variant.portes.rules).toMutable()
        ..move(Side.one, 13, 10)
        ..move(Side.one, 24, 18);
      expect(a.zobristHash, b.zobristHash);
      expect(a.sameBoardAs(b.freeze()), isTrue);
      b.move(Side.one, 10, 9);
      expect(a.zobristHash, isNot(b.zobristHash));
      expect(a.sameBoardAs(b.freeze()), isFalse);
    });

    test('pinned bits count, and setting a bit twice is a no-op', () {
      final m = pos(one: {6: 1}, two: {19: 1}, pinnedTwo: {19}).toMutable();
      final h0 = m.zobristHash;
      m.setPinned(Side.two, 19, false);
      final h1 = m.zobristHash;
      expect(h1, isNot(h0));
      m.setPinned(Side.two, 19, false);
      expect(m.zobristHash, h1);
      m.setPinned(Side.two, 19, true);
      m.setPinned(Side.two, 19, true);
      expect(m.zobristHash, h0);
    });

    test('sameBoardAs compares direction and pinned bits too', () {
      final opp = pos(one: {6: 1}, two: {17: 1});
      expect(opp.toMutable().sameBoardAs(opp), isTrue);
      final same = posSame(one: {6: 1}, two: {17: 1});
      expect(opp.toMutable().sameBoardAs(same), isFalse);
      final pinTwo = pos(one: {6: 1}, two: {19: 1}, pinnedTwo: {19});
      final pinOne = pos(one: {6: 1}, two: {19: 1}, pinnedOne: {6});
      expect(pinTwo.toMutable().sameBoardAs(pinTwo), isTrue);
      expect(pinTwo.toMutable().sameBoardAs(pinOne), isFalse);
    });
  });
}
