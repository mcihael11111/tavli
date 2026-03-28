import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/theme.dart';
import '../../../core/constants/colors.dart';
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
        duration: const Duration(milliseconds: 400),
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
                          duration: const Duration(milliseconds: 200),
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
                            style: TextStyle(
                              fontFamily: TavliTheme.serifFamily,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
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
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: TavliSpacing.xl),
          Text(
            'Tables',
            style: TextStyle(
              color: TavliColors.light,
              fontSize: 32,
              fontFamily: TavliTheme.serifFamily,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.64,
              height: 1.25,
            ),
          ),
          const SizedBox(height: TavliSpacing.sm),
          const Text(
            'Backgammon Traditions',
            style: TextStyle(
              color: TavliColors.light,
              fontSize: 20,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TavliSpacing.xxs),
          const Text(
            'One game. Many cultures.\n'
            'Choose your tradition and play the way\n'
            'your family taught you.',
            style: TextStyle(
              color: TavliColors.light,
              fontSize: 16,
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
            style: TextStyle(
              color: TavliColors.light,
              fontSize: 32,
              fontFamily: TavliTheme.serifFamily,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.64,
              height: 1.25,
            ),
          ),
          const SizedBox(height: TavliSpacing.sm),
          const Text(
            'This is how others see you\nin online games.',
            style: TextStyle(
              color: TavliColors.light,
              fontSize: 18,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: TavliSpacing.lg),
          Text(
            '5,000 Years of Play',
            style: TextStyle(
              color: TavliColors.light,
              fontSize: 32,
              fontFamily: TavliTheme.serifFamily,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: TavliSpacing.lg),
          Text(
            'Where Do You Play?',
            style: TextStyle(
              color: TavliColors.light,
              fontSize: 32,
              fontFamily: TavliTheme.serifFamily,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.64,
              height: 1.25,
            ),
          ),
          const SizedBox(height: TavliSpacing.sm),
          const Text(
            'Each tradition has its own variants,\nopponents, and atmosphere.',
            style: TextStyle(
              color: TavliColors.light,
              fontSize: 18,
              height: 1.4,
            ),
          ),
          const SizedBox(height: TavliSpacing.xl),

          // Tradition list.
          Expanded(
            child: ListView(
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
                        style: const TextStyle(fontSize: 28)),
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
            style: TextStyle(
              color: TavliColors.light,
              fontSize: 32,
              fontFamily: TavliTheme.serifFamily,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.64,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TavliSpacing.sm),
          const Text(
            'You can change this anytime in Settings.',
            style: TextStyle(
              color: TavliColors.light,
              fontSize: 18,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TavliSpacing.xl),

          Expanded(
            child: ListView(
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
                          style: const TextStyle(
                            fontSize: 21,
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
    final isSelected = widget.selected;

    final bg = _pressed
        ? (isSelected ? TavliColors.primaryActive : TavliColors.surfaceActive)
        : (isSelected ? TavliColors.primary : TavliColors.surface);
    final border =
        isSelected ? TavliColors.background : TavliColors.primary;
    final borderWidth = isSelected ? 2.0 : 1.0;
    final textColor = TavliColors.light.withValues(alpha: isSelected ? 1.0 : 0.7);

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
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
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontFamily: TavliTheme.serifFamily,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (widget.titleTrailing != null) ...[
                        const SizedBox(width: TavliSpacing.xs),
                        Text(
                          widget.titleTrailing!,
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: TavliSpacing.xxs),
                    Text(
                      widget.subtitle!,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                  if (widget.detail != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.detail!,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontSize: 12,
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
    );
  }
}

// ─── Screen 5: Language Level (Tradition-Adapted) ────────────────

class _LanguageLevelPage extends StatefulWidget {
  @override
  State<_LanguageLevelPage> createState() => _LanguageLevelPageState();
}

class _LanguageLevelPageState extends State<_LanguageLevelPage> {
  double _level = SettingsService.instance.languageLevel;

  String get _title {
    final tradition = SettingsService.instance.tradition;
    return switch (tradition) {
      Tradition.tavli => 'How Greek Should I Be?',
      Tradition.tavla => 'How Turkish Should I Be?',
      Tradition.nardy => 'How Russian Should I Be?',
      Tradition.sheshBesh => 'How Much Local Flavor?',
    };
  }

  String get _subtitle {
    final tradition = SettingsService.instance.tradition;
    return switch (tradition) {
      Tradition.tavli => 'Adjust the amount of Greek I use.',
      Tradition.tavla => 'Adjust the amount of Turkish I use.',
      Tradition.nardy => 'Adjust the amount of Russian I use.',
      Tradition.sheshBesh => 'Adjust the mix of Hebrew and Arabic.',
    };
  }

  String get _fluentLabel {
    final tradition = SettingsService.instance.tradition;
    return switch (tradition) {
      Tradition.tavli => 'Fluent Greek',
      Tradition.tavla => 'Fluent Turkish',
      Tradition.nardy => 'Fluent Russian',
      Tradition.sheshBesh => 'Full Immersion',
    };
  }

  List<_LangExample> get _examples {
    final tradition = SettingsService.instance.tradition;
    return switch (tradition) {
      Tradition.tavli => const [
          _LangExample('Ready to play', 'Michael will lose'),
          _LangExample('Έτοιμο to play', 'Michael θα lose'),
          _LangExample('Έτοιμο να παίξει', 'Ο Michael θα χάσει'),
          _LangExample('Έτοιμο να παίξει', 'Ο Μάικλ θα χάσει'),
          _LangExample('Έτοιμο να παίξει', 'Ο Μάικλ θα χάσει'),
        ],
      Tradition.tavla => const [
          _LangExample('Ready to play', 'Good roll!'),
          _LangExample('Hazır to play', 'Güzel roll!'),
          _LangExample('Hazır oynamaya', 'Güzel atış!'),
          _LangExample('Hazır oynamaya', 'Güzel atış, maşallah!'),
          _LangExample('Hazır oynamaya', 'Güzel atış, maşallah!'),
        ],
      Tradition.nardy => const [
          _LangExample('Ready to play', 'Nice move!'),
          _LangExample('Готов to play', 'Хороший move!'),
          _LangExample('Готов играть', 'Хороший ход!'),
          _LangExample('Готов играть', 'Отличный ход, молодец!'),
          _LangExample('Готов играть', 'Отличный ход, молодец!'),
        ],
      Tradition.sheshBesh => const [
          _LangExample('Ready to play', 'Good move!'),
          _LangExample('מוכן to play', 'Good move, yalla!'),
          _LangExample('מוכן לשחק', '!יאללה, מהלך טוב'),
          _LangExample('מוכן לשחק', '!יאללה, מהלך מעולה'),
          _LangExample('מוכן לשחק', '!יאללה, מהלך מעולה'),
        ],
    };
  }

  _LangExample get _currentExample {
    final idx = (_level * (_examples.length - 1)).round();
    return _examples[idx];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: TavliSpacing.lg),
          Text(
            _title,
            style: TextStyle(
              color: TavliColors.light,
              fontSize: 32,
              fontFamily: TavliTheme.serifFamily,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.64,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TavliSpacing.sm),
          Text(
            _subtitle,
            style: const TextStyle(
              color: TavliColors.light,
              fontSize: 18,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          // Slider with endpoint labels.
          Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: TavliColors.background,
                  inactiveTrackColor: TavliColors.background,
                  thumbColor: TavliColors.background,
                  overlayColor:
                      TavliColors.background.withValues(alpha: 0.2),
                  trackHeight: 4,
                  thumbShape: _LangSliderThumb(),
                ),
                child: Slider(
                  value: _level,
                  divisions: 4,
                  onChanged: (v) {
                    setState(() => _level = v);
                    SettingsService.instance.languageLevel = v;
                  },
                ),
              ),
              const SizedBox(height: TavliSpacing.sm),

              // Labels.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'English Only',
                          style: TextStyle(
                            color: TavliColors.light,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: TavliSpacing.xxs),
                        Text(
                          "Can't read the script",
                          style: TextStyle(
                            color: TavliColors.background,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _fluentLabel,
                          style: const TextStyle(
                            color: TavliColors.light,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: TavliSpacing.xxs),
                        const Text(
                          'Can read and write',
                          style: TextStyle(
                            color: TavliColors.background,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: TavliSpacing.md),

              // Example card.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(TavliSpacing.sm),
                decoration: BoxDecoration(
                  color: TavliColors.surface,
                  borderRadius: BorderRadius.circular(TavliRadius.md),
                  border: Border.all(color: TavliColors.primary),
                  boxShadow: TavliShadows.xsmall,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Example',
                      style: TextStyle(
                        color: TavliColors.background,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: TavliSpacing.xs),
                    Text(
                      _currentExample.line1,
                      style: const TextStyle(
                        color: TavliColors.text,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: TavliSpacing.xxs),
                    Text(
                      _currentExample.line2,
                      style: const TextStyle(
                        color: TavliColors.text,
                        fontSize: 14,
                        height: 1.57,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _LangSliderThumb extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(28, 28);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    canvas.drawCircle(
      center,
      14,
      Paint()
        ..color = TavliColors.background
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      14,
      Paint()
        ..color = TavliColors.text
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawCircle(
      center,
      6,
      Paint()..color = TavliColors.text,
    );
  }
}

class _LangExample {
  final String line1;
  final String line2;
  const _LangExample(this.line1, this.line2);
}

// ─── Screen 7: Ready to Play ────────────────────────────────────

class _ReadyPage extends StatelessWidget {
  final VoidCallback onLearn;
  const _ReadyPage({required this.onLearn});

  @override
  Widget build(BuildContext context) {
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
                style: TextStyle(
                  fontSize: 44,
                  fontFamily: TavliTheme.serifFamily,
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
            style: TextStyle(
              color: TavliColors.light,
              fontSize: 32,
              fontFamily: TavliTheme.serifFamily,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.64,
              height: 1.25,
            ),
          ),
          const SizedBox(height: TavliSpacing.sm),
          Text(
            'Play ${tradition.displayName} against ${personality.displayName}, '
            'challenge friends online or learn the game with an interactive tool',
            style: const TextStyle(
              color: TavliColors.light,
              fontSize: 20,
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
                  style: TextStyle(
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
                style: TextStyle(
                  fontFamily: TavliTheme.serifFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
