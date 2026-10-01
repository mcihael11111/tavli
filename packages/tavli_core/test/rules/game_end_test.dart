import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import '../support/positions.dart';

typedef S = Side;

final _portes = Variant.portes.rules;
final _plakoto = Variant.plakoto.rules;

void main() {
  test('G8 the 15th checker borne off ends the game', () {
    expect(endsGame(pos(one: {}, two: {24: 15}), _portes, S.one), isTrue);
    expect(endsGame(pos(one: {2: 1}, two: {24: 15}), _portes, S.one), isFalse);
    // Only the side that just moved counts.
    expect(endsGame(pos(one: {}, two: {24: 15}), _portes, S.two), isFalse);
  });

  group('mother rule (A4)', () {
    // two's mother (its 24 = my 1) pinned under my checker on 1.
    test('D8a pinner has left its start: ends at once', () {
      final p = pos(one: {1: 1, 10: 14}, two: {24: 1, 13: 14}, pinnedTwo: {24});
      expect(endsGame(p, _plakoto, S.one), isTrue);
    });

    test('D8b pinner still on its start: not yet', () {
      final p = pos(
        one: {24: 1, 1: 1, 10: 13},
        two: {24: 1, 13: 14},
        pinnedTwo: {24},
      );
      expect(endsGame(p, _plakoto, S.one), isFalse);
    });

    test('D8b both mothers pinned: a draw ends the game', () {
      // My mother (my 24 = two's 1) pinned under two's checker there.
      final p = pos(
        one: {24: 1, 1: 1, 10: 13},
        two: {24: 1, 1: 1, 13: 13},
        pinnedOne: {24},
        pinnedTwo: {24},
      );
      expect(endsGame(p, _plakoto, S.one), isTrue);
    });

    test('D9/D10 Tapa and Mahbusa use the same rule', () {
      final p = pos(one: {1: 1, 10: 14}, two: {24: 1, 13: 14}, pinnedTwo: {24});
      for (final v in [Variant.tapa, Variant.mahbusa, Variant.mahbusaArab]) {
        expect(endsGame(p, v.rules, S.one), isTrue, reason: '$v');
      }
    });

    test('no mother pinned: the game goes on', () {
      // two's mother alone on its 24 (= my 1), not pinned.
      final p = pos(one: {10: 15}, two: {24: 1, 13: 14});
      expect(endsGame(p, _plakoto, S.one), isFalse);
    });
  });
}
