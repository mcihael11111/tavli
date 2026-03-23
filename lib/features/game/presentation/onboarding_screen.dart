import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/theme.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/services/settings_service.dart';
import '../../ai/personality/bot_personality.dart';

/// First-launch onboarding — 5 screens, skippable.
///
/// Screen 1: Welcome
/// Screen 2: Choose your board style (card carousel)
/// Screen 3: Choose your opponent (personality)
/// Screen 4: How Greek should I be (language level slider)
/// Screen 5: Ready to play
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  /// Check if onboarding has been completed.
  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tavli_onboarding_done') ?? false;
  }

  /// Mark onboarding as completed.
  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tavli_onboarding_done', true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;
  static const _pageCount = 5;

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
                  _BoardPickPage(),
                  _PersonalityPickPage(),
                  _GreekLevelPage(),
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
                SettingsService.instance.botPersonality.avatarInitial,
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
          const SizedBox(height: TavliSpacing.xl),
          Text(
            'Γειά σου',
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
            "I'm ${SettingsService.instance.botPersonality.displayName}. Welcome to Tavli.",
            style: const TextStyle(
              color: TavliColors.light,
              fontSize: 20,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TavliSpacing.xxs),
          const Text(
            'Beautiful boards. Real strategy.\n'
            'Family and Friends.',
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

// ─── Screen 2: Board Selection (Card Carousel) ─────────────────

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: TavliSpacing.lg),
        // Header — production copy.
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
          child: Text(
            'You can change this anytime in Customize.',
            style: TextStyle(
              color: TavliColors.light.withValues(alpha: 0.7),
              fontSize: 20,
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
            itemCount: _boards.length,
            onPageChanged: (i) {
              setState(() => _selected = _boards[i].index);
              SettingsService.instance.boardSet = _boards[i].index;
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
                  board: _boards[index],
                  selected: _selected == _boards[index].index,
                  onTap: () {
                    setState(() => _selected = _boards[index].index);
                    SettingsService.instance.boardSet = _boards[index].index;
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
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TavliColors.primary),
          boxShadow: TavliShadows.large,
        ),
        child: Column(
          children: [
            // Board preview area.
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
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
            // Board label area.
            Padding(
              padding: const EdgeInsets.all(14),
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

const _boards = [
  _BoardInfo(1, 'Μαόνι', 'Mahogany & Olive Wood', [Color(0xFF8B4513), Color(0xFFC8B560)]),
  _BoardInfo(2, 'Σμαραγδί', 'Mahogany & Teal', [Color(0xFF6F3024), Color(0xFF1A5C5C)]),
  _BoardInfo(3, 'Νυχτερινό', 'Dark Walnut & Navy', [Color(0xFF2A1A0E), Color(0xFF2C3E50)]),
];

class _BoardInfo {
  final int index;
  final String name;
  final String subtitle;
  final List<Color> colors;
  const _BoardInfo(this.index, this.name, this.subtitle, this.colors);
}

// ─── Screen 3: Personality Selection ────────────────────────────

class _PersonalityPickPage extends StatefulWidget {
  @override
  State<_PersonalityPickPage> createState() => _PersonalityPickPageState();
}

class _PersonalityPickPageState extends State<_PersonalityPickPage> {
  BotPersonality _selected = BotPersonality.mikhail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TavliSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: TavliSpacing.lg),
          // Header — production copy.
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
          Text(
            'You can change this anytime in Settings.',
            style: TextStyle(
              color: TavliColors.light.withValues(alpha: 0.7),
              fontSize: 20,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TavliSpacing.xl),

          // Personality list.
          Expanded(
            child: ListView(
              children: [
                for (final personality in BotPersonality.values) ...[
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

// ─── Screen 4: How Greek Should I Be ────────────────────────────

class _GreekLevelPage extends StatefulWidget {
  @override
  State<_GreekLevelPage> createState() => _GreekLevelPageState();
}

class _GreekLevelPageState extends State<_GreekLevelPage> {
  double _level = SettingsService.instance.greekLevel;

  // Example phrases at different Greek levels.
  static const _examples = [
    _GreekExample('Ready to play', 'Michael will lose'),
    _GreekExample('Έτοιμο to play', 'Michael θα lose'),
    _GreekExample('Έτοιμο να παίξει', 'Ο Michael θα χάσει'),
    _GreekExample('Έτοιμο να παίξει', 'Ο Μάικλ θα χάσει'),
    _GreekExample('Έτοιμο να παίξει', 'Ο Μάικλ θα χάσει'),
  ];

  _GreekExample get _currentExample {
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
          // Header.
          Text(
            'How Greek Should I Be?',
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
            'We can adjust the amount of Greek I use depending on your comfort level.',
            style: TextStyle(
              color: TavliColors.light.withValues(alpha: 0.7),
              fontSize: 20,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          // Slider with endpoint labels.
          Column(
            children: [
              // Slider.
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: TavliColors.background,
                  inactiveTrackColor: TavliColors.background,
                  thumbColor: TavliColors.background,
                  overlayColor: TavliColors.background.withValues(alpha: 0.2),
                  trackHeight: 4,
                  thumbShape: _GreekSliderThumb(),
                ),
                child: Slider(
                  value: _level,
                  divisions: 4,
                  onChanged: (v) {
                    setState(() => _level = v);
                    SettingsService.instance.greekLevel = v;
                  },
                ),
              ),
              const SizedBox(height: TavliSpacing.sm),

              // Labels.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'English Only',
                          style: TextStyle(
                            color: TavliColors.light,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: TavliSpacing.xxs),
                        Text(
                          "Can't read Greek",
                          style: TextStyle(
                            color: TavliColors.light.withValues(alpha: 0.7),
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
                        const Text(
                          'Fluent',
                          style: TextStyle(
                            color: TavliColors.light,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: TavliSpacing.xxs),
                        Text(
                          'Can read and write',
                          style: TextStyle(
                            color: TavliColors.light.withValues(alpha: 0.7),
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

class _GreekSliderThumb extends SliderComponentShape {
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

    // Outer circle.
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

    // Inner dot.
    canvas.drawCircle(
      center,
      6,
      Paint()..color = TavliColors.text,
    );
  }
}

class _GreekExample {
  final String line1;
  final String line2;
  const _GreekExample(this.line1, this.line2);
}

// ─── Screen 5: Ready to Play ────────────────────────────────────

class _ReadyPage extends StatelessWidget {
  final VoidCallback onLearn;
  const _ReadyPage({required this.onLearn});

  @override
  Widget build(BuildContext context) {
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
                SettingsService.instance.botPersonality.avatarInitial,
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
            'Play against ${SettingsService.instance.botPersonality.displayName}, '
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
                'Next',
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
