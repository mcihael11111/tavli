import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

void main() {
  test('§1 opposing: my pip p is the opponent pip 25 - p', () {
    const g = Geometry(Direction.opposing);
    expect(g.toOpponent(1), 24);
    expect(g.toOpponent(24), 1);
    expect(g.toOpponent(6), 19);
    expect(g.toOpponent(13), 12);
  });

  test('§1 same: opponent head (their 24) is my 12, their 1 is my 13', () {
    const g = Geometry(Direction.same);
    expect(g.toOpponent(24), 12);
    expect(g.toOpponent(12), 24);
    expect(g.toOpponent(13), 1);
    expect(g.toOpponent(1), 13);
  });

  test(
      '§1 same: opponent home (their 1..6) is my 13..18, their start '
      'quarter (19..24) is my 7..12', () {
    const g = Geometry(Direction.same);
    for (var q = 1; q <= 6; q++) {
      expect(g.toOpponent(q + 12), q);
    }
    for (var q = 19; q <= 24; q++) {
      expect(g.toOpponent(q - 12), q);
    }
  });

  test('§1 toOpponent is an involution over 1..24 in both directions', () {
    for (final d in Direction.values) {
      final g = Geometry(d);
      final seen = <int>{};
      for (var p = 1; p <= 24; p++) {
        final q = g.toOpponent(p);
        expect(q, inInclusiveRange(1, 24), reason: '$d $p');
        expect(g.toOpponent(q), p, reason: '$d $p');
        seen.add(q);
      }
      expect(seen.length, 24, reason: '$d is a bijection');
    }
  });

  test('Geometry.of returns the geometry for a direction', () {
    for (final d in Direction.values) {
      expect(Geometry.of(d).direction, d);
    }
  });
}
