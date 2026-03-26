/// Rule configuration for a specific game variant.
///
/// Every variant is fully described by this config object. The engine reads
/// the config rather than branching on variant name.
class VariantRules {
  /// How checkers are placed at game start.
  final StartingPosition startingPosition;

  /// Whether players move in the same or opposing directions.
  final MovementDirection movementDirection;

  /// How checkers interact when landing on opponent's point.
  final CaptureMode captureMode;

  /// Whether a single checker controls (blocks) a point (running games).
  final bool singleControlsPoint;

  /// Whether hit-and-run is allowed in home board (hitting games only).
  final bool allowHitAndRun;

  /// Whether the doubling cube is used.
  final bool hasDoublingCube;

  /// Whether the winner of the opening roll re-rolls for their first turn.
  final bool winnerRerolls;

  /// Head rule: only one checker may leave the starting point per turn.
  final bool hasHeadRule;

  /// Die values that allow 2 checkers to leave head on first turn (e.g., 3,4,6 for long nard).
  final List<int> headRuleDoubleExceptions;

  /// Whether the last checker on starting point triggers special loss if pinned.
  final bool hasMotherPiece;

  /// Whether building a full prime (6 consecutive) is restricted when opponent is trapped.
  final bool hasPrimeRestriction;

  /// Maximum consecutive blocked points allowed when opponent is fully behind.
  final int maxPrimeWithTrapped;

  /// Advancement rule: must get a checker past opponent's start before moving others.
  final bool hasAdvancementRule;

  /// Whether backgammon (3x) scoring exists.
  final bool scoringBackgammon;

  /// Starting point index for player 1.
  final int p1StartPoint;

  /// Starting point index for player 2.
  final int p2StartPoint;

  /// Player 1 home board start index.
  final int p1HomeStart;

  /// Player 1 home board end index.
  final int p1HomeEnd;

  /// Player 2 home board start index.
  final int p2HomeStart;

  /// Player 2 home board end index.
  final int p2HomeEnd;

  const VariantRules({
    required this.startingPosition,
    required this.movementDirection,
    required this.captureMode,
    this.singleControlsPoint = false,
    this.allowHitAndRun = true,
    this.hasDoublingCube = false,
    this.winnerRerolls = true,
    this.hasHeadRule = false,
    this.headRuleDoubleExceptions = const [],
    this.hasMotherPiece = false,
    this.hasPrimeRestriction = false,
    this.maxPrimeWithTrapped = 6,
    this.hasAdvancementRule = false,
    this.scoringBackgammon = false,
    this.p1StartPoint = 0,
    this.p2StartPoint = 23,
    this.p1HomeStart = 0,
    this.p1HomeEnd = 5,
    this.p2HomeStart = 18,
    this.p2HomeEnd = 23,
  });
}

/// How checkers are placed at game start.
enum StartingPosition {
  /// Standard 2-5-3-5 distribution (backgammon/Portes/Tavla/Shesh Besh).
  standard,

  /// All 15 on one point, players on opposite corners, opposing direction
  /// (Plakoto/Tapa/Mahbusa).
  allOnOneOpposing,

  /// All 15 on one point, same-direction movement (Fevga/Nard/Moultezim).
  allOnOneSameDirection,
}

/// Movement direction.
enum MovementDirection {
  /// Players move in opposite directions (standard backgammon).
  opposing,

  /// Both players move in the same direction (Fevga, Nard).
  same,
}

/// How checkers interact when landing on an opponent's point.
enum CaptureMode {
  /// Landing on a single opponent checker sends it to the bar.
  hitting,

  /// Landing on a single opponent checker pins it in place.
  pinning,

  /// No interaction — a single opponent checker blocks the point entirely.
  none,
}
