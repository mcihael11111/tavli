import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../ai/difficulty/difficulty_level.dart';
import '../../../shared/services/progression_service.dart';

/// Difficulty selection screen — pick which Mikhail to face.
class DifficultyScreen extends StatefulWidget {
  const DifficultyScreen({super.key});

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final overall = _progression.overallStats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Difficulty'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Mikhail portrait area with overall stats.
          Container(
            height: 100,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Μιχαήλ', style: theme.textTheme.headlineLarge),
                  const SizedBox(height: 4),
                  if (overall.totalGames > 0)
                    Text(
                      '${overall.wins}W – ${overall.losses}L · Best streak: ${overall.bestStreak}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.secondary,
                      ),
                    )
                  else
                    Text(
                      'Choose your opponent',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.secondary,
                      ),
                    ),
                ],
              ),
            ),
          ),

          for (final level in DifficultyLevel.values)
            _DifficultyCard(
              level: level,
              stats: _progression.statsFor(level),
              isLocked: !_progression.isUnlocked(level),
              onTap: () => context.push('/game', extra: level),
            ),
        ],
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
        DifficultyLevel.easy => const Color(0xFF6B8E4E),
        DifficultyLevel.easyWithHelp => colors.secondary,
        DifficultyLevel.medium => colors.tertiary,
        DifficultyLevel.hard => const Color(0xFFC67B5C),
        DifficultyLevel.pappous => colors.error,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = _accent(colors);

    return Opacity(
      opacity: isLocked ? 0.5 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: isLocked ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_icon, color: accent, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            level.greekName,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${level.englishName})',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        level.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                      if (isLocked && level.unlockCondition != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.lock_outline, size: 12, color: colors.error),
                            const SizedBox(width: 4),
                            Text(
                              level.unlockCondition!,
                              style: TextStyle(fontSize: 11, color: colors.error),
                            ),
                          ],
                        ),
                      ],
                      if (!isLocked && stats.totalGames > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${stats.wins}W–${stats.losses}L',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.onSurface.withValues(alpha: 0.5),
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
                if (!isLocked)
                  Icon(Icons.play_arrow, color: colors.secondary, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
