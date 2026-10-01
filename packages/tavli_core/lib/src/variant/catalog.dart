/// The const catalog: the only place per-variant behaviour is decided.
///
/// Values follow design spec §3.3 and the approved matrix §6 (R options).
library;

import 'variant.dart';
import 'variant_rules.dart';

const _marathon = MatchDefaults(targets: [3, 5, 7]);
const _single = Scoring(model: ScoringModel.multiplier);

// Plakoto-style pinning: mother 2 (D8), no bear-off while pinned (D11).
const _plakotoPin = PinRules(
  motherRule: true,
  motherPoints: 2,
  bothPinnedPoints: 0,
  noBearOffWhilePinned: true,
);

// D10 A+B: one rule set shared by both Mahbusa entries.
const _mahbusa = VariantRules(
  layout: Layout.stackOpposing,
  direction: Direction.opposing,
  contact: Contact.pin,
  opening: OpeningProcedure.playOpeningDice,
  nextGame: NextGameStarter.openingRoll,
  pin: _plakotoPin,
  scoring: _single,
  match: _marathon,
);

const Map<Variant, VariantRules> variantCatalog = {
  Variant.portes: VariantRules(
    layout: Layout.standard2535,
    direction: Direction.opposing,
    contact: Contact.hit,
    opening: OpeningProcedure.playOpeningDice, // D1-A
    nextGame: NextGameStarter.previousWinner, // D2-A
    scoring: _single, // D6: triple counts as 2
    match: _marathon,
  ),
  Variant.plakoto: VariantRules(
    layout: Layout.stackOpposing,
    direction: Direction.opposing,
    contact: Contact.pin,
    opening: OpeningProcedure.playOpeningDice,
    nextGame: NextGameStarter.previousWinner,
    pin: _plakotoPin,
    scoring: _single,
    match: _marathon,
  ),
  Variant.fevga: VariantRules(
    layout: Layout.stackDiagonal,
    direction: Direction.same,
    contact: Contact.block,
    opening: OpeningProcedure.playOpeningDice,
    nextGame: NextGameStarter.previousWinner,
    advancement: Advancement(11),
    primes: PrimeRules(
      noSixOwnStartQuarter: true, // D12-A(a)
      noSixBeforeOccupiedOppHead: true, // D12-A(b)
      mustLeaveOpponentAMove: true, // D13-A
    ),
    scoring: _single,
    match: _marathon,
  ),
  Variant.tavla: VariantRules(
    layout: Layout.standard2535,
    direction: Direction.opposing,
    contact: Contact.hit,
    opening: OpeningProcedure.winnerRerolls, // D1-B
    nextGame: NextGameStarter.openingRoll,
    hit: HitRules(noHitAndRunInHome: true, bearOffNoWaste: true), // D4, D5
    scoring: _single,
    match: _marathon,
  ),
  Variant.tapa: VariantRules(
    layout: Layout.stackOpposing,
    direction: Direction.opposing,
    contact: Contact.pin,
    opening: OpeningProcedure.winnerRerolls,
    nextGame: NextGameStarter.openingRoll,
    pin: PinRules(
      motherRule: true,
      motherPoints: 2,
      bothPinnedPoints: 1, // D9-A
      noBearOffWhilePinned: true,
    ),
    scoring: _single,
    match: _marathon,
  ),
  Variant.moultezim: VariantRules(
    layout: Layout.stackDiagonal,
    direction: Direction.same,
    contact: Contact.block,
    opening: OpeningProcedure.winnerRerolls,
    nextGame: NextGameStarter.openingRoll,
    advancement: Advancement(11),
    primes: PrimeRules(
      noSixOwnStartQuarter: true,
      maxPointsInOppStartQuarter: 4, // D14-B
    ),
    scoring: _single,
    match: _marathon,
  ),
  Variant.gulBara: VariantRules(
    layout: Layout.stackDiagonal,
    direction: Direction.same,
    contact: Contact.block,
    opening: OpeningProcedure.winnerRerolls,
    nextGame: NextGameStarter.openingRoll,
    // D17-A: no advancement, no prime limits.
    doubles: DoublesMode.cascade,
    cascade: Cascade(
      normalRolls: 3, // D15-A
      onFailure: CascadeFailure.opponentPlaysRemainder, // D16-B
    ),
    scoring: _single,
    match: _marathon,
  ),
  Variant.longNard: VariantRules(
    layout: Layout.stackDiagonal,
    direction: Direction.same,
    contact: Contact.block,
    opening: OpeningProcedure.playOpeningDice,
    nextGame: NextGameStarter.openingRoll,
    head: HeadRule(
      maxPerTurn: 1,
      firstTurnDoubles: {3, 4, 6}, // D18-A
      maxOnException: 2,
    ),
    primes: PrimeRules(noPrimeTrappingAll: true), // D19-A
    scoring: _single,
    cube: CubeRules(available: true, enabledByDefault: false, crawford: true),
    match: _marathon,
  ),
  Variant.shortNard: VariantRules(
    layout: Layout.standard2535,
    direction: Direction.opposing,
    contact: Contact.hit,
    opening: OpeningProcedure.playOpeningDice,
    nextGame: NextGameStarter.openingRoll,
    scoring: Scoring(
      model: ScoringModel.multiplier,
      triple: 3, // koks
      tripleCondition: TripleCondition.barOrWinnerHome,
    ),
    cube: CubeRules(available: true, enabledByDefault: true, crawford: true),
    match: _marathon,
  ),
  Variant.sheshBesh: VariantRules(
    layout: Layout.standard2535,
    direction: Direction.opposing,
    contact: Contact.hit,
    opening: OpeningProcedure.playOpeningDice,
    nextGame: NextGameStarter.openingRoll,
    scoring: Scoring(
      model: ScoringModel.multiplier,
      triple: 3, // D6: Turkish mars
      tripleCondition: TripleCondition.winnerHome,
    ),
    cube: CubeRules(available: true, enabledByDefault: false, crawford: true),
    match: _marathon,
  ),
  Variant.mahbusa: _mahbusa,
  Variant.mahbusaArab: _mahbusa,
  Variant.tawla31: VariantRules(
    layout: Layout.stackDiagonal,
    direction: Direction.same,
    contact: Contact.block,
    opening: OpeningProcedure.playOpeningDice,
    nextGame: NextGameStarter.openingRoll,
    advancement: Advancement(18), // D21(b)
    scoring: Scoring(model: ScoringModel.checkersRemaining), // D21(d)
    match: MatchDefaults(fixedTarget: 31, targets: [31]),
  ),
};
