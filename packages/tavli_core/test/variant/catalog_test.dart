import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import 'catalog_expect.dart';

void main() {
  test('catalog has all 13 variants', () {
    expect(variantCatalog.length, 13);
    expect(Variant.values.length, 13);
    for (final v in Variant.values) {
      expect(variantCatalog.containsKey(v), isTrue, reason: v.name);
      expect(identical(v.rules, variantCatalog[v]), isTrue);
    }
  });

  group('named decisions', () {
    test('D1 portes plays opening dice', () {
      expect(Variant.portes.rules.opening, OpeningProcedure.playOpeningDice);
    });

    test('D1 tavla winner rerolls', () {
      expect(Variant.tavla.rules.opening, OpeningProcedure.winnerRerolls);
    });

    test('D1 opening procedure per variant', () {
      const rerolls = {
        Variant.tavla,
        Variant.tapa,
        Variant.moultezim,
        Variant.gulBara,
      };
      for (final v in Variant.values) {
        expect(
          v.rules.opening,
          rerolls.contains(v)
              ? OpeningProcedure.winnerRerolls
              : OpeningProcedure.playOpeningDice,
          reason: v.name,
        );
      }
    });

    test('D2 previous winner starts only in the Tavli trio', () {
      const tavli = {Variant.portes, Variant.plakoto, Variant.fevga};
      for (final v in Variant.values) {
        expect(
          v.rules.nextGame,
          tavli.contains(v)
              ? NextGameStarter.previousWinner
              : NextGameStarter.openingRoll,
          reason: v.name,
        );
      }
    });

    test(
        'D20 tawla31 is a running game with checkersRemaining scoring and '
        'target 31', () {
      final r = Variant.tawla31.rules;
      expect(r.contact, Contact.block);
      expect(r.direction, Direction.same);
      expect(r.scoring.model, ScoringModel.checkersRemaining);
      expect(r.match.fixedTarget, 31);
    });

    test('D9 tapa both-pinned scores 1 each', () {
      expect(Variant.tapa.rules.pin!.bothPinnedPoints, 1);
      expect(Variant.plakoto.rules.pin!.bothPinnedPoints, 0);
    });

    test('D7 shortNard cube on with crawford', () {
      final cube = Variant.shortNard.rules.cube;
      expect(cube.available && cube.enabledByDefault && cube.crawford, isTrue);
    });

    test('D7 cube is available only in shortNard, longNard and sheshBesh', () {
      const withCube = {Variant.shortNard, Variant.longNard, Variant.sheshBesh};
      for (final v in Variant.values) {
        expect(v.rules.cube.available, withCube.contains(v), reason: v.name);
      }
    });

    test('D6 portes has no triple', () {
      expect(Variant.portes.rules.scoring.triple, isNull);
      expect(Variant.tavla.rules.scoring.triple, isNull);
    });

    test('D14 moultezim max 4 points in opp start quarter', () {
      expect(Variant.moultezim.rules.primes.maxPointsInOppStartQuarter, 4);
    });

    test('D19 longNard trap check', () {
      expect(Variant.longNard.rules.primes.noPrimeTrappingAll, isTrue);
      for (final v in Variant.values.where((v) => v != Variant.longNard)) {
        expect(v.rules.primes.noPrimeTrappingAll, isFalse, reason: v.name);
      }
    });

    test('D18 longNard head exception {3,4,6}', () {
      final head = Variant.longNard.rules.head!;
      expect(head.firstTurnDoubles, {3, 4, 6});
      expect(head.maxOnException, 2);
      expect(head.maxPerTurn, 1);
    });

    test('D17 gulBara has no advancement or prime limits', () {
      final r = Variant.gulBara.rules;
      expect(r.advancement, isNull);
      expectNoPrimes(r);
    });

    test('D10 mahbusa and mahbusaArab rules are equal', () {
      expect(Variant.mahbusaArab.rules, Variant.mahbusa.rules);
    });

    test('D11 every pinning variant forbids bear-off while pinned', () {
      for (final v in Variant.values) {
        if (v.rules.contact == Contact.pin) {
          expect(v.rules.pin!.noBearOffWhilePinned, isTrue, reason: v.name);
        }
      }
    });

    test('D22 match targets 3/5/7 everywhere except tawla31', () {
      for (final v in Variant.values.where((v) => v != Variant.tawla31)) {
        expectMarathonTargets(v.rules);
      }
    });
  });

  group('catalog consistency', () {
    test('§1 layout matches direction and contact', () {
      for (final v in Variant.values) {
        final r = v.rules;
        final expected = switch (r.contact) {
          Contact.hit => (Layout.standard2535, Direction.opposing),
          Contact.pin => (Layout.stackOpposing, Direction.opposing),
          Contact.block => (Layout.stackDiagonal, Direction.same),
        };
        expect((r.layout, r.direction), expected, reason: v.name);
      }
    });

    test('optional blocks are present exactly when their mode needs them', () {
      for (final v in Variant.values) {
        final r = v.rules;
        expect(r.pin != null, r.contact == Contact.pin, reason: v.name);
        expect(r.cascade != null, r.doubles == DoublesMode.cascade);
        expect(r.scoring.triple != null, r.scoring.tripleCondition != null);
        expect(r.hit == null || r.contact == Contact.hit, isTrue);
        expect(r.head == null || r.contact == Contact.block, isTrue);
        expect(r.advancement == null || r.contact == Contact.block, isTrue);
        expect(
          r.cube.crawford || !r.cube.enabledByDefault,
          isTrue,
          reason: '${v.name}: D22 Crawford wherever a cube is in play',
        );
      }
    });

    test('PrimeRules.none and CubeRules.none are all-off', () {
      const p = PrimeRules.none;
      expect(p.noSixOwnStartQuarter, isFalse);
      expect(p.noSixBeforeOccupiedOppHead, isFalse);
      expect(p.maxPointsInOppStartQuarter, isNull);
      expect(p.noPrimeTrappingAll, isFalse);
      expect(p.mustLeaveOpponentAMove, isFalse);
      expect(CubeRules.none.available, isFalse);
      expect(CubeRules.none.enabledByDefault, isFalse);
      expect(CubeRules.none.crawford, isFalse);
    });
  });
}
