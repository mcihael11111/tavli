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

  group('checkGameEnd scoring', () {
    GameResult? end(Position p, Variant v, {int cube = 1}) =>
        checkGameEnd(p, v.rules, justMoved: S.one, cubeValue: cube);
    GameResult win(ResultKind kind, int points, {int cube = 1}) =>
        GameResult(winner: S.one, kind: kind, points: points, cubeValue: cube);

    test('only the opponent\'s mother counts (agrees with endsGame)', () {
      // One's mother is pinned by two and two's start is empty: a finished
      // position for two, but not an end caused by a step of one.
      final p = pos(
        one: {24: 1, 6: 14},
        two: {1: 1, 13: 14},
        pinnedOne: {24},
      );
      expect(end(p, Variant.plakoto), isNull);
      expect(endsGame(p, Variant.plakoto.rules, S.one), isFalse);
      expect(
        checkGameEnd(p, Variant.plakoto.rules, justMoved: S.two, cubeValue: 1),
        const GameResult(
            winner: S.two, kind: ResultKind.mother, points: 2, cubeValue: 1),
      );
    });

    test('no end while checkers remain', () {
      expect(end(pos(one: {2: 1}, two: {24: 15}), Variant.portes), isNull);
    });

    test('G8 single', () {
      final p = pos(one: {}, two: {6: 12}, offTwo: 3);
      expect(end(p, Variant.portes), win(ResultKind.single, 1));
    });

    test('G8 gammon', () {
      final p = pos(one: {}, two: {6: 15});
      expect(end(p, Variant.portes), win(ResultKind.gammon, 2));
    });

    test('D6 portes triple counts as 2', () {
      // two's 20 is in my home: a backgammon elsewhere, a gammon here.
      final p = pos(one: {}, two: {20: 1, 6: 14});
      expect(end(p, Variant.portes), win(ResultKind.gammon, 2));
      expect(end(p, Variant.tavla), win(ResultKind.gammon, 2));
    });

    test('shortNard koks: the bar or the winner home, none off', () {
      final home = pos(one: {}, two: {19: 1, 6: 14});
      expect(end(home, Variant.shortNard), win(ResultKind.triple, 3));
      final bar = pos(one: {}, two: {6: 14}, barTwo: 1);
      expect(end(bar, Variant.shortNard), win(ResultKind.triple, 3));
      final off = pos(one: {}, two: {19: 1, 6: 13});
      expect(end(off, Variant.shortNard), win(ResultKind.single, 1),
          reason: 'one borne off: no triple, no gammon');
    });

    test('D6 sheshBesh Turkish mars: winner home only', () {
      final home = pos(one: {}, two: {24: 1, 6: 14});
      expect(end(home, Variant.sheshBesh), win(ResultKind.triple, 3));
      final bar = pos(one: {}, two: {6: 14}, barTwo: 1);
      expect(end(bar, Variant.sheshBesh), win(ResultKind.gammon, 2));
    });

    test('cube multiplies', () {
      final p = pos(one: {}, two: {6: 15});
      expect(end(p, Variant.shortNard, cube: 4),
          win(ResultKind.gammon, 8, cube: 4));
      final koks = pos(one: {}, two: {19: 1, 6: 14});
      expect(end(koks, Variant.shortNard, cube: 2),
          win(ResultKind.triple, 6, cube: 2));
    });

    test('D21 tawla31 checkersRemaining', () {
      final p = posSame(one: {}, two: {3: 4, 1: 2});
      expect(end(p, Variant.tawla31), win(ResultKind.checkersRemaining, 6));
    });

    test('D8 mother win and draws, from either side', () {
      final mother = pos(
        one: {1: 1, 10: 14},
        two: {24: 1, 13: 14},
        pinnedTwo: {24},
      );
      expect(end(mother, Variant.plakoto), win(ResultKind.mother, 2));
      final both = pos(
        one: {24: 1, 1: 1, 10: 13},
        two: {24: 1, 1: 1, 13: 13},
        pinnedOne: {24},
        pinnedTwo: {24},
      );
      const draw0 = GameResult(
          winner: null, kind: ResultKind.draw, points: 0, cubeValue: 1);
      expect(end(both, Variant.plakoto), draw0);
      expect(end(both, Variant.mahbusa), draw0);
      expect(
        end(both, Variant.tapa),
        const GameResult(
            winner: null, kind: ResultKind.draw, points: 1, cubeValue: 1),
      );
      expect(end(mother, Variant.portes), isNull, reason: 'no mother rule');
    });
  });
}
