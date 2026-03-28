import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/services/copy_service.dart';
import '../../../shared/widgets/content_module.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../data/achievements.dart';

/// Achievements display screen.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AchievementService.instance;

    return GradientScaffold(
      appBar: AppBar(
        title: Text('${TavliCopy.achievements} (${service.unlockedCount}/${service.totalCount})'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: kToolbarHeight + TavliSpacing.md),

            // Progress module.
            ContentModule(
              icon: Icons.emoji_events,
              title: '${service.unlockedCount} / ${service.totalCount} Unlocked',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: service.totalCount > 0
                      ? service.unlockedCount / service.totalCount
                      : 0,
                  minHeight: 8,
                  backgroundColor: TavliColors.light.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation(TavliColors.light),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Unlocked.
            if (service.unlockedAchievements.isNotEmpty) ...[
              _SectionLabel('Unlocked'),
              const SizedBox(height: 8),
              for (final a in service.unlockedAchievements)
                _AchievementTile(achievement: a, unlocked: true),
              const SizedBox(height: 24),
            ],

            // All locked achievements grouped.
            ..._buildLockedSections(service),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLockedSections(AchievementService service) {
    final widgets = <Widget>[];
    for (final cat in AchievementCategory.values) {
      final catAchievements = service.lockedAchievements
          .where((a) => a.category == cat)
          .toList();
      if (catAchievements.isEmpty) continue;

      widgets.add(_SectionLabel(_categoryLabel(cat)));
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
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12, letterSpacing: 1.5,
        fontWeight: FontWeight.w600, color: TavliColors.light.withValues(alpha: 0.7),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Opacity(
        opacity: unlocked ? 1.0 : 0.5,
        child: ContentModule(
          leading: Text(
            unlocked ? achievement.icon : '\u{1F512}',
            style: const TextStyle(fontSize: 24),
          ),
          title: achievement.name,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(achievement.nameGreek,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: TavliColors.light.withValues(alpha: 0.6),
                  )),
              const SizedBox(height: 2),
              Text(achievement.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: TavliColors.light.withValues(alpha: 0.8),
                  )),
            ],
          ),
          trailing: unlocked
              ? const Icon(Icons.check_circle, color: TavliColors.light, size: 20)
              : null,
        ),
      ),
    );
  }
}
