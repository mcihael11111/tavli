import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/tradition.dart';
import '../../../shared/services/settings_service.dart';
import '../../../shared/widgets/content_module.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../auth/presentation/auth_provider.dart';

/// Online lobby — choose quick match or play with friend.
class OnlineLobbyScreen extends ConsumerWidget {
  const OnlineLobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentPlayerProfileProvider);

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Play Online'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
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
          padding: EdgeInsets.fromLTRB(
            TavliSpacing.lg, kToolbarHeight + TavliSpacing.xl, TavliSpacing.lg, TavliSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Player info module.
              profileAsync.when(
                data: (profile) {
                  if (profile == null) return const SizedBox.shrink();
                  return ContentModule(
                    leading: CircleAvatar(
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
                    title: profile.displayName,
                    body: 'Rating: ${profile.rating}  \u00b7  ${profile.gamesPlayed} games',
                    trailing: Column(
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
                  if (profile?.activeGameId == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ContentModule(
                      icon: Icons.play_circle,
                      title: 'Active Game',
                      body: 'You have a game in progress',
                      trailing: const Icon(Icons.chevron_right, color: TavliColors.light),
                      onTap: () {
                        context.push('/online-game', extra: {
                          'gameRoomId': profile!.activeGameId,
                          'rejoin': true,
                        });
                      },
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: TavliSpacing.xl),

              // ── My Tradition section ──────────────────────
              Text(
                '${SettingsService.instance.tradition.displayName} \u2014 My Tradition',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: TavliTheme.serifFamily,
                  fontWeight: FontWeight.w600,
                  color: TavliColors.light,
                ),
              ),
              const SizedBox(height: TavliSpacing.sm),

              ContentModule(
                icon: Icons.flash_on,
                iconSize: 26,
                title: 'Quick Match',
                body: 'Find a ${SettingsService.instance.tradition.displayName} player near your rating',
                trailing: const Icon(Icons.chevron_right, color: TavliColors.light),
                onTap: () => context.push('/matchmaking'),
              ),

              const SizedBox(height: TavliSpacing.lg),

              // ── International section ─────────────────────
              Text(
                'International',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: TavliTheme.serifFamily,
                  fontWeight: FontWeight.w600,
                  color: TavliColors.light,
                ),
              ),
              const SizedBox(height: TavliSpacing.sm),

              ContentModule(
                icon: Icons.public,
                iconSize: 26,
                title: 'International Match',
                body: 'Play across traditions by game mechanic',
                trailing: const Icon(Icons.chevron_right, color: TavliColors.light),
                onTap: () => context.push('/matchmaking', extra: {
                  'poolType': PoolType.international,
                }),
              ),

              const SizedBox(height: TavliSpacing.lg),

              // ── Private games ─────────────────────────────
              Text(
                'Private Games',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: TavliTheme.serifFamily,
                  fontWeight: FontWeight.w600,
                  color: TavliColors.light,
                ),
              ),
              const SizedBox(height: TavliSpacing.sm),

              ContentModule(
                icon: Icons.add_circle_outline,
                iconSize: 26,
                title: 'Create Room',
                body: 'Invite a friend with a code or QR',
                trailing: const Icon(Icons.chevron_right, color: TavliColors.light),
                onTap: () => context.push('/invite/create'),
              ),
              const SizedBox(height: TavliSpacing.sm),

              ContentModule(
                icon: Icons.login,
                iconSize: 26,
                title: 'Join Room',
                body: 'Enter a room code or scan QR',
                trailing: const Icon(Icons.chevron_right, color: TavliColors.light),
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
