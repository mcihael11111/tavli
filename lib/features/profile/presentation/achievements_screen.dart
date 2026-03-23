import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../data/achievements.dart';

/// Achievements display screen.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final service = AchievementService.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text('Achievements (${service.unlockedCount}/${service.totalCount})'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Progress bar.
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: service.totalCount > 0
                  ? service.unlockedCount / service.totalCount
                  : 0,
              minHeight: 8,
              backgroundColor: TavliColors.primary.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation(TavliColors.primary),
            ),
          ),
          const SizedBox(height: 24),

          // Unlocked.
          if (service.unlockedAchievements.isNotEmpty) ...[
            const _SectionLabel('Unlocked', TavliColors.primary),
            const SizedBox(height: 8),
            for (final a in service.unlockedAchievements)
              _AchievementTile(achievement: a, unlocked: true),
            const SizedBox(height: 24),
          ],

          // All locked achievements grouped.
          ..._buildLockedSections(service, colors),
        ],
      ),
    );
  }

  List<Widget> _buildLockedSections(AchievementService service, ColorScheme colors) {
    final widgets = <Widget>[];
    for (final cat in AchievementCategory.values) {
      final catAchievements = service.lockedAchievements
          .where((a) => a.category == cat)
          .toList();
      if (catAchievements.isEmpty) continue;

      widgets.add(_SectionLabel(_categoryLabel(cat), TavliColors.primary));
      widgets.add(const SizedBox(height: 8));
      for (final a in catAchievements) {
        widgets.add(_AchievementTile(achievement: a, unlocked: false));
      }
      widgets.add(const SizedBox(height: 16));
    }
    return widgets;
  }

  String _categoryLabel(AchievementCategory c) => switch (c) {
        AchievementCategory.beginner => 'Beginner',
        AchievementCategory.skill => 'Skill',
        AchievementCategory.social => 'Social',
        AchievementCategory.mastery => 'Mastery',
      };
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12, letterSpacing: 1.5,
        fontWeight: FontWeight.w600, color: color,
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  const _AchievementTile({required this.achievement, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: TavliColors.primary,
        borderRadius: BorderRadius.circular(TavliRadius.lg),
        border: Border.all(color: TavliColors.background),
        boxShadow: TavliShadows.xsmall,
      ),
      child: Opacity(
        opacity: unlocked ? 1.0 : 0.5,
        child: ListTile(
          leading: Text(
            unlocked ? achievement.icon : '🔒',
            style: const TextStyle(fontSize: 24),
          ),
          title: Text(
            achievement.name,
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(achievement.nameGreek,
                  style: theme.textTheme.labelSmall?.copyWith(color: colors.secondary)),
              const SizedBox(height: 2),
              Text(achievement.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.7),
                  )),
            ],
          ),
          trailing: unlocked
              ? const Icon(Icons.check_circle, color: TavliColors.primary, size: 20)
              : null,
        ),
      ),
    );
  }
}
