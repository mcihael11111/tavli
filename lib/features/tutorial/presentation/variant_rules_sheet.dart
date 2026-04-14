import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../game/domain/engine/variants/game_variant.dart';

/// In-game rule reference sheet — accessible from the pause menu during gameplay.
/// Shows a quick-reference of the current variant's rules.
class VariantRulesSheet extends StatelessWidget {
  final GameVariant variant;

  const VariantRulesSheet({super.key, required this.variant});

  static void show(BuildContext context, GameVariant variant) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VariantRulesSheet(variant: variant),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = _VariantInfo.forVariant(variant);

    return Container(
      margin: const EdgeInsets.all(TavliSpacing.sm),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: TavliColors.background,
        borderRadius: BorderRadius.circular(TavliRadius.xl),
        border: Border.all(color: TavliColors.primary, width: 1.5),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TavliSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle.
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: TavliColors.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: TavliSpacing.lg),

            // Header.
            Row(
              children: [
                Icon(info.icon, color: TavliColors.primary, size: 28),
                const SizedBox(width: TavliSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${variant.displayName} (${variant.nativeName})',
                      style: theme.textTheme.headlineMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: TavliColors.text,
                      ),
                    ),
                    Text(
                      '${variant.tradition.displayName} \u2022 ${variant.mechanicFamily.displayName}',
                      style: theme.textTheme.bodySmall!.copyWith(
                        fontSize: 13,
                        color: TavliColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: TavliSpacing.lg),

            // Setup section.
            _sectionHeader(theme, 'Setup'),
            _bulletPoint(theme, info.startingPosition),
            _bulletPoint(theme, info.movementDirection),

            const SizedBox(height: TavliSpacing.md),

            // Core mechanic section.
            _sectionHeader(theme, 'Core Mechanic'),
            for (final rule in info.coreMechanic) _bulletPoint(theme, rule),

            const SizedBox(height: TavliSpacing.md),

            // Special rules section.
            if (info.specialRules.isNotEmpty) ...[
              _sectionHeader(theme, 'Special Rules'),
              for (final rule in info.specialRules) _bulletPoint(theme, rule),
              const SizedBox(height: TavliSpacing.md),
            ],

            // Scoring section.
            _sectionHeader(theme, 'Scoring'),
            for (final rule in info.scoring) _bulletPoint(theme, rule),

            const SizedBox(height: TavliSpacing.lg),

            // Close button.
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TavliSpacing.xs),
      child: Text(
        title,
        style: theme.textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.w600,
          color: TavliColors.text,
        ),
      ),
    );
  }

  Widget _bulletPoint(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TavliSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 7),
            child: Icon(Icons.circle, size: 5, color: TavliColors.primary),
          ),
          const SizedBox(width: TavliSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium!.copyWith(height: 1.4, color: TavliColors.text),
            ),
          ),
        ],
      ),
    );
  }
}

/// Structured rule info for each variant.
class _VariantInfo {
  final IconData icon;
  final String startingPosition;
  final String movementDirection;
  final List<String> coreMechanic;
  final List<String> specialRules;
  final List<String> scoring;

  const _VariantInfo({
    required this.icon,
    required this.startingPosition,
    required this.movementDirection,
    required this.coreMechanic,
    required this.specialRules,
    required this.scoring,
  });

  factory _VariantInfo.forVariant(GameVariant variant) => switch (variant) {
        GameVariant.portes => const _VariantInfo(
          icon: Icons.gavel,
          startingPosition: 'Standard backgammon: 2 on 24-pt, 5 on 13-pt, 3 on 8-pt, 5 on 6-pt',
          movementDirection: 'Players move in opposite directions toward their home board',
          coreMechanic: [
            'Hit lone opponent checkers to send them to the bar',
            'Hit checkers must re-enter through opponent\'s home board before other moves',
            'No hit-and-run: cannot hit and continue on the same die in home board',
          ],
          specialRules: [
            'Winner of opening roll re-rolls both dice for their first turn',
            'No backgammon (3x) scoring — only single and gammon',
          ],
          scoring: ['Single win: 1 point', 'Gammon (opponent bore off nothing): 2 points'],
        ),
        GameVariant.plakoto => const _VariantInfo(
          icon: Icons.push_pin,
          startingPosition: 'All 15 checkers on your 1-point (opposite corners)',
          movementDirection: 'Players move in opposite directions',
          coreMechanic: [
            'No hitting! Land on a single opponent checker to PIN it in place',
            'Pinned checkers cannot move until the pinning checker leaves',
            'Two of your checkers (or one pinning) blocks the point completely',
          ],
          specialRules: [
            'Mother piece (\u03bc\u03ac\u03bd\u03b1): your last checker on the starting point',
            'If the mother is pinned by the opponent, you LOSE immediately (2 points)',
            'If both mothers are pinned simultaneously, the game is a draw',
          ],
          scoring: ['Single: 1 pt', 'Gammon: 2 pts', 'Mother pinned: 2 pts (immediate loss)'],
        ),
        GameVariant.fevga => const _VariantInfo(
          icon: Icons.directions_run,
          startingPosition: 'All 15 checkers on one point (diagonal corners)',
          movementDirection: 'Both players move in the SAME direction (counterclockwise)',
          coreMechanic: [
            'No hitting, no pinning — a single checker blocks the point entirely',
            'You cannot land on any point occupied by even one opponent checker',
          ],
          specialRules: [
            'Must advance first checker past opponent\'s starting point before moving others',
            'Cannot create 6+ consecutive blocked points if all opponent checkers are trapped behind',
            'Cannot block all 6 points in your starting quadrant unless opponent has passed through',
          ],
          scoring: ['Single: 1 pt', 'Gammon: 2 pts'],
        ),
        GameVariant.tavla => const _VariantInfo(
          icon: Icons.gavel,
          startingPosition: 'Standard backgammon setup (same as Portes)',
          movementDirection: 'Players move in opposite directions',
          coreMechanic: [
            'Hit lone opponent checkers to send them to the bar',
            'Hit checkers must re-enter through opponent\'s home board',
            'No hit-and-run in home board',
          ],
          specialRules: ['Winner of opening roll re-rolls both dice'],
          scoring: ['Single: 1 pt', 'Gammon: 2 pts'],
        ),
        GameVariant.tapa => const _VariantInfo(
          icon: Icons.push_pin,
          startingPosition: 'All 15 checkers on one point (opposite corners)',
          movementDirection: 'Players move in opposite directions',
          coreMechanic: [
            'No hitting — land on a single opponent to PIN it',
            'Pinned checkers cannot move until freed',
          ],
          specialRules: [
            'No mother piece rule — pinning the last checker on start is NOT an auto-loss',
            'This is the key difference from Greek Plakoto',
          ],
          scoring: ['Single: 1 pt', 'Gammon (mars): 2 pts'],
        ),
        GameVariant.moultezim => const _VariantInfo(
          icon: Icons.directions_run,
          startingPosition: 'All 15 checkers on one point (diagonal corners)',
          movementDirection: 'Both players move in the same direction',
          coreMechanic: [
            'No hitting — single checker blocks the point',
            'Same as Fevga rules',
          ],
          specialRules: [
            'Must advance first checker past opponent\'s start',
            'Cannot create 6+ consecutive blocked points trapping opponent',
          ],
          scoring: ['Single: 1 pt', 'Gammon: 2 pts'],
        ),
        GameVariant.gulBara => const _VariantInfo(
          icon: Icons.auto_awesome,
          startingPosition: 'All 15 checkers on one point (diagonal corners)',
          movementDirection: 'Both players move in the same direction',
          coreMechanic: [
            'No hitting — single checker blocks the point (same as Fevga)',
            'Cascading doubles: after roll 3, doubles trigger a chain reaction',
          ],
          specialRules: [
            'First 3 rolls: doubles work normally (4 moves)',
            'After roll 3: rolling doubles = four of that number + four of every higher number through 6',
            'Example: rolling 2-2 = four 2s, four 3s, four 4s, four 5s, four 6s',
            'If any portion cannot be played, the cascade ends immediately',
            'Same advancement rule and prime restrictions as Fevga/Moultezim',
          ],
          scoring: ['Single: 1 pt', 'Gammon: 2 pts'],
        ),
        GameVariant.longNard => const _VariantInfo(
          icon: Icons.looks_one,
          startingPosition: 'All 15 checkers on the "head" point (diagonal corners)',
          movementDirection: 'Both players move in the same direction (counterclockwise)',
          coreMechanic: [
            'No hitting — single checker blocks the point',
            'Head rule: only ONE checker may leave the head per turn',
          ],
          specialRules: [
            'First turn exception: 3-3, 4-4, or 6-6 allows two off the head',
            'If only one die can be played, the larger die must be used',
            'Cannot build a 6-prime trapping all opponent checkers',
          ],
          scoring: ['Oyn (single): 1 pt', 'Mars (gammon): 2 pts'],
        ),
        GameVariant.shortNard => const _VariantInfo(
          icon: Icons.casino,
          startingPosition: 'Standard backgammon setup',
          movementDirection: 'Players move in opposite directions',
          coreMechanic: [
            'Hit lone opponent checkers (standard backgammon)',
            'Hit-and-run IS allowed',
            'Doubling cube in play',
          ],
          specialRules: [
            'Doubling cube: offer to double stakes before rolling',
            'Jacoby rule: gammon/backgammon only count if cube was used',
            'Beaver: immediately re-double after accepting a double',
            'Backgammon (3x) scoring available',
          ],
          scoring: ['Single: 1 pt', 'Gammon: 2 pts', 'Backgammon: 3 pts', 'All multiplied by cube value'],
        ),
        GameVariant.sheshBesh => const _VariantInfo(
          icon: Icons.speed,
          startingPosition: 'Standard backgammon setup',
          movementDirection: 'Players move in opposite directions',
          coreMechanic: [
            'Hit lone opponent checkers to send them to the bar',
            'Hit-and-run IS allowed — hit and continue moving past',
          ],
          specialRules: [
            'Winner of opening roll re-rolls both dice',
            'Hit-and-run makes this variant faster and more aggressive',
          ],
          scoring: ['Single: 1 pt', 'Gammon: 2 pts'],
        ),
        GameVariant.mahbusa => const _VariantInfo(
          icon: Icons.push_pin,
          startingPosition: 'All 15 checkers on one point (opposite corners)',
          movementDirection: 'Players move in opposite directions',
          coreMechanic: [
            'No hitting — land on a single opponent to PIN it',
            'Pinned checkers cannot move until freed',
          ],
          specialRules: [
            'Mother piece rule: pinning opponent\'s last checker on start = immediate loss (2 pts)',
            'Both mothers pinned = draw',
            'Same rules as Plakoto from the Arabic tradition',
          ],
          scoring: ['Single: 1 pt', 'Gammon: 2 pts', 'Mother pinned: 2 pts'],
        ),
        GameVariant.tawla31 => const _VariantInfo(
          icon: Icons.speed,
          startingPosition: 'Standard backgammon setup',
          movementDirection: 'Players move in opposite directions',
          coreMechanic: [
            'Hit lone opponent checkers to send them to the bar',
            'Hit-and-run IS allowed — hit and continue moving past',
          ],
          specialRules: [
            'Winner of opening roll re-rolls both dice',
            'Points-race scoring — play to 31 points',
          ],
          scoring: ['Win: 1 pt', 'Mars (gammon): 2 pts', 'First to 31 wins'],
        ),
        GameVariant.mahbusaArab => const _VariantInfo(
          icon: Icons.push_pin,
          startingPosition: 'All 15 checkers on one point (opposite corners)',
          movementDirection: 'Players move in opposite directions',
          coreMechanic: [
            'No hitting — land on a single opponent to PIN it',
            'Pinned checkers cannot move until freed',
          ],
          specialRules: [
            'Mother piece rule: pinning opponent\'s last checker on start = immediate loss (2 pts)',
            'Both mothers pinned = draw',
          ],
          scoring: ['Single: 1 pt', 'Gammon: 2 pts', 'Mother pinned: 2 pts'],
        ),
      };
}
