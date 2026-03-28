import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';
import '../../features/game/domain/engine/variants/game_variant.dart';

/// In-game contextual hints for variant-specific rules.
///
/// Shows a dismissible toast the first time a variant-specific
/// situation occurs during gameplay.
class VariantHintOverlay {
  VariantHintOverlay._();

  static final _shownHints = <String>{};
  static bool _hintsDisabled = false;

  /// Initialize from preferences (call once at app start).
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _hintsDisabled = prefs.getBool('variant_hints_disabled') ?? false;
    final shown = prefs.getStringList('variant_hints_shown') ?? [];
    _shownHints.addAll(shown);
  }

  /// Disable all hints.
  static Future<void> disable() async {
    _hintsDisabled = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('variant_hints_disabled', true);
  }

  /// Enable all hints.
  static Future<void> enable() async {
    _hintsDisabled = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('variant_hints_disabled', false);
  }

  /// Show a contextual hint if it hasn't been shown before.
  static void showHint(BuildContext context, VariantHint hint) {
    if (_hintsDisabled) return;
    final key = hint.id;
    if (_shownHints.contains(key)) return;

    _shownHints.add(key);
    SharedPreferences.getInstance().then((prefs) {
      prefs.setStringList('variant_hints_shown', _shownHints.toList());
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(hint.icon, color: TavliColors.light, size: 20),
            const SizedBox(width: TavliSpacing.sm),
            Expanded(
              child: Text(
                hint.message,
                style: const TextStyle(color: TavliColors.light, fontSize: 13),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        backgroundColor: TavliColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TavliRadius.md),
        ),
        margin: const EdgeInsets.only(
          bottom: 80,
          left: TavliSpacing.md,
          right: TavliSpacing.md,
        ),
      ),
    );
  }
}

/// Predefined variant-specific hints.
class VariantHint {
  final String id;
  final String message;
  final IconData icon;

  const VariantHint({
    required this.id,
    required this.message,
    required this.icon,
  });

  // ── Plakoto / Pinning hints ──────────────────────────────
  static const pinningExplain = VariantHint(
    id: 'pinning_explain',
    message: 'You pinned an opponent checker! It can\'t move until you leave.',
    icon: Icons.push_pin,
  );

  static const pinnedExplain = VariantHint(
    id: 'pinned_explain',
    message: 'Your checker is pinned — it can\'t move until the opponent leaves.',
    icon: Icons.lock,
  );

  static const motherDanger = VariantHint(
    id: 'mother_danger',
    message: 'Watch out! Your last checker on start is the "mother" (\u03bc\u03ac\u03bd\u03b1). If it gets pinned, you lose!',
    icon: Icons.warning_amber,
  );

  // ── Fevga / Running hints ────────────────────────────────
  static const singleBlocks = VariantHint(
    id: 'single_blocks',
    message: 'In this variant, one checker blocks the point — you can\'t land here.',
    icon: Icons.block,
  );

  static const primeRestriction = VariantHint(
    id: 'prime_restriction',
    message: 'You can\'t build 6 consecutive blocked points when the opponent is trapped behind.',
    icon: Icons.fence,
  );

  static const advancementRule = VariantHint(
    id: 'advancement_rule',
    message: 'You must advance your first checker past the opponent\'s start before moving others.',
    icon: Icons.arrow_forward,
  );

  // ── Long Nard hints ──────────────────────────────────────
  static const headRule = VariantHint(
    id: 'head_rule',
    message: 'Head rule: only one checker can leave the starting point per turn.',
    icon: Icons.looks_one,
  );

  static const headRuleException = VariantHint(
    id: 'head_rule_exception',
    message: 'Exception! On the first turn with this double, you can move two off the head.',
    icon: Icons.looks_two,
  );

  // ── Short Nard / Doubling hints ──────────────────────────
  static const doublingCubeIntro = VariantHint(
    id: 'doubling_intro',
    message: 'This variant uses the doubling cube. Before rolling, you can offer to double the stakes!',
    icon: Icons.casino,
  );

  // ── Hit-and-run hints ────────────────────────────────────
  static const hitAndRunAllowed = VariantHint(
    id: 'hit_and_run_allowed',
    message: 'In Shesh Besh, you can hit an opponent and keep moving past — hit-and-run!',
    icon: Icons.speed,
  );

  static const hitAndRunBlocked = VariantHint(
    id: 'hit_and_run_blocked',
    message: 'No hit-and-run in this variant — you can\'t hit and continue on the same die.',
    icon: Icons.do_not_disturb,
  );

  /// Get relevant hint for a variant on first play.
  static VariantHint? firstPlayHint(GameVariant variant) => switch (variant) {
        GameVariant.plakoto || GameVariant.tapa || GameVariant.mahbusa =>
          pinningExplain,
        GameVariant.fevga || GameVariant.moultezim => singleBlocks,
        GameVariant.longNard => headRule,
        GameVariant.shortNard => doublingCubeIntro,
        GameVariant.sheshBesh => hitAndRunAllowed,
        _ => null,
      };
}
