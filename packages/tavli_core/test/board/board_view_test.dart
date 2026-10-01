import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/positions.dart';

/// A consumer written only against [BoardView].
String describe(BoardView b, Side s) => [
      b.direction.name,
      b.geometry.direction.name,
      b.count(s, 6),
      b.isPinned(s, 1),
      b.pinnedMask(s),
      b.onBar(s),
      b.borneOff(s),
      b.pipCount(s),
      b.allHome(s),
      b.checkersOnBoard(s),
      b.controller(s, 1)?.name,
    ].join('|');

void main() {
  test('Position and MutablePosition both serve as a BoardView', () {
    final p = pos(one: {1: 1, 6: 3}, two: {24: 1}, barOne: 1, pinnedOne: {1});
    final BoardView frozen = p;
    final BoardView mutable = p.toMutable();
    for (final s in Side.values) {
      expect(describe(mutable, s), describe(frozen, s));
    }
    expect(describe(frozen, Side.one),
        'opposing|opposing|3|true|2|1|10|44|false|5|two');
  });
}
