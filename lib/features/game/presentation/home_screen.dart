import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/constants/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/services/settings_service.dart';

/// Home screen — bot greets you, choose how to play.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hour = DateTime.now().hour;
    if (l10n != null) {
      if (hour < 12) return l10n.homeGreetingMorning;
      if (hour < 18) return l10n.homeGreetingAfternoon;
      return l10n.homeGreetingEvening;
    }
    if (hour < 12) return 'Καλημέρα! Ready for coffee and tavli?';
    if (hour < 18) return 'Μεσημέρι... perfect time for a game, ρε!';
    return 'Καληνύχτα soon... one more game?';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
                'Tavli',
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

              // Bot greeting card.
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
                        border: Border.all(
                          color: TavliColors.primary,
                          width: 0.467,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          SettingsService.instance.botPersonality.avatarInitial,
                          style: const TextStyle(
                            color: TavliColors.primary,
                            fontSize: 21,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.41,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: TavliSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            SettingsService.instance.botPersonality.displayName,
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: TavliTheme.serifFamily,
                              fontWeight: FontWeight.w500,
                              color: TavliColors.primary,
                            ),
                          ),
                          const SizedBox(height: TavliSpacing.xxs),
                          Text(
                            _greeting(context),
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

              // Game variant tabs.
              Row(
                children: [
                  _VariantChip(
                    label: 'Πόρτες',
                    selected: true,
                    onTap: () => context.push('/difficulty', extra: {'variant': 'portes'}),
                  ),
                  const SizedBox(width: TavliSpacing.sm),
                  _VariantChip(
                    label: 'Πλακωτό',
                    selected: false,
                    onTap: () => context.push('/difficulty', extra: {'variant': 'plakoto'}),
                  ),
                  const SizedBox(width: TavliSpacing.sm),
                  _VariantChip(
                    label: 'Φεύγα',
                    selected: false,
                    onTap: () => context.push('/difficulty', extra: {'variant': 'fevga'}),
                  ),
                ],
              ),
              const SizedBox(height: TavliSpacing.sm),

              // Play mode cards.
              _PlayModeCard(
                icon: Icons.smart_toy_outlined,
                title: l10n?.playVsBot ?? 'Play vs ${SettingsService.instance.botPersonality.displayName}',
                subtitle: l10n?.playVsBotSub ?? 'Challenge the AI opponent',
                onTap: () => context.push('/difficulty'),
              ),
              const SizedBox(height: TavliSpacing.sm),
              _PlayModeCard(
                icon: Icons.public,
                title: l10n?.playOnline ?? 'Play Online',
                subtitle: l10n?.playOnlineSub ?? 'Quick match or invite a friend',
                onTap: () {
                  if (FirebaseAuth.instance.currentUser != null) {
                    context.push('/online-lobby');
                  } else {
                    context.push('/sign-in');
                  }
                },
              ),
              const SizedBox(height: TavliSpacing.sm),
              _PlayModeCard(
                icon: Icons.people_outline,
                title: l10n?.passAndPlay ?? 'Pass & Play',
                subtitle: l10n?.passAndPlaySub ?? 'Two players, one device',
                onTap: () => context.push('/pass-play'),
              ),
              const SizedBox(height: TavliSpacing.sm),
              _PlayModeCard(
                icon: Icons.school_outlined,
                title: l10n?.learnToPlay ?? 'Learn to Play',
                subtitle: l10n?.learnToPlaySub ?? 'Interactive tutorial with ${SettingsService.instance.botPersonality.displayName}',
                onTap: () => context.push('/tutorial'),
              ),
              const SizedBox(height: TavliSpacing.sm),
              _PlayModeCard(
                icon: Icons.emoji_events_outlined,
                title: 'Weekly Challenges',
                subtitle: 'Complete tasks and earn rewards',
                onTap: () => context.push('/challenges'),
              ),
              const SizedBox(height: TavliSpacing.sm),
              _PlayModeCard(
                icon: Icons.storefront_outlined,
                title: 'Shop',
                subtitle: 'Boards, checkers, and dice sets',
                onTap: () => context.push('/shop'),
              ),
              const SizedBox(height: TavliSpacing.sm),
              _PlayModeCard(
                icon: Icons.replay_outlined,
                title: 'Replay',
                subtitle: 'Watch your previous games',
                onTap: () => context.push('/replay'),
              ),
              // Extra padding for bottom nav gradient.
              const SizedBox(height: 140),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PlayModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title — $subtitle',
      child: GestureDetector(
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
      ),
    );
  }
}

class _VariantChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _VariantChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: TavliSpacing.md),
          decoration: BoxDecoration(
            color: TavliColors.primary,
            borderRadius: BorderRadius.circular(TavliRadius.lg),
            border: Border.all(color: TavliColors.background),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontFamily: TavliTheme.serifFamily,
                fontWeight: FontWeight.w500,
                color: TavliColors.light,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
