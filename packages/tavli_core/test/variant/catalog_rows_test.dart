import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

import 'catalog_expect.dart';

void main() {
  group('rows', () {
    test(
        'D1 D2 D3 D6 portes: hitting, plays opening dice, previous winner '
        'starts, no hit-and-run ban, no triple', () {
      final r = Variant.portes.rules;
      expectBasics(
        r,
        layout: Layout.standard2535,
        direction: Direction.opposing,
        contact: Contact.hit,
        opening: OpeningProcedure.playOpeningDice,
        nextGame: NextGameStarter.previousWinner,
      );
      expect(r.head, isNull);
      expect(r.advancement, isNull);
      expectNoPrimes(r);
      expect(r.pin, isNull);
      expect(r.hit, isNull);
      expectFourDoubles(r);
      expectMultiplierNoTriple(r);
      expectNoCube(r);
      expectMarathonTargets(r);
    });

    test(
        'D1 D2 D8 D11 plakoto: pinning, mother 2, both-pinned draw 0, '
        'no bear-off while pinned', () {
      final r = Variant.plakoto.rules;
      expectBasics(
        r,
        layout: Layout.stackOpposing,
        direction: Direction.opposing,
        contact: Contact.pin,
        opening: OpeningProcedure.playOpeningDice,
        nextGame: NextGameStarter.previousWinner,
      );
      expect(r.head, isNull);
      expect(r.advancement, isNull);
      expectNoPrimes(r);
      expectPlakotoPin(r, bothPinned: 0);
      expect(r.hit, isNull);
      expectFourDoubles(r);
      expectMultiplierNoTriple(r);
      expectNoCube(r);
      expectMarathonTargets(r);
    });

    test(
        'D1 D2 D12 D13 fevga: running, runner past pip 11, EOPT primes, '
        'leave a move', () {
      final r = Variant.fevga.rules;
      expectBasics(
        r,
        layout: Layout.stackDiagonal,
        direction: Direction.same,
        contact: Contact.block,
        opening: OpeningProcedure.playOpeningDice,
        nextGame: NextGameStarter.previousWinner,
      );
      expect(r.head, isNull);
      expect(r.advancement!.releasePip, 11);
      expect(r.primes.noSixOwnStartQuarter, isTrue);
      expect(r.primes.noSixBeforeOccupiedOppHead, isTrue);
      expect(r.primes.maxPointsInOppStartQuarter, isNull);
      expect(r.primes.noPrimeTrappingAll, isFalse);
      expect(r.primes.mustLeaveOpponentAMove, isTrue);
      expect(r.pin, isNull);
      expect(r.hit, isNull);
      expectFourDoubles(r);
      expectMultiplierNoTriple(r);
      expectNoCube(r);
      expectMarathonTargets(r);
    });

    test(
        'D1 D4 D5 tavla: hitting, winner rerolls, no hit-and-run in home, '
        'no-waste bear-off', () {
      final r = Variant.tavla.rules;
      expectBasics(
        r,
        layout: Layout.standard2535,
        direction: Direction.opposing,
        contact: Contact.hit,
        opening: OpeningProcedure.winnerRerolls,
        nextGame: NextGameStarter.openingRoll,
      );
      expect(r.head, isNull);
      expect(r.advancement, isNull);
      expectNoPrimes(r);
      expect(r.pin, isNull);
      expect(r.hit!.noHitAndRunInHome, isTrue);
      expect(r.hit!.bearOffNoWaste, isTrue);
      expectFourDoubles(r);
      expectMultiplierNoTriple(r);
      expectNoCube(r);
      expectMarathonTargets(r);
    });

    test(
        'D1 D9 D11 tapa: pinning, winner rerolls, mother 2, both-pinned '
        '1 each', () {
      final r = Variant.tapa.rules;
      expectBasics(
        r,
        layout: Layout.stackOpposing,
        direction: Direction.opposing,
        contact: Contact.pin,
        opening: OpeningProcedure.winnerRerolls,
        nextGame: NextGameStarter.openingRoll,
      );
      expect(r.head, isNull);
      expect(r.advancement, isNull);
      expectNoPrimes(r);
      expectPlakotoPin(r, bothPinned: 1);
      expect(r.hit, isNull);
      expectFourDoubles(r);
      expectMultiplierNoTriple(r);
      expectNoCube(r);
      expectMarathonTargets(r);
    });

    test(
        'D1 D14 moultezim: running, winner rerolls, runner past pip 11, '
        'own start quarter and max 4 in opp start quarter', () {
      final r = Variant.moultezim.rules;
      expectBasics(
        r,
        layout: Layout.stackDiagonal,
        direction: Direction.same,
        contact: Contact.block,
        opening: OpeningProcedure.winnerRerolls,
        nextGame: NextGameStarter.openingRoll,
      );
      expect(r.head, isNull);
      expect(r.advancement!.releasePip, 11);
      expect(r.primes.noSixOwnStartQuarter, isTrue);
      expect(r.primes.noSixBeforeOccupiedOppHead, isFalse);
      expect(r.primes.maxPointsInOppStartQuarter, 4);
      expect(r.primes.noPrimeTrappingAll, isFalse);
      expect(r.primes.mustLeaveOpponentAMove, isFalse);
      expect(r.pin, isNull);
      expect(r.hit, isNull);
      expectFourDoubles(r);
      expectMultiplierNoTriple(r);
      expectNoCube(r);
      expectMarathonTargets(r);
    });

    test(
        'D1 D15 D16 D17 gulBara: running, winner rerolls, cascade after 3 '
        'rolls, opponent plays remainder', () {
      final r = Variant.gulBara.rules;
      expectBasics(
        r,
        layout: Layout.stackDiagonal,
        direction: Direction.same,
        contact: Contact.block,
        opening: OpeningProcedure.winnerRerolls,
        nextGame: NextGameStarter.openingRoll,
      );
      expect(r.head, isNull);
      expect(r.advancement, isNull);
      expectNoPrimes(r);
      expect(r.pin, isNull);
      expect(r.hit, isNull);
      expect(r.doubles, DoublesMode.cascade);
      expect(r.cascade!.normalRolls, 3);
      expect(r.cascade!.onFailure, CascadeFailure.opponentPlaysRemainder);
      expectMultiplierNoTriple(r);
      expectNoCube(r);
      expectMarathonTargets(r);
    });

    test(
        'D1 D7 D18 D19 longNard: running, head 1 per turn, first-turn '
        '{3,4,6} exception 2, trap check, cube available off', () {
      final r = Variant.longNard.rules;
      expectBasics(
        r,
        layout: Layout.stackDiagonal,
        direction: Direction.same,
        contact: Contact.block,
        opening: OpeningProcedure.playOpeningDice,
        nextGame: NextGameStarter.openingRoll,
      );
      expect(r.head!.maxPerTurn, 1);
      expect(r.head!.firstTurnDoubles, {3, 4, 6});
      expect(r.head!.maxOnException, 2);
      expect(r.advancement, isNull);
      expect(r.primes.noSixOwnStartQuarter, isFalse);
      expect(r.primes.noSixBeforeOccupiedOppHead, isFalse);
      expect(r.primes.maxPointsInOppStartQuarter, isNull);
      expect(r.primes.noPrimeTrappingAll, isTrue);
      expect(r.primes.mustLeaveOpponentAMove, isFalse);
      expect(r.pin, isNull);
      expect(r.hit, isNull);
      expectFourDoubles(r);
      expectMultiplierNoTriple(r);
      expect(r.cube.available, isTrue);
      expect(r.cube.enabledByDefault, isFalse);
      expect(r.cube.crawford, isTrue);
      expectMarathonTargets(r);
    });

    test(
        'D1 D6 D7 shortNard: hitting, koks 3 (bar or winner home), cube on '
        'with crawford', () {
      final r = Variant.shortNard.rules;
      expectBasics(
        r,
        layout: Layout.standard2535,
        direction: Direction.opposing,
        contact: Contact.hit,
        opening: OpeningProcedure.playOpeningDice,
        nextGame: NextGameStarter.openingRoll,
      );
      expect(r.head, isNull);
      expect(r.advancement, isNull);
      expectNoPrimes(r);
      expect(r.pin, isNull);
      expect(r.hit, isNull);
      expectFourDoubles(r);
      expect(r.scoring.model, ScoringModel.multiplier);
      expect(r.scoring.triple, 3);
      expect(r.scoring.tripleCondition, TripleCondition.barOrWinnerHome);
      expect(r.cube.available, isTrue);
      expect(r.cube.enabledByDefault, isTrue);
      expect(r.cube.crawford, isTrue);
      expectMarathonTargets(r);
    });

    test(
        'D1 D6 D7 sheshBesh: hitting, Turkish mars 3 (winner home), cube '
        'available off', () {
      final r = Variant.sheshBesh.rules;
      expectBasics(
        r,
        layout: Layout.standard2535,
        direction: Direction.opposing,
        contact: Contact.hit,
        opening: OpeningProcedure.playOpeningDice,
        nextGame: NextGameStarter.openingRoll,
      );
      expect(r.head, isNull);
      expect(r.advancement, isNull);
      expectNoPrimes(r);
      expect(r.pin, isNull);
      expect(r.hit, isNull);
      expectFourDoubles(r);
      expect(r.scoring.model, ScoringModel.multiplier);
      expect(r.scoring.triple, 3);
      expect(r.scoring.tripleCondition, TripleCondition.winnerHome);
      expect(r.cube.available, isTrue);
      expect(r.cube.enabledByDefault, isFalse);
      expect(r.cube.crawford, isTrue);
      expectMarathonTargets(r);
    });

    for (final v in [Variant.mahbusa, Variant.mahbusaArab]) {
      test('D1 D10 D11 ${v.name}: pinning as plakoto, opening roll each game',
          () {
        final r = v.rules;
        expectBasics(
          r,
          layout: Layout.stackOpposing,
          direction: Direction.opposing,
          contact: Contact.pin,
          opening: OpeningProcedure.playOpeningDice,
          nextGame: NextGameStarter.openingRoll,
        );
        expect(r.head, isNull);
        expect(r.advancement, isNull);
        expectNoPrimes(r);
        expectPlakotoPin(r, bothPinned: 0);
        expect(r.hit, isNull);
        expectFourDoubles(r);
        expectMultiplierNoTriple(r);
        expectNoCube(r);
        expectMarathonTargets(r);
      });
    }

    test(
        'D20 D21 tawla31: running, runner to pip 18, no prime limits, '
        'checkersRemaining, fixed target 31', () {
      final r = Variant.tawla31.rules;
      expectBasics(
        r,
        layout: Layout.stackDiagonal,
        direction: Direction.same,
        contact: Contact.block,
        opening: OpeningProcedure.playOpeningDice,
        nextGame: NextGameStarter.openingRoll,
      );
      expect(r.head, isNull);
      expect(r.advancement!.releasePip, 18);
      expectNoPrimes(r);
      expect(r.pin, isNull);
      expect(r.hit, isNull);
      expectFourDoubles(r);
      expect(r.scoring.model, ScoringModel.checkersRemaining);
      expect(r.scoring.triple, isNull);
      expectNoCube(r);
      expect(r.match.fixedTarget, 31);
    });
  });
}
