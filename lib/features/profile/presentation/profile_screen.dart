import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/services/progression_service.dart';
import '../../../shared/services/copy_service.dart';
import '../../../shared/services/settings_service.dart';
import '../../../shared/widgets/content_module.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../ai/difficulty/difficulty_level.dart';

/// Profile screen — shows player stats from ProgressionService.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progression = ProgressionService.instance;
    final overall = progression.overallStats;

    final rating = 1000 + (overall.wins * 15) - (overall.losses * 10);
    final rankTitle = _rankFor(rating);

    return GradientScaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
          child: Column(
            children: [
              const SizedBox(height: TavliSpacing.xxl),
              // Title.
              Text(
                TavliCopy.profile,
                style: TextStyle(
                  fontSize: 32,
                  fontFamily: TavliTheme.serifFamily,
                  fontWeight: FontWeight.w400,
                  color: TavliColors.light,
                  letterSpacing: -0.64,
                  height: 1.25,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TavliSpacing.sm),

              // Profile module.
              ContentModule(
                title: SettingsService.instance.playerDisplayName.isNotEmpty
                    ? SettingsService.instance.playerDisplayName
                    : TavliCopy.player,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: TavliColors.surface,
                    border: Border.all(color: TavliColors.primary, width: 0.467),
                  ),
                  child: const Center(
                    child: Icon(Icons.person, size: 24, color: TavliColors.primary),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${SettingsService.instance.tradition.flagEmoji} '
                      '${SettingsService.instance.tradition.displayName} Player',
                      style: const TextStyle(
                        fontSize: 14,
                        color: TavliColors.light,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rankTitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: TavliColors.light.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TavliSpacing.md),

              // Stats module (group).
              ContentModule(
                child: Row(
                  children: [
                    _StatChip('$rating', 'Rating'),
                    const SizedBox(width: TavliSpacing.sm),
                    _StatChip('${overall.totalGames}', 'Games'),
                    const SizedBox(width: TavliSpacing.sm),
                    _StatChip(overall.totalGames > 0
                        ? '${(overall.winRate * 100).round()}%'
                        : '—', 'Win Rate'),
                  ],
                ),
              ),
              const SizedBox(height: TavliSpacing.sm),

              // List cards.
              ContentModule(
                icon: Icons.history,
                iconSize: 32,
                title: TavliCopy.matchHistory,
                body: '${overall.totalGames} games played',
                trailing: const Icon(Icons.chevron_right, color: TavliColors.light, size: 24),
                onTap: () => context.push('/match-history'),
              ),
              const SizedBox(height: 10),
              ContentModule(
                icon: Icons.emoji_events_outlined,
                iconSize: 32,
                title: TavliCopy.achievements,
                body: 'Track your progress',
                trailing: const Icon(Icons.chevron_right, color: TavliColors.light, size: 24),
                onTap: () => context.push('/achievements'),
              ),
              const SizedBox(height: 10),
              ContentModule(
                icon: Icons.trending_up,
                iconSize: 32,
                title: TavliCopy.statistics,
                body: '${overall.wins}W – ${overall.losses}L · Best streak: ${overall.bestStreak}',
                trailing: const Icon(Icons.chevron_right, color: TavliColors.light, size: 24),
                onTap: () {},
              ),
              const SizedBox(height: 10),
              for (final level in DifficultyLevel.values) ...[
                ContentModule(
                  icon: isUnlockedIcon(progression, level),
                  iconSize: 32,
                  title: level.greekName,
                  body: _difficultySubtitle(progression, level),
                  trailing: const Icon(Icons.chevron_right, color: TavliColors.light, size: 24),
                  onTap: () {},
                ),
                const SizedBox(height: 10),
              ],

              // Extra padding for bottom nav gradient.
              const SizedBox(height: 140),
            ],
          ),
        ),
      ),
    );
  }

  IconData isUnlockedIcon(ProgressionService p, DifficultyLevel level) {
    return p.isUnlocked(level) ? Icons.sports_martial_arts : Icons.lock_outline;
  }

  String _difficultySubtitle(ProgressionService p, DifficultyLevel level) {
    if (!p.isUnlocked(level)) return 'Locked';
    final stats = p.statsFor(level);
    if (stats.totalGames == 0) return '${level.englishName} · No games yet';
    return '${level.englishName} · ${stats.wins}W–${stats.losses}L';
  }

  String _rankFor(int rating) {
    if (rating < 800) return 'Αρχάριος (Beginner)';
    if (rating < 1200) return 'Μαθητής (Student)';
    if (rating < 1600) return 'Παίκτης (Player)';
    if (rating < 2000) return 'Δάσκαλος (Master)';
    if (rating < 2400) return 'Μάστορας (Grandmaster)';
    return 'Θρύλος (Legend)';
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  const _StatChip(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontFamily: TavliTheme.serifFamily,
                fontWeight: FontWeight.w500,
                color: TavliColors.light,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: TavliColors.light.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
