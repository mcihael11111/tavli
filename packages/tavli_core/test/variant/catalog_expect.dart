/// Shared expectations for the catalog tests.
library;

import 'package:tavli_core/tavli_core.dart';
import 'package:test/test.dart';

const marathon = [3, 5, 7];

/// Asserts the fields every row of the catalog table shares in shape.
void expectBasics(
  VariantRules r, {
  required Layout layout,
  required Direction direction,
  required Contact contact,
  required OpeningProcedure opening,
  required NextGameStarter nextGame,
}) {
  expect(r.layout, layout, reason: 'layout');
  expect(r.direction, direction, reason: 'direction');
  expect(r.contact, contact, reason: 'contact');
  expect(r.opening, opening, reason: 'opening');
  expect(r.nextGame, nextGame, reason: 'nextGame');
}

void expectNoPrimes(VariantRules r) {
  expect(r.primes.noSixOwnStartQuarter, isFalse);
  expect(r.primes.noSixBeforeOccupiedOppHead, isFalse);
  expect(r.primes.maxPointsInOppStartQuarter, isNull);
  expect(r.primes.noPrimeTrappingAll, isFalse);
  expect(r.primes.mustLeaveOpponentAMove, isFalse);
}

void expectNoCube(VariantRules r) {
  expect(r.cube.available, isFalse);
  expect(r.cube.enabledByDefault, isFalse);
  expect(r.cube.crawford, isFalse);
}

void expectFourDoubles(VariantRules r) {
  expect(r.doubles, DoublesMode.four);
  expect(r.cascade, isNull);
}

void expectMultiplierNoTriple(VariantRules r) {
  expect(r.scoring.model, ScoringModel.multiplier);
  expect(r.scoring.triple, isNull);
  expect(r.scoring.tripleCondition, isNull);
}

void expectMarathonTargets(VariantRules r) {
  expect(r.match.fixedTarget, isNull);
  expect(r.match.targets, marathon);
}

void expectPlakotoPin(VariantRules r, {required int bothPinned}) {
  final pin = r.pin!;
  expect(pin.motherRule, isTrue);
  expect(pin.motherPoints, 2);
  expect(pin.bothPinnedPoints, bothPinned);
  expect(pin.noBearOffWhilePinned, isTrue);
}
