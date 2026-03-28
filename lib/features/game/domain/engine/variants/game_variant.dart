import '../../../../../core/constants/tradition.dart';
import '../../../../../core/constants/variants/variant_rules.dart';

/// All game variants across all traditions.
enum GameVariant {
  // ── Tavli (Greece) ────────────────────────────────────────
  /// Πόρτες — standard backgammon (hitting).
  portes,

  /// Πλακωτό — pinning variant.
  plakoto,

  /// Φεύγα — running variant.
  fevga,

  // ── Tavla (Turkey) ────────────────────────────────────────
  /// Tavla — Turkish standard backgammon (hitting).
  tavla,

  /// Tapa — Turkish pinning variant.
  tapa,

  /// Moultezim — Turkish running variant.
  moultezim,

  /// Gul Bara — Turkish cascading doubles variant (Crazy Narde).
  gulBara,

  // ── Nardy (Russia / Caucasus / Iran) ──────────────────────
  /// Long Nard — primary Russian running variant with head rule.
  longNard,

  /// Short Nard — standard backgammon (Russian name).
  shortNard,

  // ── Shesh Besh (Israel / Arab World) ──────────────────────
  /// Shesh Besh — standard hitting game.
  sheshBesh,

  /// Mahbusa — Arabic pinning variant.
  mahbusa;

  /// The tradition this variant belongs to.
  Tradition get tradition => switch (this) {
        portes || plakoto || fevga => Tradition.tavli,
        tavla || tapa || moultezim || gulBara => Tradition.tavla,
        longNard || shortNard => Tradition.nardy,
        sheshBesh || mahbusa => Tradition.sheshBesh,
      };

  /// The mechanic family.
  MechanicFamily get mechanicFamily => switch (this) {
        portes || tavla || shortNard || sheshBesh => MechanicFamily.hitting,
        plakoto || tapa || mahbusa => MechanicFamily.pinning,
        fevga || moultezim || longNard || gulBara => MechanicFamily.running,
      };

  /// English display name.
  String get displayName => switch (this) {
        portes => 'Portes',
        plakoto => 'Plakoto',
        fevga => 'Fevga',
        tavla => 'Tavla',
        tapa => 'Tapa',
        moultezim => 'Moultezim',
        gulBara => 'Gul Bara',
        longNard => 'Long Nard',
        shortNard => 'Short Nard',
        sheshBesh => 'Shesh Besh',
        mahbusa => 'Mahbusa',
      };

  /// Name in native script.
  String get nativeName => switch (this) {
        portes => 'Πόρτες',
        plakoto => 'Πλακωτό',
        fevga => 'Φεύγα',
        tavla => 'Tavla',
        tapa => 'Tapa',
        moultezim => 'Moultezim',
        gulBara => 'Gül Bara',
        longNard => 'Длинные нарды',
        shortNard => 'Короткие нарды',
        sheshBesh => 'שש בש',
        mahbusa => 'محبوسة',
      };

  /// Complete rule configuration for this variant.
  VariantRules get rules => switch (this) {
        // ── Hitting games ───────────────────────────────────
        portes => const VariantRules(
          startingPosition: StartingPosition.standard,
          movementDirection: MovementDirection.opposing,
          captureMode: CaptureMode.hitting,
          allowHitAndRun: false, // Greek rule
          winnerRerolls: true,
          p1HomeStart: 0, p1HomeEnd: 5,
          p2HomeStart: 18, p2HomeEnd: 23,
        ),
        tavla => const VariantRules(
          startingPosition: StartingPosition.standard,
          movementDirection: MovementDirection.opposing,
          captureMode: CaptureMode.hitting,
          allowHitAndRun: false, // Turkish rule
          winnerRerolls: true,
          p1HomeStart: 0, p1HomeEnd: 5,
          p2HomeStart: 18, p2HomeEnd: 23,
        ),
        shortNard => const VariantRules(
          startingPosition: StartingPosition.standard,
          movementDirection: MovementDirection.opposing,
          captureMode: CaptureMode.hitting,
          allowHitAndRun: true, // Standard backgammon rules
          hasDoublingCube: true,
          winnerRerolls: false,
          scoringBackgammon: true,
          p1HomeStart: 0, p1HomeEnd: 5,
          p2HomeStart: 18, p2HomeEnd: 23,
        ),
        sheshBesh => const VariantRules(
          startingPosition: StartingPosition.standard,
          movementDirection: MovementDirection.opposing,
          captureMode: CaptureMode.hitting,
          allowHitAndRun: true,
          winnerRerolls: true,
          p1HomeStart: 0, p1HomeEnd: 5,
          p2HomeStart: 18, p2HomeEnd: 23,
        ),

        // ── Pinning games ───────────────────────────────────
        plakoto => const VariantRules(
          startingPosition: StartingPosition.allOnOneOpposing,
          movementDirection: MovementDirection.opposing,
          captureMode: CaptureMode.pinning,
          hasMotherPiece: true,
          winnerRerolls: true,
          p1StartPoint: 0, p2StartPoint: 23,
          // Plakoto: P1 moves 0→23, bears off from 18-23
          p1HomeStart: 18, p1HomeEnd: 23,
          // P2 moves 23→0, bears off from 0-5
          p2HomeStart: 0, p2HomeEnd: 5,
        ),
        tapa => const VariantRules(
          startingPosition: StartingPosition.allOnOneOpposing,
          movementDirection: MovementDirection.opposing,
          captureMode: CaptureMode.pinning,
          hasMotherPiece: false, // Tapa does NOT have mother piece (key difference from Plakoto)
          winnerRerolls: true,
          p1StartPoint: 0, p2StartPoint: 23,
          p1HomeStart: 18, p1HomeEnd: 23,
          p2HomeStart: 0, p2HomeEnd: 5,
        ),
        mahbusa => const VariantRules(
          startingPosition: StartingPosition.allOnOneOpposing,
          movementDirection: MovementDirection.opposing,
          captureMode: CaptureMode.pinning,
          hasMotherPiece: true,
          winnerRerolls: true,
          p1StartPoint: 0, p2StartPoint: 23,
          p1HomeStart: 18, p1HomeEnd: 23,
          p2HomeStart: 0, p2HomeEnd: 5,
        ),

        // ── Running games ───────────────────────────────────
        gulBara => const VariantRules(
          startingPosition: StartingPosition.allOnOneSameDirection,
          movementDirection: MovementDirection.same,
          captureMode: CaptureMode.none,
          singleControlsPoint: true,
          hasAdvancementRule: true,
          hasPrimeRestriction: true,
          maxPrimeWithTrapped: 5,
          winnerRerolls: true,
          p1StartPoint: 0, p2StartPoint: 12,
          p1HomeStart: 18, p1HomeEnd: 23,
          p2HomeStart: 6, p2HomeEnd: 11,
        ),
        fevga => const VariantRules(
          startingPosition: StartingPosition.allOnOneSameDirection,
          movementDirection: MovementDirection.same,
          captureMode: CaptureMode.none,
          singleControlsPoint: true,
          hasAdvancementRule: true,
          hasPrimeRestriction: true,
          maxPrimeWithTrapped: 5,
          winnerRerolls: true,
          p1StartPoint: 0, p2StartPoint: 12,
          p1HomeStart: 18, p1HomeEnd: 23,
          p2HomeStart: 6, p2HomeEnd: 11,
        ),
        moultezim => const VariantRules(
          startingPosition: StartingPosition.allOnOneSameDirection,
          movementDirection: MovementDirection.same,
          captureMode: CaptureMode.none,
          singleControlsPoint: true,
          hasAdvancementRule: true,
          hasPrimeRestriction: true,
          maxPrimeWithTrapped: 5,
          winnerRerolls: true,
          p1StartPoint: 0, p2StartPoint: 12,
          p1HomeStart: 18, p1HomeEnd: 23,
          p2HomeStart: 6, p2HomeEnd: 11,
        ),
        longNard => const VariantRules(
          startingPosition: StartingPosition.allOnOneSameDirection,
          movementDirection: MovementDirection.same,
          captureMode: CaptureMode.none,
          singleControlsPoint: true,
          hasHeadRule: true,
          headRuleDoubleExceptions: [3, 4, 6], // 3-3, 4-4, 6-6 allow 2 off head
          hasPrimeRestriction: true,
          maxPrimeWithTrapped: 5,
          winnerRerolls: false, // Narde tradition does NOT re-roll opening
          p1StartPoint: 0, p2StartPoint: 12,
          p1HomeStart: 18, p1HomeEnd: 23,
          p2HomeStart: 6, p2HomeEnd: 11,
        ),
      };
}
