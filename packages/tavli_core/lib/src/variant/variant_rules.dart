/// Per-variant rules as data (matrix §7). The engine branches on these
/// fields, never on variant names.
library;

/// Starting layout (matrix §1).
enum Layout { standard2535, stackOpposing, stackDiagonal }

/// Whether the two sides move in opposite or the same physical direction.
enum Direction { opposing, same }

/// What a single checker does to an opposing point it lands on.
///
/// `block` means a single checker already controls the point.
enum Contact { hit, pin, block }

/// D1: the opening-roll winner plays both dice, or re-rolls.
enum OpeningProcedure { playOpeningDice, winnerRerolls }

/// D2: who starts the next game of a match.
enum NextGameStarter { openingRoll, previousWinner }

/// G3 (four moves per double) or the Gul Bara cascade (D15).
enum DoublesMode { four, cascade }

/// D16: what happens when a cascade number cannot be fully played.
enum CascadeFailure { forfeit, opponentPlaysRemainder }

/// How a won game is scored.
enum ScoringModel { multiplier, checkersRemaining }

/// When a gammon is upgraded to a triple (D6).
enum TripleCondition { barOrWinnerHome, winnerHome }

/// Long Nard head rule (D18): how many checkers may leave pip 24 per turn.
class HeadRule {
  final int maxPerTurn;

  /// Double values that, on a side's first turn, allow [maxOnException].
  final Set<int> firstTurnDoubles;
  final int maxOnException;

  const HeadRule({
    required this.maxPerTurn,
    required this.firstTurnDoubles,
    required this.maxOnException,
  });
}

/// Sole-runner rule (Fevga, Moultezim, Tawla 31).
class Advancement {
  /// The runner must reach pip <= releasePip before other checkers may leave pip 24.
  final int releasePip;
  const Advancement(this.releasePip);
}

/// Prime restrictions (D12, D13, D14, D19).
class PrimeRules {
  /// All of own pips 19..24 held is forbidden (D12-A(a), D14).
  final bool noSixOwnStartQuarter;

  /// All of own pips 6..11 held while the opponent's head (my 12) is
  /// occupied is forbidden (D12-A(b)).
  final bool noSixBeforeOccupiedOppHead;

  /// At most this many own points on pips 7..12 (D14).
  final int? maxPointsInOppStartQuarter;

  /// Long Nard D19: no six-block with every opposing checker behind it,
  /// checked every step.
  final bool noPrimeTrappingAll;

  /// Fevga D13: a play must leave the opponent a legal move.
  final bool mustLeaveOpponentAMove;

  const PrimeRules({
    this.noSixOwnStartQuarter = false,
    this.noSixBeforeOccupiedOppHead = false,
    this.maxPointsInOppStartQuarter,
    this.noPrimeTrappingAll = false,
    this.mustLeaveOpponentAMove = false,
  });

  static const none = PrimeRules();
}

/// Pinning-game rules (D8, D9, D10, D11).
class PinRules {
  final bool motherRule;
  final int motherPoints; // 2

  /// 0 (Plakoto/Mahbusa) or 1 (Tapa), awarded to EACH side.
  final int bothPinnedPoints;

  /// D11: no bear-off while any own checker is pinned.
  final bool noBearOffWhilePinned;

  const PinRules({
    required this.motherRule,
    required this.motherPoints,
    required this.bothPinnedPoints,
    required this.noBearOffWhilePinned,
  });
}

/// Tavla hitting-game deviations (D4, D5).
class HitRules {
  final bool noHitAndRunInHome; // D4
  final bool bearOffNoWaste; // D5

  const HitRules({
    this.noHitAndRunInHome = false,
    this.bearOffNoWaste = false,
  });
}

/// Gul Bara cascading doubles (D15, D16).
class Cascade {
  /// Rolls of the game played normally before doubles cascade (D15-A).
  final int normalRolls;
  final CascadeFailure onFailure;

  const Cascade({required this.normalRolls, required this.onFailure});
}

/// Scoring: single 1, gammon 2, optional triple (D6, D21).
class Scoring {
  final ScoringModel model;

  /// Points for a triple; null means a triple scores as a gammon.
  final int? triple;
  final TripleCondition? tripleCondition;

  const Scoring({required this.model, this.triple, this.tripleCondition})
      : assert(
          (triple == null) == (tripleCondition == null),
          'triple and tripleCondition go together',
        );
}

/// Doubling cube policy (D7).
class CubeRules {
  final bool available;
  final bool enabledByDefault;
  final bool crawford;

  const CubeRules({
    required this.available,
    required this.enabledByDefault,
    required this.crawford,
  });

  static const none = CubeRules(
    available: false,
    enabledByDefault: false,
    crawford: false,
  );
}

/// Default match formats (D22).
class MatchDefaults {
  /// A target the variant always plays to (Tawla 31), or null.
  final int? fixedTarget;

  /// Match lengths offered to the player.
  final List<int> targets;

  const MatchDefaults({this.fixedTarget, required this.targets});
}

/// The complete rule set of one variant.
class VariantRules {
  final Layout layout;
  final Direction direction;
  final Contact contact;
  final OpeningProcedure opening;
  final NextGameStarter nextGame;
  final HeadRule? head;
  final Advancement? advancement;
  final PrimeRules primes;
  final PinRules? pin;
  final HitRules? hit;
  final DoublesMode doubles;
  final Cascade? cascade;
  final Scoring scoring;
  final CubeRules cube;
  final MatchDefaults match;

  const VariantRules({
    required this.layout,
    required this.direction,
    required this.contact,
    required this.opening,
    required this.nextGame,
    this.head,
    this.advancement,
    this.primes = PrimeRules.none,
    this.pin,
    this.hit,
    this.doubles = DoublesMode.four,
    this.cascade,
    required this.scoring,
    this.cube = CubeRules.none,
    required this.match,
  })  : assert(
          (doubles == DoublesMode.cascade) == (cascade != null),
          'cascade is set exactly when doubles cascade',
        ),
        assert(
          (contact == Contact.pin) == (pin != null),
          'pin rules are set exactly for pinning games',
        ),
        assert(hit == null || contact == Contact.hit, 'hit rules need hit');
}
