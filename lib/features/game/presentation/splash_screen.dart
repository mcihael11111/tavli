import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/tradition.dart';
import '../../../shared/services/settings_service.dart';
import '../../../shared/widgets/gradient_scaffold.dart';
import 'onboarding_screen.dart';

/// Splash screen — culture-locative with staggered animations.
///
/// First launch: shows "Tables" (universal name).
/// Returning user: shows tradition-specific name (Tavli / Tavla / Нарды / שש בש).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Staggered fade-ins.
  late Animation<double> _iconFade;
  late Animation<double> _iconScale;
  late Animation<double> _titleFade;
  late Animation<double> _titleSlide;
  late Animation<double> _subtitleFade;
  late Animation<double> _dotsFade;

  // Fade-out for smooth exit.
  late Animation<double> _exitFade;

  // Culture-locative state.
  String _displayName = 'Tables';
  String _nativeSubtitle = 'Backgammon Traditions';
  String _iconLetter = 'T';
  bool _isFirstLaunch = true;

  // Cycling animation for first launch.
  Timer? _cycleTimer;
  int _cycleIndex = 0;
  double _cycleOpacity = 1.0;
  static const _traditions = Tradition.values;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Phase 1: Icon (0% – 35%).
    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );
    _iconScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    // Phase 2: Title (20% – 55%).
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.55, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<double>(begin: 12.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.55, curve: Curves.easeOut),
      ),
    );

    // Phase 3: Subtitle + divider (40% – 75%).
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.75, curve: Curves.easeOut),
      ),
    );

    // Phase 4: Loading dots (60% – 90%).
    _dotsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.9, curve: Curves.easeOut),
      ),
    );

    // Phase 5: Exit fade (held at 1.0 until 88%, then fades to 0).
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.88, 1.0, curve: Curves.easeIn),
      ),
    );

    _loadTraditionAndStart();
  }

  Future<void> _loadTraditionAndStart() async {
    // Determine if user has a saved tradition.
    try {
      final settings = SettingsService.instance;
      final done = await OnboardingScreen.isCompleted();

      if (done) {
        final tradition = settings.tradition;
        _isFirstLaunch = false;
        _displayName = tradition.displayName;
        _nativeSubtitle = tradition.nativeName;
        _iconLetter = _iconLetterFor(tradition);
      }
    } catch (_) {
      // SettingsService not yet initialized — use defaults (first launch).
    }

    if (mounted) setState(() {});

    // Start the entrance animation.
    _controller.forward();

    // Start cycling for first launch.
    if (_isFirstLaunch) {
      _startCycling();
    }

    // Navigate after animation completes.
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _navigateNext();
      }
    });
  }

  /// Returns the icon letter for a tradition.
  String _iconLetterFor(Tradition tradition) => switch (tradition) {
        Tradition.tavli => 'Τ',
        Tradition.tavla => 'T',
        Tradition.nardy => 'Н',
        Tradition.sheshBesh => 'ש',
      };

  /// On first launch, subtly cycle through tradition native names.
  void _startCycling() {
    _cycleTimer = Timer.periodic(const Duration(milliseconds: 2000), (_) {
      if (!mounted) return;
      // Fade out.
      setState(() => _cycleOpacity = 0.0);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _cycleIndex = (_cycleIndex + 1) % _traditions.length;
        setState(() {
          _nativeSubtitle = _traditions[_cycleIndex].nativeName;
          _cycleOpacity = 1.0;
        });
      });
    });
  }

  Future<void> _navigateNext() async {
    final done = await OnboardingScreen.isCompleted();
    if (mounted) context.go(done ? '/home' : '/onboarding');
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      gradient: TavliGradients.deepScaffold,
      body: Semantics(
        label: '$_displayName — Loading',
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _exitFade.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Icon circle ──
                    Opacity(
                      opacity: _iconFade.value,
                      child: Transform.scale(
                        scale: _iconScale.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: TavliColors.surface,
                            border: Border.all(
                              color: TavliColors.light.withValues(alpha: 0.3),
                              width: 3,
                            ),
                            boxShadow: TavliShadows.large,
                          ),
                          child: Center(
                            child: Text(
                              _iconLetter,
                              style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w700,
                                fontFamily: TavliTheme.serifFamily,
                                color: TavliColors.light,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: TavliSpacing.xl),

                    // ── Title ──
                    Opacity(
                      opacity: _titleFade.value,
                      child: Transform.translate(
                        offset: Offset(0, _titleSlide.value),
                        child: Text(
                          _displayName,
                          style: TextStyle(
                            color: TavliColors.light,
                            fontSize: 40,
                            fontFamily: TavliTheme.serifFamily,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: TavliSpacing.xs),

                    // ── Native subtitle ──
                    Opacity(
                      opacity: _subtitleFade.value,
                      child: AnimatedOpacity(
                        opacity: _isFirstLaunch ? _cycleOpacity : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _nativeSubtitle,
                          style: TextStyle(
                            color: TavliColors.background,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: _isFirstLaunch ? 1 : 6,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: TavliSpacing.xl),

                    // ── Decorative divider ──
                    Opacity(
                      opacity: _subtitleFade.value,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 1,
                            color: TavliColors.light.withValues(alpha: 0.3),
                          ),
                          const SizedBox(width: TavliSpacing.sm),
                          Icon(
                            Icons.casino_outlined,
                            size: 16,
                            color: TavliColors.light.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: TavliSpacing.sm),
                          Container(
                            width: 32,
                            height: 1,
                            color: TavliColors.light.withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: TavliSpacing.xxl),

                    // ── Pulsing dots loading indicator ──
                    Opacity(
                      opacity: _dotsFade.value,
                      child: const _PulsingDots(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Three dots that pulse sequentially — warm, premium loading indicator.
class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Stagger each dot by 0.2.
            final delay = i * 0.2;
            final t = (_controller.value - delay).clamp(0.0, 1.0);
            // Sine pulse: 0 → 1 → 0 over t.
            final scale = 0.4 + 0.6 * _pulse(t);
            final opacity = 0.3 + 0.7 * _pulse(t);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: TavliColors.light,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// Sine wave pulse peaking at t=0.5.
  double _pulse(double t) {
    if (t <= 0 || t >= 1) return 0;
    return (1 - (2 * t - 1) * (2 * t - 1));
  }
}
