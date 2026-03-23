import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/services/progression_service.dart';
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

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
          child: Column(
            children: [
              const SizedBox(height: TavliSpacing.xxl),
              // Title.
              Text(
                'Profile',
                style: TextStyle(
                  fontSize: 32,
                  fontFamily: TavliTheme.serifFamily,
                  fontWeight: FontWeight.w400,
                  color: TavliColors.text,
                  letterSpacing: -0.64,
                  height: 1.25,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TavliSpacing.sm),

              // Profile card (elevated).
              Container(
                padding: const EdgeInsets.all(TavliSpacing.md),
                decoration: BoxDecoration(
                  color: TavliColors.background,
                  borderRadius: BorderRadius.circular(TavliRadius.lg),
                  border: Border.all(color: TavliColors.primary),
                  boxShadow: TavliShadows.xsmall,
                ),
                child: Row(
                  children: [
                    Container(
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
                    const SizedBox(width: TavliSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Player',
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: TavliTheme.serifFamily,
                              fontWeight: FontWeight.w500,
                              color: TavliColors.primary,
                            ),
                          ),
                          const SizedBox(height: TavliSpacing.xxs),
                          Text(
                            rankTitle,
                            style: const TextStyle(
                              fontSize: 14,
                              color: TavliColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TavliSpacing.md),

              // Stats tabs.
              Row(
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
              const SizedBox(height: TavliSpacing.sm),

              // List cards.
              _ProfileCard(
                icon: Icons.history,
                title: 'Match History',
                subtitle: '${overall.totalGames} games played',
                onTap: () => context.push('/match-history'),
              ),
              const SizedBox(height: 10),
              _ProfileCard(
                icon: Icons.emoji_events_outlined,
                title: 'Achievements',
                subtitle: 'Track your progress',
                onTap: () => context.push('/achievements'),
              ),
              const SizedBox(height: 10),
              _ProfileCard(
                icon: Icons.trending_up,
                title: 'Statistics',
                subtitle: '${overall.wins}W – ${overall.losses}L · Best streak: ${overall.bestStreak}',
                onTap: () {},
              ),
              const SizedBox(height: 10),
              for (final level in DifficultyLevel.values) ...[
                _ProfileCard(
                  icon: isUnlockedIcon(progression, level),
                  title: level.greekName,
                  subtitle: _difficultySubtitle(progression, level),
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: TavliSpacing.md),
        decoration: BoxDecoration(
          color: TavliColors.primary,
          borderRadius: BorderRadius.circular(TavliRadius.lg),
          border: Border.all(color: TavliColors.background),
        ),
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
                style: const TextStyle(
                  fontSize: 14,
                  color: TavliColors.light,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(TavliSpacing.md),
        decoration: BoxDecoration(
          color: TavliColors.primary,
          borderRadius: BorderRadius.circular(TavliRadius.lg),
          border: Border.all(color: TavliColors.background),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: TavliColors.light),
            const SizedBox(width: TavliSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: TavliTheme.serifFamily,
                      fontWeight: FontWeight.w500,
                      color: TavliColors.light,
                    ),
                  ),
                  const SizedBox(height: TavliSpacing.xxs),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: TavliColors.light,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: TavliColors.light, size: 24),
          ],
        ),
      ),
    );
  }
}
