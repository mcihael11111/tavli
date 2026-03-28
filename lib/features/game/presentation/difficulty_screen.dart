import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../ai/difficulty/difficulty_level.dart';
import '../../../shared/services/progression_service.dart';
import '../../../shared/services/copy_service.dart';
import '../../../shared/services/settings_service.dart';
import '../../../shared/widgets/content_module.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../domain/engine/variants/game_variant.dart';

/// Difficulty selection screen — pick which difficulty to face.
class DifficultyScreen extends StatefulWidget {
  final GameVariant variant;

  const DifficultyScreen({super.key, this.variant = GameVariant.portes});

  @override
  State<DifficultyScreen> createState() => _DifficultyScreenState();
}

class _DifficultyScreenState extends State<DifficultyScreen> {
  late ProgressionService _progression;

  @override
  void initState() {
    super.initState();
    _progression = ProgressionService.instance;
  }

  @override
  Widget build(BuildContext context) {
    final overall = _progression.overallStats;

    return GradientScaffold(
      appBar: AppBar(
        title: Text(TavliCopy.chooseDifficulty),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            TavliSpacing.md, kToolbarHeight + TavliSpacing.xl, TavliSpacing.md, TavliSpacing.md,
          ),
          children: [
            // Bot info module.
            ContentModule(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TavliColors.surface,
                  border: Border.all(color: TavliColors.primary),
                ),
                child: Center(
                  child: Text(
                    SettingsService.instance.botPersonality.avatarInitial,
                    style: const TextStyle(
                      color: TavliColors.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: SettingsService.instance.botPersonality.greekName,
              body: overall.totalGames > 0
                  ? '${overall.wins}W \u2013 ${overall.losses}L \u00b7 Best streak: ${overall.bestStreak}'
                  : 'Choose your opponent',
            ),
            const SizedBox(height: TavliSpacing.md),

            for (final level in DifficultyLevel.values)
              _DifficultyCard(
                level: level,
                stats: _progression.statsFor(level),
                isLocked: !_progression.isUnlocked(level),
                onTap: () => context.push('/game', extra: {
                  'difficulty': level,
                  'variant': widget.variant,
                }),
              ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final DifficultyLevel level;
  final DifficultyStats stats;
  final bool isLocked;
  final VoidCallback onTap;

  const _DifficultyCard({
    required this.level,
    required this.stats,
    required this.isLocked,
    required this.onTap,
  });

  IconData get _icon => switch (level) {
        DifficultyLevel.easy => Icons.sentiment_satisfied_alt,
        DifficultyLevel.easyWithHelp => Icons.school_outlined,
        DifficultyLevel.medium => Icons.sports_martial_arts,
        DifficultyLevel.hard => Icons.local_fire_department,
        DifficultyLevel.pappous => Icons.elderly,
      };

  Color _accent(ColorScheme colors) => switch (level) {
        DifficultyLevel.easy => TavliColors.success,
        DifficultyLevel.easyWithHelp => colors.secondary,
        DifficultyLevel.medium => colors.tertiary,
        DifficultyLevel.hard => TavliColors.hitEffect,
        DifficultyLevel.pappous => colors.error,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = _accent(colors);

    return Opacity(
      opacity: isLocked ? 0.5 : 1.0,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ContentModule(
          onTap: isLocked ? null : onTap,
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: accent, size: 26),
          ),
          title: level.greekName,
          trailing: !isLocked
              ? const Icon(Icons.play_arrow, color: TavliColors.light, size: 28)
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '(${level.englishName})',
                    style: TextStyle(
                      fontSize: 14,
                      color: TavliColors.light.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TavliSpacing.xxs),
              Text(
                level.description,
                style: TextStyle(
                  fontSize: 13,
                  color: TavliColors.light.withValues(alpha: 0.8),
                ),
              ),
              if (isLocked && level.unlockCondition != null) ...[
                const SizedBox(height: TavliSpacing.xxs),
                Row(
                  children: [
                    Icon(Icons.lock_outline, size: 12, color: TavliColors.error),
                    const SizedBox(width: 4),
                    Text(
                      level.unlockCondition!,
                      style: const TextStyle(fontSize: 11, color: TavliColors.error),
                    ),
                  ],
                ),
              ],
              if (!isLocked && stats.totalGames > 0) ...[
                const SizedBox(height: TavliSpacing.xxs),
                Row(
                  children: [
                    Text(
                      '${stats.wins}W\u2013${stats.losses}L',
                      style: TextStyle(
                        fontSize: 11,
                        color: TavliColors.light.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (stats.currentStreak > 1) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${stats.currentStreak} streak',
                        style: TextStyle(
                          fontSize: 11,
                          color: accent.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
