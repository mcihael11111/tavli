import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

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
  });
}
