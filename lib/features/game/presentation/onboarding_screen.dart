import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/providers/accessibility_providers.dart';
import '../../../core/constants/tradition.dart';
import '../../../shared/services/settings_service.dart';
import '../../../shared/widgets/content_module.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import '../../ai/personality/bot_personality.dart';

/// First-launch onboarding — 7 screens, skippable.
///
/// Screen 1: Welcome to Tables
/// Screen 2: What should we call you? (username)
/// Screen 3: 5,000 Years of Play (history)
/// Screen 4: Choose your tradition
/// Screen 5: How [tradition] should I be (language level slider)
/// Screen 6: Choose your opponent (personality)
/// Screen 7: Ready to play
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  /// Check if onboarding has been completed.
  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    // Check both old and new keys for backward compat.
    return prefs.getBool('tables_onboarding_done') ??
        prefs.getBool('tavli_onboarding_done') ??
        false;
  }

  /// Mark onboarding as completed.
  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tables_onboarding_done', true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;
  static const _pageCount = 7;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pageCount - 1) {
      _controller.nextPage(
        duration: ReducedMotion.duration(context, const Duration(milliseconds: 400)),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    OnboardingScreen.markCompleted();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return GradientScaffold(
      body: Stack(
        children: [
          // Pages (full screen — content scrolls behind the footer).
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _controller,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      children: [
                        _WelcomePage(),
                        _UsernamePage(),
                        _HistoryPage(),
                        _TraditionPickPage(onChanged: () => setState(() {})),
                        _LanguageLevelPage(),
                        _PersonalityPickPage(),
                        _ReadyPage(onLearn: () {
                          _finish();
                          context.push('/learn');
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating frosted glass footer — dots + button.
          Positioned(
            left: TavliSpacing.md,
            right: TavliSpacing.md,
            bottom: bottomPadding + TavliSpacing.sm,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(TavliRadius.xl),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    TavliSpacing.md,
                    TavliSpacing.sm,
                    TavliSpacing.sm,
                    TavliSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: TavliColors.background.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(TavliRadius.xl),
                    border: Border.all(
                      color: TavliColors.light.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Pagination dots.
                      for (int i = 0; i < _pageCount; i++)
                        AnimatedContainer(
                          duration: ReducedMotion.duration(context, const Duration(milliseconds: 200)),
                          curve: Curves.easeInOut,
                          width: _currentPage == i ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: _currentPage == i
                                ? TavliColors.light
                                : TavliColors.light.withValues(alpha: 0.4),
                            borderRadius:
                                BorderRadius.circular(TavliRadius.full),
                          ),
                        ),
                      const Spacer(),
                      // Next / Get Started button.
                      SizedBox(
                        height: 44,
                        child: FilledButton(
                          onPressed: _next,
                          style: FilledButton.styleFrom(
                            backgroundColor: TavliColors.background,
                            foregroundColor: TavliColors.primary,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: TavliSpacing.lg,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(TavliRadius.lg),
                            ),
                          ),
                          child: Text(
                            _currentPage < _pageCount - 1
                                ? 'Next'
                                : 'Get Started',
                            style: theme.textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Screen 1: Welcome ─────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Geometric logo placeholder.
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TavliColors.surface,
              border: Border.all(color: TavliColors.primary),
            ),
            child: Center(
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    border: Border.all(color: TavliColors.primary, width: 2),
                    borderRadius: BorderRadius.circular(TavliRadius.xs),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: TavliSpacing.xl),
          Text(
            'Tables',
            style: theme.textTheme.displayMedium!.copyWith(
              color: TavliColors.light,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.64,
              height: 1.25,
            ),
          ),
          const SizedBox(height: TavliSpacing.sm),
          Text(
            'Backgammon Traditions',
            style: theme.textTheme.headlineMedium!.copyWith(
              color: TavliColors.light,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TavliSpacing.xxs),
          Text(
            'One game. Many cultures.\n'
            'Choose your tradition and play the way\n'
            'your family taught you.',
            style: theme.textTheme.bodyLarge!.copyWith(
              color: TavliColors.light,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Screen 2: Username ─────────────────────────────────────────

class _UsernamePage extends StatefulWidget {
  @override
  State<_UsernamePage> createState() => _UsernamePageState();
}

class _UsernamePageState extends State<_UsernamePage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: SettingsService.instance.playerDisplayName,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: TavliSpacing.lg),
          Text(
            'What Should We\nCall You?',
            style: theme.textTheme.displayMedium!.copyWith(
              color: TavliColors.light,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.64,
              height: 1.25,
            ),
          ),
          const SizedBox(height: TavliSpacing.sm),
          Text(
            'This is how others see you\nin online games.',
            style: theme.textTheme.titleLarge!.copyWith(
              color: TavliColors.light,
              height: 1.4,
            ),
          ),
          const SizedBox(height: TavliSpacing.xl),
          TextField(
            controller: _controller,
            maxLength: 20,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: TavliColors.text,
            ),
            decoration: InputDecoration(
              hintText: 'Enter your name',
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: TavliColors.text.withValues(alpha: 0.6),
              ),
              filled: true,
              fillColor: TavliColors.surface,
              counterStyle: const TextStyle(color: TavliColors.light),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TavliRadius.sm),
                borderSide: const BorderSide(color: TavliColors.primary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TavliRadius.sm),
                borderSide:
                    const BorderSide(color: TavliColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: TavliSpacing.md,
                vertical: TavliSpacing.sm,
              ),
            ),
            onChanged: (value) {
              SettingsService.instance.playerDisplayName = value.trim();
            },
          ),
        ],
      ),
    );
  }
}

// ─── Screen 3: History of Tables ────────────────────────────────

class _HistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: TavliSpacing.lg),
          Text(
            '5,000 Years of Play',
            style: theme.textTheme.displayMedium!.copyWith(
              color: TavliColors.light,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.64,
              height: 1.25,
            ),
          ),
          const SizedBox(height: TavliSpacing.lg),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: const [
                ContentModule(
                  icon: Icons.temple_buddhist_outlined,
                  title: 'Ancient Origins',
                  body: 'In ancient Mesopotamia, around 3000 BCE, the Royal '
                      'Game of Ur was carved into stone \u2014 the oldest '
                      'ancestor of every backgammon board. In Egypt, Senet '
                      'was buried with pharaohs for the afterlife.',
                ),
                SizedBox(height: TavliSpacing.sm),
                ContentModule(
                  icon: Icons.explore_outlined,
                  title: 'The Silk Road Spread',
                  body: 'The game traveled with traders, soldiers, and '
                      'sailors. The Romans called it Tabula. The Persians '
                      'called it Takht\u2011e\u00A0Nard. In medieval Europe '
                      'it became "Tables" \u2014 the name that stuck for '
                      'centuries.',
                ),
                SizedBox(height: TavliSpacing.sm),
                ContentModule(
                  icon: Icons.local_cafe_outlined,
                  title: 'The Coffeehouse Era',
                  body: 'From the 17th century, coffeehouses across the '
                      'Ottoman Empire and Europe became the heart of the '
                      'game. Greek kafeneia, Turkish kahvehane, and '
                      'Viennese kaffeehaus \u2014 every culture had its table.',
                ),
                SizedBox(height: TavliSpacing.sm),
                ContentModule(
                  icon: Icons.shield_outlined,
                  title: 'Through the Wars',
                  body: 'During both World Wars, soldiers carried pocket '
                      'backgammon sets in their kits. In prisoner-of-war '
                      'camps, boards were scratched into floors and tables. '
                      'The game was a thread of normalcy in chaos.',
                ),
                SizedBox(height: TavliSpacing.sm),
                ContentModule(
                  icon: Icons.flag_outlined,
                  title: 'Living Traditions',
                  body: 'Today, the same game lives in kafeneia in Athens, '
                      'tea houses in Istanbul, dachas outside Moscow, and '
                      'shuk stalls in Jerusalem. Same board. Same dice. '
                      'Different names, different rules, different souls.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Screen 4: Tradition Selection ──────────────────────────────

class _TraditionPickPage extends StatefulWidget {
  final VoidCallback onChanged;
  const _TraditionPickPage({required this.onChanged});

  @override
  State<_TraditionPickPage> createState() => _TraditionPickPageState();
}

class _TraditionPickPageState extends State<_TraditionPickPage> {
  Tradition _selected = SettingsService.instance.tradition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: TavliSpacing.lg),
          Text(
            'Where Do You Play?',
            style: theme.textTheme.displayMedium!.copyWith(
              color: TavliColors.light,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.64,
              height: 1.25,
            ),
          ),
          const SizedBox(height: TavliSpacing.sm),
          Text(
            'Each tradition has its own variants,\nopponents, and atmosphere.',
            style: theme.textTheme.titleLarge!.copyWith(
              color: TavliColors.light,
              height: 1.4,
            ),
          ),
          const SizedBox(height: TavliSpacing.xl),

          // Tradition list.
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: TavliSpacing.xxl + 24),
              children: [
                for (final tradition in Tradition.values) ...[
                  _SelectionCard(
                    selected: _selected == tradition,
                    onTap: () {
                      setState(() => _selected = tradition);
                      SettingsService.instance.tradition = tradition;
                      // Reset personality to tradition default.
                      SettingsService.instance.botPersonality =
                          BotPersonality.defaultFor(tradition);
                      widget.onChanged();
                    },
                    leading: Text(tradition.flagEmoji,
                        style: theme.textTheme.displaySmall),
                    title: tradition.displayName,
                    titleTrailing: tradition.nativeName,
                    subtitle:
                        '${tradition.regionLabel} · ${tradition.variants.length} games',
                    detail: tradition.variants
                        .map((v) => v.displayName)
                        .join(' · '),
                  ),
                  const SizedBox(height: TavliSpacing.sm),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Screen 6: Personality Selection ────────────────────────────

class _PersonalityPickPage extends StatefulWidget {
  @override
  State<_PersonalityPickPage> createState() => _PersonalityPickPageState();
}

class _PersonalityPickPageState extends State<_PersonalityPickPage> {
  BotPersonality _selected = SettingsService.instance.botPersonality;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tradition = SettingsService.instance.tradition;
    final personalities = BotPersonality.forTradition(tradition);

    // If current selection doesn't match tradition, reset.
    if (_selected.tradition != tradition) {
      _selected = BotPersonality.defaultFor(tradition);
      SettingsService.instance.botPersonality = _selected;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
      child: Column(
        children: [
          const SizedBox(height: TavliSpacing.lg),
          Text(
            'Choose Your Opponent',
            style: theme.textTheme.displayMedium!.copyWith(
              color: TavliColors.light,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.64,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TavliSpacing.sm),
          Text(
            'You can change this anytime in Settings.',
            style: theme.textTheme.titleLarge!.copyWith(
              color: TavliColors.light,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TavliSpacing.xl),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: TavliSpacing.xxl + 24),
              children: [
                for (final personality in personalities) ...[
                  _SelectionCard(
                    selected: _selected == personality,
                    onTap: () {
                      setState(() => _selected = personality);
                      SettingsService.instance.botPersonality = personality;
                    },
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: TavliColors.surface,
                      ),
                      child: Center(
                        child: Text(
                          personality.avatarInitial,
                          style: theme.textTheme.headlineMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: TavliColors.light,
                          ),
                        ),
                      ),
                    ),
                    title: personality.displayName,
                    subtitle: personality.subtitle,
                  ),
                  const SizedBox(height: TavliSpacing.sm),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Selection Card ──────────────────────────────────────

class _SelectionCard extends StatefulWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  final String title;
  final String? titleTrailing;
  final String? subtitle;
  final String? detail;

  const _SelectionCard({
    required this.selected,
    required this.onTap,
    this.leading,
    required this.title,
    this.titleTrailing,
    this.subtitle,
    this.detail,
  });

  @override
  State<_SelectionCard> createState() => _SelectionCardState();
}

class _SelectionCardState extends State<_SelectionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = widget.selected;

    final bg = _pressed
        ? (isSelected ? TavliColors.primaryActive : TavliColors.surfaceActive)
        : (isSelected ? TavliColors.primary : TavliColors.surface);
    final border =
        isSelected ? TavliColors.background : TavliColors.primary;
    final borderWidth = isSelected ? 2.0 : 1.0;
    final textColor = TavliColors.light.withValues(alpha: isSelected ? 1.0 : 0.7);

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Select ${widget.title}',
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: ReducedMotion.duration(context, const Duration(milliseconds: 100)),
          curve: Curves.easeIn,
          transform: _pressed
              ? Matrix4.diagonal3Values(0.98, 0.98, 1.0)
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.all(TavliSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TavliRadius.lg),
            color: bg,
            border: Border.all(color: border, width: borderWidth),
            boxShadow: isSelected ? TavliShadows.xsmall : null,
          ),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: TavliSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.titleLarge!.copyWith(
                            color: textColor,
                          ),
                        ),
                        if (widget.titleTrailing != null) ...[
                          const SizedBox(width: TavliSpacing.xs),
                          Text(
                            widget.titleTrailing!,
                            style: theme.textTheme.bodyMedium!.copyWith(
                              color: textColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: TavliSpacing.xxs),
                      Text(
                        widget.subtitle!,
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: textColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                    if (widget.detail != null) ...[
                      const SizedBox(height: TavliSpacing.xxxs),
                      Text(
                        widget.detail!,
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: TavliColors.light,
                    size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Screen 5: Language Level (Tradition-Adapted) ────────────────

class _LanguageLevelPage extends StatefulWidget {
  @override
  State<_LanguageLevelPage> createState() => _LanguageLevelPageState();
}

class _LanguageLevelPageState extends State<_LanguageLevelPage> {
  LanguageTier _tier = SettingsService.instance.languageTier;

  Tradition get _tradition => SettingsService.instance.tradition;

  /// Example pairs per tradition: English and native heading/body.
  ({String engHeading, String natHeading, String engBody, String natBody})
      get _example => switch (_tradition) {
            Tradition.tavli => (
                engHeading: 'Play vs Bot',
                natHeading: 'Παίξε με Bot',
                engBody: 'Challenge the AI opponent',
                natBody: 'Πρόκληση εναντίον AI',
              ),
            Tradition.tavla => (
                engHeading: 'Play Online',
                natHeading: 'Online Oyna',
                engBody: 'Quick match or invite a friend',
                natBody: 'Hızlı maç veya arkadaş davet et',
              ),
            Tradition.nardy => (
                engHeading: 'Learn to Play',
                natHeading: 'Учитесь играть',
                engBody: 'Interactive tutorial',
                natBody: 'Интерактивное обучение',
              ),
            Tradition.sheshBesh => (
                engHeading: 'My Collection',
                natHeading: 'האוסף שלי',
                engBody: 'Boards, checkers, and dice sets',
                natBody: 'לוחות, כלים וקוביות',
              ),
            Tradition.tawla => (
                engHeading: 'Play vs Bot',
                natHeading: 'العب ضد البوت',
                engBody: 'Challenge the AI opponent',
                natBody: 'تحدّى الذكاء الاصطناعي',
              ),
          };

  void _select(LanguageTier tier) {
    setState(() => _tier = tier);
    SettingsService.instance.languageLevel = tier.value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = _tradition.languageName;
    final ex = _example;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: TavliSpacing.lg + TavliSpacing.sm),
          Text(
            'How $lang Should I Be?',
            style: theme.textTheme.displayMedium!.copyWith(
              color: TavliColors.light,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.64,
              height: 1.25,
            ),
          ),
          const SizedBox(height: TavliSpacing.sm),
          Text(
            'Choose how much $lang to mix in.',
            style: theme.textTheme.titleLarge!.copyWith(
              color: TavliColors.light,
              height: 1.4,
            ),
          ),

          const SizedBox(height: TavliSpacing.lg),

          // Three tier cards.
          _LanguageTierCard(
            selected: _tier == LanguageTier.english,
            onTap: () => _select(LanguageTier.english),
            label: 'English',
            description: 'Everything in English',
            heading: ex.engHeading,
            body: ex.engBody,
          ),
          const SizedBox(height: TavliSpacing.sm),
          _LanguageTierCard(
            selected: _tier == LanguageTier.mixed,
            onTap: () => _select(LanguageTier.mixed),
            label: 'Mixed',
            description: 'Headings in $lang, body in English',
            heading: ex.natHeading,
            body: ex.engBody,
          ),
          const SizedBox(height: TavliSpacing.sm),
          _LanguageTierCard(
            selected: _tier == LanguageTier.fluent,
            onTap: () => _select(LanguageTier.fluent),
            label: 'Fluent $lang',
            description: 'Everything in $lang',
            heading: ex.natHeading,
            body: ex.natBody,
          ),

          const Spacer(),
        ],
      ),
    );
  }
}

/// A single language tier option card with example preview.
class _LanguageTierCard extends StatefulWidget {
  final bool selected;
  final VoidCallback onTap;
  final String label;
  final String description;
  final String heading;
  final String body;

  const _LanguageTierCard({
    required this.selected,
    required this.onTap,
    required this.label,
    required this.description,
    required this.heading,
    required this.body,
  });

  @override
  State<_LanguageTierCard> createState() => _LanguageTierCardState();
}

class _LanguageTierCardState extends State<_LanguageTierCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = widget.selected;

    final bg = _pressed
        ? (isSelected ? TavliColors.primaryActive : TavliColors.surfaceActive)
        : (isSelected ? TavliColors.primary : TavliColors.surface);
    final border = isSelected ? TavliColors.background : TavliColors.primary;
    final borderWidth = isSelected ? 2.0 : 1.0;
    final textColor =
        TavliColors.light.withValues(alpha: isSelected ? 1.0 : 0.7);

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Select ${widget.label} language level',
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: ReducedMotion.duration(context, const Duration(milliseconds: 100)),
          curve: Curves.easeIn,
          transform: _pressed
              ? Matrix4.diagonal3Values(0.98, 0.98, 1.0)
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          padding: const EdgeInsets.all(TavliSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TavliRadius.lg),
            color: bg,
            border: Border.all(color: border, width: borderWidth),
            boxShadow: isSelected ? TavliShadows.xsmall : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: label + check icon.
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.label,
                      style: theme.textTheme.titleMedium!.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: TavliColors.light,
                        size: 20),
                ],
              ),

              // Description.
              const SizedBox(height: TavliSpacing.xxs),
              Text(
                widget.description,
                style: theme.textTheme.bodySmall!.copyWith(
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),

              // Divider.
              Padding(
                padding: const EdgeInsets.symmetric(vertical: TavliSpacing.xs),
                child: Divider(
                  height: 1,
                  color: textColor.withValues(alpha: 0.15),
                ),
              ),

              // Example preview.
              Text(
                widget.heading,
                style: theme.textTheme.titleMedium!.copyWith(
                  color: textColor,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: TavliSpacing.xxxs),
              Text(
                widget.body,
                style: theme.textTheme.bodySmall!.copyWith(
                  color: textColor.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Screen 7: Ready to Play ────────────────────────────────────

class _ReadyPage extends StatelessWidget {
  final VoidCallback onLearn;
  const _ReadyPage({required this.onLearn});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final personality = SettingsService.instance.botPersonality;
    final tradition = SettingsService.instance.tradition;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar with border.
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TavliColors.surface,
              border: Border.all(color: TavliColors.primary),
            ),
            child: Center(
              child: Text(
                personality.avatarInitial,
                style: theme.textTheme.displayLarge!.copyWith(
                  fontSize: 44,
                  fontWeight: FontWeight.w400,
                  color: TavliColors.light,
                  letterSpacing: -0.88,
                ),
              ),
            ),
          ),
          const SizedBox(height: TavliSpacing.lg),
          Text(
            'Ready to play',
            style: theme.textTheme.displayMedium!.copyWith(
              color: TavliColors.light,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.64,
              height: 1.25,
            ),
          ),
          const SizedBox(height: TavliSpacing.sm),
          Text(
            'Play ${tradition.displayName} against ${personality.displayName}, '
            'challenge friends online or learn the game with an interactive tool',
            style: theme.textTheme.headlineMedium!.copyWith(
              color: TavliColors.light,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TavliSpacing.md),
          // Shop teaser.
          Container(
            padding: const EdgeInsets.all(TavliSpacing.sm),
            decoration: BoxDecoration(
              color: TavliColors.background.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(TavliRadius.md),
              border: Border.all(
                color: TavliColors.primary.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storefront, color: TavliColors.light,
                    size: 18),
                const SizedBox(width: TavliSpacing.xs),
                Text(
                  'Visit the Shop to unlock boards, dice & more',
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: TavliColors.light.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TavliSpacing.lg),
          // Learn to Play button — proper OutlinedButton.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onLearn,
              style: OutlinedButton.styleFrom(
                foregroundColor: TavliColors.light,
                backgroundColor: TavliColors.background.withValues(alpha: 0.15),
                side: BorderSide(color: TavliColors.light.withValues(alpha: 0.4)),
              ),
              icon: const Icon(Icons.school_outlined, size: 20),
              label: Text(
                'Learn to Play',
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
