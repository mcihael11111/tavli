import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/tradition.dart';
import '../../features/game/domain/engine/variants/game_variant.dart';

/// Bottom sheet shown when a player selects a variant for the first time.
/// Explains the key rules in 3-4 bullet points with an option to launch tutorial.
class VariantIntroSheet extends StatelessWidget {
  final GameVariant variant;
  final VoidCallback onPlay;
  final VoidCallback onTutorial;

  const VariantIntroSheet({
    super.key,
    required this.variant,
    required this.onPlay,
    required this.onTutorial,
  });

  /// Show the intro sheet only if the player hasn't seen it before.
  /// Returns true if the sheet was shown, false if already seen.
  static Future<bool> showIfNeeded({
    required BuildContext context,
    required GameVariant variant,
    required VoidCallback onPlay,
    required VoidCallback onTutorial,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'variant_intro_seen_${variant.name}';
    if (prefs.getBool(key) == true) return false;

    if (!context.mounted) return false;

    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VariantIntroSheet(
        variant: variant,
        onPlay: () {
          prefs.setBool(key, true);
          Navigator.pop(context);
          onPlay();
        },
        onTutorial: () {
          prefs.setBool(key, true);
          Navigator.pop(context);
          onTutorial();
        },
      ),
    );
    return true;
  }

  IconData get _mechanicIcon => switch (variant.mechanicFamily) {
        MechanicFamily.hitting => Icons.gavel,
        MechanicFamily.pinning => Icons.push_pin,
        MechanicFamily.running => Icons.directions_run,
      };

  String get _mechanicLabel => switch (variant.mechanicFamily) {
        MechanicFamily.hitting => 'Hitting Game',
        MechanicFamily.pinning => 'Pinning Game',
        MechanicFamily.running => 'Running Game',
      };

  List<String> get _keyRules => switch (variant) {
        GameVariant.portes => [
          'Standard backgammon setup — 2-5-3-5 checker placement',
          'Hit lone opponent checkers to send them to the bar',
          'No hit-and-run allowed in home board',
          'Winner of opening roll re-rolls both dice',
        ],
        GameVariant.plakoto => [
          'All 15 checkers start on a single point',
          'Land on a lone opponent to PIN it (trap in place)',
          'Mother piece (\u03bc\u03ac\u03bd\u03b1): if your last checker on start is pinned, you lose double!',
          'No hitting — only pinning',
        ],
        GameVariant.fevga => [
          'All 15 checkers start on one point, both move same direction',
          'A single checker blocks the entire point — no hitting',
          'Must advance first checker past opponent\'s start before spreading',
          'Cannot build a wall of 6+ consecutive blocked points',
        ],
        GameVariant.tavla => [
          'Standard backgammon setup — same as Portes',
          'Hit lone opponent checkers to send them to the bar',
          'No hit-and-run allowed in home board',
          'Winner of opening roll re-rolls both dice',
        ],
        GameVariant.tapa => [
          'All 15 checkers start on a single point',
          'Land on a lone opponent to PIN it (trap in place)',
          'No mother piece rule — pinning the last checker is not an auto-loss',
          'Strategy favors patient, deliberate play',
        ],
        GameVariant.moultezim => [
          'All 15 checkers start on one point, both move same direction',
          'A single checker blocks the entire point — no hitting',
          'Must advance first checker past opponent\'s start before spreading',
          'Cannot build a wall of 6+ consecutive blocked points',
        ],
        GameVariant.gulBara => [
          'Same movement rules as Fevga/Moultezim — same direction, single blocks',
          'Cascading doubles: after the first 3 rolls, doubles trigger a cascade',
          'E.g., rolling 2-2 = four 2s, then four 3s, four 4s, four 5s, four 6s!',
          'If any part of the cascade can\'t be completed, the turn ends',
        ],
        GameVariant.longNard => [
          'All 15 checkers start on the "head" point',
          'Only ONE checker may leave the head per turn',
          'Exception: first turn with 3-3, 4-4, or 6-6 allows two off the head',
          'No hitting — single checker blocks the point',
        ],
        GameVariant.shortNard => [
          'Standard backgammon setup with doubling cube',
          'Hit lone opponent checkers to send them to the bar',
          'Doubling cube + Jacoby rule + beaver option',
          'Backgammon (3x) scoring available',
        ],
        GameVariant.sheshBesh => [
          'Standard backgammon setup',
          'Hit lone opponent checkers to send them to the bar',
          'Hit-and-run IS allowed — hit and continue past',
          'Winner of opening roll re-rolls both dice',
        ],
        GameVariant.mahbusa => [
          'All 15 checkers start on a single point',
          'Land on a lone opponent to PIN it (trap in place)',
          'Mother piece rule: if your last checker on start is pinned, you lose double!',
          'Similar to Plakoto from the Arabic tradition',
        ],
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TavliColors.background,
        borderRadius: BorderRadius.circular(TavliRadius.xl),
        border: Border.all(color: TavliColors.primary, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TavliSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar.
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: TavliColors.primary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: TavliSpacing.lg),

            // Variant name and mechanic icon.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_mechanicIcon, color: TavliColors.primary, size: 28),
                const SizedBox(width: TavliSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      variant.displayName,
                      style: TextStyle(
                        fontSize: 24,
                        fontFamily: TavliTheme.serifFamily,
                        fontWeight: FontWeight.w600,
                        color: TavliColors.text,
                      ),
                    ),
                    Text(
                      _mechanicLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: TavliColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: TavliSpacing.lg),

            // Section header.
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'How it works:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: TavliColors.text,
                ),
              ),
            ),
            const SizedBox(height: TavliSpacing.sm),

            // Key rules.
            for (final rule in _keyRules)
              Padding(
                padding: const EdgeInsets.only(bottom: TavliSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.circle, size: 6, color: TavliColors.primary),
                    ),
                    const SizedBox(width: TavliSpacing.sm),
                    Expanded(
                      child: Text(
                        rule,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: TavliColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: TavliSpacing.lg),

            // Buttons.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPlay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TavliColors.primary,
                  foregroundColor: TavliColors.light,
                  padding: const EdgeInsets.symmetric(vertical: TavliSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TavliRadius.lg),
                  ),
                ),
                child: const Text(
                  'Got it, let\'s play!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: TavliSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onTutorial,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: TavliSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TavliRadius.lg),
                  ),
                ),
                child: const Text(
                  'Show me a tutorial first',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
