import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/theme.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/tradition.dart';
import '../../../shared/services/settings_service.dart';
import '../../ai/personality/bot_personality.dart';

/// First-launch onboarding — 6 screens, skippable.
///
/// Screen 1: Welcome to Tables
/// Screen 2: Choose your tradition
/// Screen 3: Choose your board style (card carousel)
/// Screen 4: Choose your opponent (personality)
/// Screen 5: How [tradition] should I be (language level slider)
/// Screen 6: Ready to play
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
  static const _pageCount = 6;

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
    return Scaffold(
      backgroundColor: TavliColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button.
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip',
                  style: TextStyle(color: TavliColors.light, fontSize: 14)),
              ),
            ),

            // Pages.
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _WelcomePage(),
                  _TraditionPickPage(onChanged: () => setState(() {})),
                  _BoardPickPage(),
                  _PersonalityPickPage(),
                  _LanguageLevelPage(),
                  _ReadyPage(onLearn: () {
                    _finish();
                    context.push('/tutorial');
                  }),
                ],
              ),
            ),

            // Indicators + next button.
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TavliSpacing.md,
                vertical: TavliSpacing.xl,
              ),
              child: Row(
                children: [
                  // Dots.
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        for (int i = 0; i < _pageCount; i++) ...[
                          Container(
                            width: _currentPage == i ? 52 : 14,
                            height: 14,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: _currentPage == i
                                  ? TavliColors.light
                                  : TavliColors.primary,
                              borderRadius: BorderRadius.circular(TavliRadius.full),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Next / Get Started.
                  ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TavliColors.primary,
                      foregroundColor: TavliColors.light,
                      padding: const EdgeInsets.symmetric(
                        horizontal: TavliSpacing.sm,
                        vertical: TavliSpacing.xs,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(TavliRadius.sm),
                      ),
                    ),
                    child: Text(
                      _currentPage < _pageCount - 1 ? 'Next' : 'Get Started',
                      style: TextStyle(
                        fontFamily: TavliTheme.serifFamily,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

// ─── Screen 2: Tradition Selection ──────────────────────────────

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
                  _TraditionChoice(
                    tradition: tradition,
                    selected: _selected == tradition,
                    onTap: () {
                      setState(() => _selected = tradition);
                      SettingsService.instance.tradition = tradition;
                      // Reset personality to tradition default.
                      SettingsService.instance.botPersonality =
                          BotPersonality.defaultFor(tradition);
                      widget.onChanged();
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TraditionChoice extends StatelessWidget {
  final Tradition tradition;
  final bool selected;
  final VoidCallback onTap;

  const _TraditionChoice({
    required this.tradition,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(TavliSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TavliRadius.lg),
          color: TavliColors.background,
          border: Border.all(color: TavliColors.primary),
          boxShadow: TavliShadows.xsmall,
        ),
        child: Row(
          children: [
            Text(tradition.flagEmoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: TavliSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(tradition.displayName, style: TextStyle(
                        color: TavliColors.primary, fontSize: 18,
                        fontFamily: TavliTheme.serifFamily, fontWeight: FontWeight.w500,
                      )),
                      const SizedBox(width: TavliSpacing.xs),
                      Text(tradition.nativeName, style: const TextStyle(
                        color: TavliColors.primary, fontSize: 14,
                      )),
                    ],
                  ),
                  const SizedBox(height: TavliSpacing.xxs),
                  Text(
                    '${tradition.regionLabel} · ${tradition.variants.length} games',
                    style: const TextStyle(color: TavliColors.primary, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tradition.variants.map((v) => v.displayName).join(' · '),
                    style: const TextStyle(color: TavliColors.primary, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: TavliColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}

// ─── Screen 3: Board Selection (Card Carousel) ─────────────────

class _BoardPickPage extends StatefulWidget {
  @override
  State<_BoardPickPage> createState() => _BoardPickPageState();
}

class _BoardPickPageState extends State<_BoardPickPage> {
  int _selected = 1;
  late final PageController _carouselController;

  @override
  void initState() {
    super.initState();
    _carouselController = PageController(viewportFraction: 0.72);
  }

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  List<_BoardInfo> get _boards {
    final tradition = SettingsService.instance.tradition;
    return switch (tradition) {
      Tradition.tavli => const [
        _BoardInfo(1, 'Μαόνι', 'Mahogany & Olive Wood', [Color(0xFF8B4513), Color(0xFFC8B560)]),
        _BoardInfo(2, 'Σμαραγδί', 'Mahogany & Teal', [Color(0xFF6F3024), Color(0xFF1A5C5C)]),
        _BoardInfo(3, 'Νυχτερινό', 'Dark Walnut & Navy', [Color(0xFF2A1A0E), Color(0xFF2C3E50)]),
      ],
      Tradition.tavla => const [
        _BoardInfo(1, 'Sultanahmet', 'Warm Cedar & Crimson', [Color(0xFF8B4513), Color(0xFF8B2500)]),
        _BoardInfo(2, 'Anadolu', 'Light Ash & Turquoise', [Color(0xFFA0856C), Color(0xFF1A8B8B)]),
        _BoardInfo(3, 'İstanbuli', 'Dark Walnut & Gold', [Color(0xFF2A1A0E), Color(0xFFB8860B)]),
      ],
      Tradition.nardy => const [
        _BoardInfo(1, 'Кавказ', 'Light Birch & Burgundy', [Color(0xFFC4A882), Color(0xFF722F37)]),
        _BoardInfo(2, 'Москва', 'Dark Oak & Forest Green', [Color(0xFF4A3728), Color(0xFF2E5A3E)]),
        _BoardInfo(3, 'Баку', 'Rosewood & Copper', [Color(0xFF65000B), Color(0xFFB87333)]),
      ],
      Tradition.sheshBesh => const [
        _BoardInfo(1, 'ירושלים', 'Olive Wood & Sandstone', [Color(0xFF808000), Color(0xFFD2B48C)]),
        _BoardInfo(2, 'السوق', 'Mother-of-Pearl Inlay', [Color(0xFF3B2F2F), Color(0xFFD4C5B5)]),
        _BoardInfo(3, 'صحراء', 'Light Cedar & Amber', [Color(0xFFC4A882), Color(0xFFFFBF00)]),
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final boards = _boards;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: TavliSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
          child: Text(
            'Choose Your Board',
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
        ),
        const SizedBox(height: TavliSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
          child: const Text(
            'You can change this anytime in Customize.',
            style: TextStyle(
              color: TavliColors.light,
              fontSize: 18,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: TavliSpacing.xl),

        // Card carousel.
        Expanded(
          child: PageView.builder(
            controller: _carouselController,
            itemCount: boards.length,
            onPageChanged: (i) {
              setState(() => _selected = boards[i].index);
              SettingsService.instance.boardSet = boards[i].index;
            },
            itemBuilder: (context, index) {
              return ListenableBuilder(
                listenable: _carouselController,
                builder: (context, child) {
                  double page = 0;
                  if (_carouselController.position.haveDimensions) {
                    page = _carouselController.page ?? 0;
                  }
                  final delta = (index - page).abs();
                  final scale = 1.0 - (delta * 0.1).clamp(0.0, 0.3);
                  final rotation = (index - page) * 0.05;

                  return Transform(
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateZ(rotation)
                      ..scale(scale, scale, 1.0),
                    child: child,
                  );
                },
                child: _BoardCard(
                  board: boards[index],
                  selected: _selected == boards[index].index,
                  onTap: () {
                    setState(() => _selected = boards[index].index);
                    SettingsService.instance.boardSet = boards[index].index;
                    _carouselController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BoardCard extends StatelessWidget {
  final _BoardInfo board;
  final bool selected;
  final VoidCallback onTap;

  const _BoardCard({
    required this.board,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: TavliSpacing.xs,
          vertical: TavliSpacing.md,
        ),
        decoration: BoxDecoration(
          color: TavliColors.background,
          borderRadius: BorderRadius.circular(TavliRadius.lg),
          border: Border.all(color: TavliColors.primary),
          boxShadow: TavliShadows.large,
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(TavliRadius.lg),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: board.colors,
                  ),
                ),
                child: Center(
                  child: Transform.rotate(
                    angle: math.pi / 4,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: TavliColors.light.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: TavliColors.light.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(TavliSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    board.name,
                    style: TextStyle(
                      color: TavliColors.primary,
                      fontSize: 18,
                      fontFamily: TavliTheme.serifFamily,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: TavliSpacing.xxs),
                  Text(
                    board.subtitle,
                    style: const TextStyle(
                      color: TavliColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardInfo {
  final int index;
  final String name;
  final String subtitle;
  final List<Color> colors;
  const _BoardInfo(this.index, this.name, this.subtitle, this.colors);
}

// ─── Screen 4: Personality Selection ────────────────────────────

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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  _PersonalityChoice(
                    personality: personality,
                    selected: _selected == personality,
                    onTap: () {
                      setState(() => _selected = personality);
                      SettingsService.instance.botPersonality = personality;
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalityChoice extends StatelessWidget {
  final BotPersonality personality;
  final bool selected;
  final VoidCallback onTap;

  const _PersonalityChoice({
    required this.personality,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(TavliSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TavliRadius.lg),
          color: TavliColors.background,
          border: Border.all(color: TavliColors.primary),
          boxShadow: TavliShadows.xsmall,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: TavliColors.surface,
              ),
              child: Center(
                child: Text(personality.avatarInitial, style: const TextStyle(
                  fontSize: 21, fontWeight: FontWeight.bold,
                  color: TavliColors.primary,
                )),
              ),
            ),
            const SizedBox(width: TavliSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(personality.displayName, style: TextStyle(
                    color: TavliColors.primary, fontSize: 18, fontFamily: TavliTheme.serifFamily, fontWeight: FontWeight.w500,
                  )),
                  const SizedBox(height: TavliSpacing.xxs),
                  Text(personality.subtitle, style: const TextStyle(
                    color: TavliColors.primary, fontSize: 14,
                  )),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: TavliColors.primary, size: 22),
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
                  overlayColor: TavliColors.background.withValues(alpha: 0.2),
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
                  color: TavliColors.background,
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
                        color: TavliColors.primary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: TavliSpacing.xs),
                    Text(
                      _currentExample.line1,
                      style: const TextStyle(
                        color: TavliColors.primary,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: TavliSpacing.xxs),
                    Text(
                      _currentExample.line2,
                      style: const TextStyle(
                        color: TavliColors.primary,
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
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(28, 28);

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

// ─── Screen 6: Ready to Play ────────────────────────────────────

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
                  color: TavliColors.primary,
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
          const SizedBox(height: TavliSpacing.lg),
          GestureDetector(
            onTap: onLearn,
            child: Container(
              width: double.infinity,
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
              decoration: BoxDecoration(
                color: TavliColors.background,
                borderRadius: BorderRadius.circular(TavliRadius.sm),
                border: Border.all(color: TavliColors.primary),
                boxShadow: TavliShadows.xsmall,
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                'Learn to Play',
                style: TextStyle(
                  color: TavliColors.primary,
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
