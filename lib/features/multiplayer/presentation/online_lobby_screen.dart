import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/tradition.dart';
import '../../../shared/services/settings_service.dart';
import '../../auth/presentation/auth_provider.dart';

/// Online lobby — choose quick match or play with friend.
class OnlineLobbyScreen extends ConsumerWidget {
  const OnlineLobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final profileAsync = ref.watch(currentPlayerProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Play Online'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          // Sign out button.
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            onPressed: () async {
              final authService = ref.read(authServiceProvider);
              await authService.signOut();
              if (context.mounted) context.go('/home');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: TavliSpacing.lg),

              // Player info card.
              profileAsync.when(
                data: (profile) {
                  if (profile == null) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    padding: const EdgeInsets.all(TavliSpacing.md),
                    decoration: BoxDecoration(
                      color: TavliColors.background,
                      borderRadius: BorderRadius.circular(TavliRadius.lg),
                      border: Border.all(color: TavliColors.primary),
                    ),
                    child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: TavliColors.primary,
                            child: Text(
                              profile.displayName.isNotEmpty
                                  ? profile.displayName[0].toUpperCase()
                                  : 'P',
                              style: const TextStyle(
                                color: TavliColors.light,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: TavliSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.displayName,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: TavliSpacing.xxs),
                                Text(
                                  'Rating: ${profile.rating}  ·  ${profile.gamesPlayed} games',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                '${profile.wins}W',
                                style: const TextStyle(
                                  color: TavliColors.success,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${profile.losses}L',
                                style: const TextStyle(
                                  color: TavliColors.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Active game banner.
              profileAsync.when(
                data: (profile) {
                  if (profile?.activeGameId == null) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Card(
                      color: colors.primaryContainer,
                      child: ListTile(
                        leading: Icon(Icons.play_circle,
                            color: colors.onPrimaryContainer),
                        title: Text(
                          'Active Game',
                          style: TextStyle(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'You have a game in progress',
                          style: TextStyle(
                            color: colors.onPrimaryContainer
                                .withValues(alpha: 0.8),
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Rejoin active game.
                          context.push('/online-game', extra: {
                            'gameRoomId': profile!.activeGameId,
                            'rejoin': true,
                          });
                        },
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: TavliSpacing.xl),

              // ── My Tradition section ──────────────────────
              Text(
                '${SettingsService.instance.tradition.displayName} — My Tradition',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: TavliTheme.serifFamily,
                  fontWeight: FontWeight.w600,
                  color: TavliColors.text,
                ),
              ),
              const SizedBox(height: TavliSpacing.sm),

              _LobbyCard(
                icon: Icons.flash_on,
                title: 'Quick Match',
                subtitle: 'Find a ${SettingsService.instance.tradition.displayName} player near your rating',
                onTap: () => context.push('/matchmaking'),
              ),

              const SizedBox(height: TavliSpacing.sm),

              // ── International section ─────────────────────
              const Text(
                'International',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: TavliColors.text,
                ),
              ),
              const SizedBox(height: TavliSpacing.sm),

              _LobbyCard(
                icon: Icons.public,
                title: 'International Match',
                subtitle: 'Play across traditions by game mechanic',
                onTap: () => context.push('/matchmaking', extra: {
                  'poolType': PoolType.international,
                }),
              ),

              const SizedBox(height: TavliSpacing.lg),

              // ── Private games ─────────────────────────────
              const Text(
                'Private Games',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: TavliColors.text,
                ),
              ),
              const SizedBox(height: TavliSpacing.sm),

              _LobbyCard(
                icon: Icons.add_circle_outline,
                title: 'Create Room',
                subtitle: 'Invite a friend with a code or QR',
                onTap: () => context.push('/invite/create'),
              ),

              const SizedBox(height: TavliSpacing.sm),

              _LobbyCard(
                icon: Icons.login,
                title: 'Join Room',
                subtitle: 'Enter a room code or scan QR',
                onTap: () => context.push('/join'),
              ),

              const SizedBox(height: TavliSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _LobbyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LobbyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: TavliColors.primary,
        borderRadius: BorderRadius.circular(TavliRadius.lg),
        border: Border.all(color: TavliColors.background),
        boxShadow: TavliShadows.xsmall,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TavliRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(TavliSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: TavliColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(TavliRadius.md),
                ),
                child: Icon(icon, size: 26, color: TavliColors.primary),
              ),
              const SizedBox(width: TavliSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: TavliSpacing.xxs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: TavliColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
