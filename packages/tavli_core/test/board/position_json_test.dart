import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/positions.dart';

void main() {
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
        throwsFormatException,
      );
    });

    test('fromJson rejects a side not totalling 15', () {
      final j = pos(one: {}, two: {}).toJson();
      final one = List<int>.filled(26, 0)..[0] = 14;
      expect(
        () => Position.fromJson({...j, 'one': one}),
        throwsFormatException,
      );
    });

    test('fromJson rejects duplicate pinned pips', () {
      final j = pos(one: {1: 1}, two: {24: 1}, pinnedOne: {1}).toJson();
      expect(
        () => Position.fromJson({
          ...j,
          'pinnedOne': [1, 1],
        }),
        throwsFormatException,
      );
    });

    test('fromJson wraps every invalid payload in FormatException', () {
      final j = pos(one: {}, two: {}).toJson();
      for (final bad in <Map<String, Object?>>[
        {...j, 'direction': 'sideways'},
        {
          ...j,
          'pinnedOne': [0]
        },
        {
          ...j,
          'pinnedTwo': [25]
        },
        {...j, 'pinnedOne': 'x'},
        {...j, 'two': List<Object?>.filled(26, null)},
        {...j, 'one': List<int>.filled(26, 0)..[0] = 16},
        // Shared point without a pin.
        {
          ...j,
          'one': List<int>.filled(26, 0)
            ..[0] = 14
            ..[6] = 1,
          'two': List<int>.filled(26, 0)
            ..[0] = 14
            ..[19] = 1,
        },
      ]) {
        expect(() => Position.fromJson(bad), throwsFormatException,
            reason: '$bad');
      }
    });

    test('toJson emits plain int lists for schema v1', () {
      final j =
          Position.start(Layout.standard2535, Direction.opposing).toJson();
      expect(j.keys, {'direction', 'one', 'two', 'pinnedOne', 'pinnedTwo'});
      expect(j['one'], isA<List<int>>());
      expect((j['one']! as List<int>).length, 26);
      expect(j['pinnedOne'], isEmpty);
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
