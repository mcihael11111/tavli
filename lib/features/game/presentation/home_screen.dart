import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/providers/accessibility_providers.dart';
import '../../../core/constants/tradition.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/services/copy_service.dart';
import '../../../shared/services/settings_service.dart';
import '../../../shared/widgets/content_module.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../../shared/widgets/variant_intro_sheet.dart';
import '../domain/engine/variants/game_variant.dart';

/// Home screen — cultural-first game selection hub.
///
/// Layout: greeting -> variant chips -> marathon -> play modes.
/// Adapts dynamically based on the player's selected tradition.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GameVariant _selectedVariant;

  @override
  void initState() {
    super.initState();
    _selectedVariant = SettingsService.instance.tradition.defaultVariant;
  }

  String _greeting(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hour = DateTime.now().hour;
    final personality = SettingsService.instance.botPersonality;
    final langLevel = SettingsService.instance.languageLevel;

    if (hour < 12) {
      return l10n?.homeGreetingMorning ??
          personality.morningGreeting(langLevel);
    }
    if (hour < 18) {
      return l10n?.homeGreetingAfternoon ??
          personality.afternoonGreeting(langLevel);
    }
    return l10n?.homeGreetingEvening ??
        personality.eveningGreeting(langLevel);
  }

  void _onVariantTap(GameVariant variant) async {
    setState(() => _selectedVariant = variant);

    final shown = await VariantIntroSheet.showIfNeeded(
      context: context,
      variant: variant,
      onPlay: () => context.push('/difficulty',
          extra: {'variant': variant.name}),
      onTutorial: () => context.push('/learn'),
    );

    if (!shown && mounted) {
      context.push('/difficulty', extra: {'variant': variant.name});
    }
  }

  void _onMarathonTap() {
    final tradition = SettingsService.instance.tradition;
    context.push('/difficulty', extra: {
      'variant': tradition.defaultVariant.name,
      'marathon': true,
      'tradition': tradition.name,
    });
  }

  void _onQuickPlay() {
    context.push('/difficulty',
        extra: {'variant': _selectedVariant.name});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final tradition = SettingsService.instance.tradition;
    final variants = tradition.variants;

    return GradientScaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
          child: Column(
            children: [
              const SizedBox(height: TavliSpacing.xl),

              // Dynamic title — tradition name.
              Text(
                tradition.displayName,
                style: theme.textTheme.displayMedium!.copyWith(
                  fontWeight: FontWeight.w400,
                  color: TavliColors.light,
                  letterSpacing: -0.64,
                  height: 1.25,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: TavliSpacing.sm),

              // Bot greeting module.
              ContentModule(
                title: SettingsService.instance.botPersonality.displayName,
                leading: Container(
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
                      style: theme.textTheme.headlineMedium!.copyWith(
                        color: TavliColors.primary,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.41,
                      ),
                    ),
                  ),
                ),
                body: _greeting(context),
              ),

              const SizedBox(height: TavliSpacing.lg),

              // Section: Choose Your Game.
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose Your Game',
                  style: theme.textTheme.headlineSmall!.copyWith(
                    color: TavliColors.light,
                  ),
                ),
              ),
              const SizedBox(height: TavliSpacing.sm),

              // Game variant cards — dynamic per tradition.
              Row(
                children: [
                  for (int i = 0; i < variants.length; i++) ...[
                    if (i > 0) const SizedBox(width: TavliSpacing.sm),
                    _VariantCard(
                      variant: variants[i],
                      selected: variants[i] == _selectedVariant,
                      onTap: () => _onVariantTap(variants[i]),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: TavliSpacing.sm),

              // Marathon mode module.
              ContentModule(
                icon: Icons.emoji_events,
                iconSize: 32,
                title: '${tradition.displayName} Marathon',
                body: tradition.variants.map((v) => v.nativeName).join(' \u2192 '),
                trailing: const Icon(Icons.play_arrow, color: TavliColors.light, size: 28),
                onTap: _onMarathonTap,
              ),

              const SizedBox(height: TavliSpacing.lg),

              // Section: Play Modes.
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Play',
                  style: theme.textTheme.headlineSmall!.copyWith(
                    color: TavliColors.light,
                  ),
                ),
              ),
              const SizedBox(height: TavliSpacing.sm),

              ContentModule(
                icon: Icons.smart_toy_outlined,
                iconSize: 32,
                title: l10n?.playVsBot ?? TavliCopy.playVsBot,
                body: l10n?.playVsBotSub ?? TavliCopy.playVsBotSub,
                trailing: const Icon(Icons.chevron_right, color: TavliColors.light, size: 24),
                onTap: _onQuickPlay,
              ),
              const SizedBox(height: TavliSpacing.sm),
              ContentModule(
                icon: Icons.public,
                iconSize: 32,
                title: l10n?.playOnline ?? TavliCopy.playOnline,
                body: l10n?.playOnlineSub ?? TavliCopy.playOnlineSub,
                trailing: const Icon(Icons.chevron_right, color: TavliColors.light, size: 24),
                onTap: () {
                  if (FirebaseAuth.instance.currentUser != null) {
                    context.push('/online-lobby');
                  } else {
                    context.push('/sign-in');
                  }
                },
              ),
              const SizedBox(height: TavliSpacing.sm),
              ContentModule(
                icon: Icons.people_outline,
                iconSize: 32,
                title: l10n?.passAndPlay ?? TavliCopy.passAndPlay,
                body: l10n?.passAndPlaySub ?? TavliCopy.passAndPlaySub,
                trailing: const Icon(Icons.chevron_right, color: TavliColors.light, size: 24),
                onTap: () => context.push('/pass-play',
                    extra: {'variant': _selectedVariant.name}),
              ),

              const SizedBox(height: TavliSpacing.lg),

              // Section: More.
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'More',
                  style: theme.textTheme.headlineSmall!.copyWith(
                    color: TavliColors.light,
                  ),
                ),
              ),
              const SizedBox(height: TavliSpacing.sm),

              ContentModule(
                icon: Icons.school_outlined,
                iconSize: 32,
                title: l10n?.learnToPlay ?? TavliCopy.learnToPlay,
                body: l10n?.learnToPlaySub ?? TavliCopy.learnToPlaySub,
                trailing: const Icon(Icons.chevron_right, color: TavliColors.light, size: 24),
                onTap: () => context.push('/learn'),
              ),
              const SizedBox(height: TavliSpacing.sm),
              ContentModule(
                icon: Icons.emoji_events_outlined,
                iconSize: 32,
                title: TavliCopy.weeklyChallenges,
                body: TavliCopy.challengesSub,
                trailing: const Icon(Icons.chevron_right, color: TavliColors.light, size: 24),
                onTap: () => context.push('/challenges'),
              ),
              const SizedBox(height: TavliSpacing.sm),
              ContentModule(
                icon: Icons.storefront_outlined,
                iconSize: 32,
                title: TavliCopy.shop,
                body: TavliCopy.shopSub,
                trailing: const Icon(Icons.chevron_right, color: TavliColors.light, size: 24),
                onTap: () => context.push('/shop'),
              ),
              const SizedBox(height: TavliSpacing.sm),

              // Explore other traditions module.
              _ExploreTraditionsCard(
                currentTradition: tradition,
                onTraditionTap: (t) {
                  SettingsService.instance.tradition = t;
                  setState(() {
                    _selectedVariant = t.defaultVariant;
                  });
                },
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

/// Card for a single game variant with mechanic icon and native name.
class _VariantCard extends StatefulWidget {
  final GameVariant variant;
  final bool selected;
  final VoidCallback onTap;

  const _VariantCard({
    required this.variant,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_VariantCard> createState() => _VariantCardState();
}

class _VariantCardState extends State<_VariantCard> {
  bool _pressed = false;

  IconData get _mechanicIcon => switch (widget.variant.mechanicFamily) {
        MechanicFamily.hitting => Icons.gavel,
        MechanicFamily.pinning => Icons.push_pin,
        MechanicFamily.running => Icons.directions_run,
      };

  String get _mechanicLabel => switch (widget.variant.mechanicFamily) {
        MechanicFamily.hitting => 'Hit & run',
        MechanicFamily.pinning => 'Trap & pin',
        MechanicFamily.running => 'Race & block',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = widget.selected;
    final bg = _pressed
        ? (selected ? TavliColors.primaryActive : TavliColors.surfaceActive)
        : (selected ? TavliColors.primary : TavliColors.surface);
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '${widget.variant.displayName} — ${widget.variant.mechanicFamily.displayName}',
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: ReducedMotion.duration(context, const Duration(milliseconds: 150)),
            curve: Curves.easeInOut,
            transform: _pressed
                ? Matrix4.diagonal3Values(0.98, 0.98, 1.0)
                : Matrix4.identity(),
            transformAlignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              vertical: TavliSpacing.md,
              horizontal: TavliSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(TavliRadius.lg),
              border: Border.all(
                color: selected ? TavliColors.background : TavliColors.primary,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected ? TavliShadows.xsmall : null,
            ),
            child: Column(
              children: [
                Icon(
                  _mechanicIcon,
                  size: 24,
                  color: selected ? TavliColors.light : TavliColors.disabledOnPrimary,
                ),
                const SizedBox(height: TavliSpacing.xs),
                Text(
                  widget.variant.nativeName,
                  style: theme.textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected ? TavliColors.light : TavliColors.disabledOnPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: TavliSpacing.xxxs),
                Text(
                  _mechanicLabel,
                  style: theme.textTheme.labelSmall!.copyWith(
                    color: selected ? TavliColors.light : TavliColors.disabledOnPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Explore other traditions module.
class _ExploreTraditionsCard extends StatelessWidget {
  final Tradition currentTradition;
  final ValueChanged<Tradition> onTraditionTap;

  const _ExploreTraditionsCard({
    required this.currentTradition,
    required this.onTraditionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final otherTraditions =
        Tradition.values.where((t) => t != currentTradition).toList();

    return ContentModule(
      icon: Icons.explore_outlined,
      title: 'Explore Other Traditions',
      body: 'Backgammon is played differently around the world. Try another style!',
      child: Row(
        children: [
          for (int i = 0; i < otherTraditions.length; i++) ...[
            if (i > 0) const SizedBox(width: TavliSpacing.sm),
            Expanded(
              child: GestureDetector(
                onTap: () => onTraditionTap(otherTraditions[i]),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: TavliSpacing.sm,
                    horizontal: TavliSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: TavliColors.background.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(TavliRadius.md),
                    border: Border.all(
                        color: TavliColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        otherTraditions[i].flagEmoji,
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: TavliSpacing.xxs),
                      Text(
                        otherTraditions[i].displayName,
                        style: theme.textTheme.labelMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: TavliColors.light,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
