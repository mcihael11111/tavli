import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/positions.dart';

const _std = {24: 2, 13: 5, 8: 3, 6: 5};

void main() {
  group('start positions', () {
    test('G1 standard start: 167 pips each, nothing off', () {
      final p = Position.start(Layout.standard2535, Direction.opposing);
      for (final s in Side.values) {
        expect(p.pipCount(s), 167);
        expect(p.borneOff(s), 0);
        expect(p.onBar(s), 0);
        expect(p.checkersOnBoard(s), 15);
        expect(p.count(s, 24), 2);
        expect(p.count(s, 13), 5);
        expect(p.count(s, 8), 3);
        expect(p.count(s, 6), 5);
      }
    });

    test('G1 stack starts: 360 pips each, all 15 on pip 24', () {
      for (final (layout, dir) in [
        (Layout.stackOpposing, Direction.opposing),
        (Layout.stackDiagonal, Direction.same),
      ]) {
        final p = Position.start(layout, dir);
        expect(p.direction, dir);
        for (final s in Side.values) {
          expect(p.pipCount(s), 360);
          expect(p.borneOff(s), 0);
          expect(p.count(s, 24), 15);
        }
      }
    });

    test('start equals the fromPips equivalent', () {
      expect(
        Position.start(Layout.standard2535, Direction.opposing),
        pos(one: _std, two: _std),
      );
      expect(
        Position.start(Layout.stackDiagonal, Direction.same),
        posSame(one: {24: 15}, two: {24: 15}),
      );
    });
  });

  group('fromPips validation', () {
    test('G1 rejects 16 checkers', () {
      expect(() => pos(one: {24: 16}, two: {}), throwsArgumentError);
      expect(() => pos(one: {24: 15}, two: {}, barOne: 1), throwsArgumentError);
      expect(() => pos(one: {}, two: {1: 10, 2: 6}), throwsArgumentError);
    });

    test('G1 derives borneOff from omitted checkers', () {
      final p = pos(one: {1: 5}, two: {});
      expect(p.borneOff(Side.one), 10);
      expect(p.count(Side.one, 0), 10);
      expect(p.checkersOnBoard(Side.one), 5);
      expect(p.borneOff(Side.two), 15);
      expect(pos(one: {}, two: {}, barTwo: 2).borneOff(Side.two), 13);
    });

    test('rejects negative counts and bar', () {
      expect(() => pos(one: {5: -1}, two: {}), throwsArgumentError);
      expect(() => pos(one: {}, two: {}, barOne: -1), throwsArgumentError);
    });

    test('rejects map keys outside pips 1..24', () {
      for (final bad in [0, 25, 26, -1]) {
        expect(() => pos(one: {bad: 1}, two: {}), throwsArgumentError);
        expect(() => pos(one: {}, two: {bad: 1}), throwsArgumentError);
      }
    });

    test('allows zero entries', () {
      expect(pos(one: {5: 0}, two: {}), pos(one: {}, two: {}));
    });

    test('§4.2 rejects both sides on one physical point without a pin', () {
      // My 6 is the opponent's 19 in the opposing direction.
      expect(() => pos(one: {6: 1}, two: {19: 1}), throwsArgumentError);
      // Same direction: my 24 is the opponent's 12.
      expect(() => posSame(one: {24: 1}, two: {12: 1}), throwsArgumentError);
    });

    test('§4.2 pinned bit needs exactly one owner checker and a pinner', () {
      // Valid: one has 1 on pip 1 under two's checker on its pip 24.
      expect(
        pos(one: {1: 1}, two: {24: 3}, pinnedOne: {1}).isPinned(Side.one, 1),
        isTrue,
      );
      // Two owner checkers on the pinned pip.
      expect(
        () => pos(one: {1: 2}, two: {24: 1}, pinnedOne: {1}),
        throwsArgumentError,
      );
      // No owner checker.
      expect(
        () => pos(one: {}, two: {24: 1}, pinnedOne: {1}),
        throwsArgumentError,
      );
      // No pinner.
      expect(
          () => pos(one: {1: 1}, two: {}, pinnedOne: {1}), throwsArgumentError);
    });

    test('§4.2 pinned pips must be 1..24', () {
      for (final bad in [0, 25, 26]) {
        expect(
          () => pos(one: {1: 1}, two: {24: 1}, pinnedOne: {bad}),
          throwsArgumentError,
        );
      }
    });

    test('§4.2 a point cannot be pinned both ways', () {
      expect(
        () => pos(
          one: {1: 1},
          two: {24: 1},
          pinnedOne: {1},
          pinnedTwo: {24},
        ),
        throwsArgumentError,
      );
    });

    test('is not affected by later changes to the input maps', () {
      final one = {24: 15};
      final p = pos(one: one, two: {24: 15});
      one[24] = 3;
      expect(p.count(Side.one, 24), 15);
    });
  });

  group('equality and hash', () {
    test('separately built equal positions are == with equal hashCode', () {
      final a = pos(one: _std, two: {2: 3, 7: 2}, barTwo: 1);
      final b = pos(one: Map.of(_std), two: {7: 2, 2: 3}, barTwo: 1);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect({a, b}.length, 1);
    });

    test('positions differing only in a pinned bit are !=', () {
      // Same counts; only which side of the pair is pinned differs.
      final a = pos(one: {1: 1, 6: 2}, two: {24: 1}, pinnedOne: {1});
      final b = pos(one: {1: 1, 6: 2}, two: {24: 1}, pinnedTwo: {24});
      expect(a, isNot(b));
      expect(a.pinnedMask(Side.one), isNot(b.pinnedMask(Side.one)));
    });

    test('a shared point without a pin bit is not a valid position', () {
      expect(() => pos(one: {1: 1}, two: {24: 1}), throwsArgumentError);
    });

    test('positions differing in direction or side are !=', () {
      expect(
        pos(one: {24: 15}, two: {24: 15}),
        isNot(posSame(one: {24: 15}, two: {24: 15})),
      );
      expect(pos(one: {3: 1}, two: {}), isNot(pos(one: {}, two: {3: 1})));
    });

    test('hashCode is web-safe (0 <= h < 2^30)', () {
      final samples = [
        Position.start(Layout.standard2535, Direction.opposing),
        Position.start(Layout.stackOpposing, Direction.opposing),
        Position.start(Layout.stackDiagonal, Direction.same),
        pos(one: {1: 1}, two: {24: 15}, pinnedOne: {1}),
        pos(one: {}, two: {}, barOne: 15, barTwo: 15),
      ];
      for (final p in samples) {
        expect(p.hashCode, inInclusiveRange(0, (1 << 30) - 1));
        expect(p.hashCode, p.hashCode);
      }
    });
  });

  group('helpers', () {
    test('pipCount counts the bar as 25', () {
      expect(pos(one: {3: 2}, two: {}, barOne: 1).pipCount(Side.one), 31);
    });

    test('G5 allHome: nothing on pips 7..25', () {
      expect(pos(one: {6: 5, 1: 10}, two: {}).allHome(Side.one), isTrue);
      expect(pos(one: {7: 1, 3: 14}, two: {}).allHome(Side.one), isFalse);
      expect(pos(one: {3: 1}, two: {}, barOne: 1).allHome(Side.one), isFalse);
    });

    test('§3.2 a pinned checker counts toward totals, pips and allHome', () {
      final p = pos(one: {3: 1, 5: 14}, two: {22: 1}, pinnedOne: {3});
      expect(p.allHome(Side.one), isTrue);
      expect(p.checkersOnBoard(Side.one), 15);
      expect(p.pipCount(Side.one), 73);
    });

    test('onBar and pinnedMask', () {
      final p = pos(one: {1: 1}, two: {24: 1}, barOne: 2, pinnedOne: {1});
      expect(p.onBar(Side.one), 2);
      expect(p.count(Side.one, 25), 2);
      expect(p.pinnedMask(Side.one), 1 << 1);
      expect(p.pinnedMask(Side.two), 0);
    });
  });

  group('controller', () {
    test('opposing: one holds my 6, which is two\'s 19', () {
      final p = pos(one: {6: 2}, two: {});
      expect(p.controller(Side.two, 19), Side.one);
      expect(p.controller(Side.one, 6), Side.one);
    });

    test('§4.2 pinned pair: the pinner controls the point', () {
      final p = pos(one: {1: 1}, two: {24: 1}, pinnedOne: {1});
      expect(p.controller(Side.one, 1), Side.two);
      expect(p.controller(Side.two, 24), Side.two);
    });

    test('same direction: two on its 24 controls my 12', () {
      final p = posSame(one: {}, two: {24: 1});
      expect(p.controller(Side.one, 12), Side.two);
      expect(p.controller(Side.one, 24), isNull);
    });

    test('empty point has no controller', () {
      expect(pos(one: {}, two: {}).controller(Side.one, 5), isNull);
    });
  });

  group('JSON', () {
    final cases = {
      'standard': Position.start(Layout.standard2535, Direction.opposing),
      'stackOpposing': Position.start(Layout.stackOpposing, Direction.opposing),
      'stackDiagonal': Position.start(Layout.stackDiagonal, Direction.same),
      'pinned': pos(
        one: {1: 1, 5: 1, 6: 4},
        two: {24: 2, 3: 1, 20: 1},
        pinnedOne: {1},
        pinnedTwo: {20},
      ),
      'bar': pos(one: {6: 3}, two: {19: 0, 5: 2}, barOne: 2, barTwo: 1),
    };
    for (final MapEntry(key: name, value: p) in cases.entries) {
      test('round-trips $name', () {
        final back = Position.fromJson(p.toJson());
        expect(back, p);
        expect(back.hashCode, p.hashCode);
        expect(back.toJson(), p.toJson());
      });
    }

    test('fromJson validates the position', () {
      final j = pos(one: {1: 1}, two: {24: 1}, pinnedOne: {1}).toJson();
      // Remove the pinner: the pinned bit becomes invalid.
      final two = List<int>.from(j['two']! as List<Object?>)
        ..[24] = 0
        ..[0] = 15;
      expect(
        () => Position.fromJson({...j, 'two': two}),
        throwsA(anyOf(isArgumentError, isFormatException)),
      );
    });

    test('fromJson rejects a side not totalling 15', () {
      final j = pos(one: {}, two: {}).toJson();
      final one = List<int>.filled(26, 0)..[0] = 14;
      expect(
        () => Position.fromJson({...j, 'one': one}),
        throwsA(anyOf(isArgumentError, isFormatException)),
      );
    });

    test('fromJson rejects malformed input', () {
      expect(() => Position.fromJson({}), throwsFormatException);
      final j = pos(one: {}, two: {}).toJson();
      expect(
        () => Position.fromJson({
          ...j,
          'one': <int>[15]
        }),
        throwsFormatException,
      );
    });
  });
}
