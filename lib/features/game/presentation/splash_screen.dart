import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/constants/colors.dart';
import 'onboarding_screen.dart';

/// Splash screen — warm mahogany feel with animated logo.
///
/// Preloads services during the animation, then navigates to home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleIn = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2000), () async {
      if (!mounted) return;
      final done = await OnboardingScreen.isCompleted();
      if (mounted) context.go(done ? '/home' : '/onboarding');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TavliColors.background,
      body: Semantics(
        label: 'Tavli — Loading',
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeIn.value,
                child: Transform.scale(
                  scale: _scaleIn.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App icon.
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: TavliColors.surface,
                          border: Border.all(
                            color: TavliColors.primary,
                            width: 4,
                          ),
                          boxShadow: TavliShadows.large,
                        ),
                        child: Center(
                          child: Text('T', style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w700,
                            fontFamily: TavliTheme.serifFamily,
                            color: TavliColors.light,
                          )),
                        ),
                      ),
                      const SizedBox(height: TavliSpacing.xl),
                      Text(
                        'Tavli',
                        style: TextStyle(
                          color: TavliColors.primary,
                          fontSize: 40,
                          fontFamily: TavliTheme.serifFamily,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: TavliSpacing.xs),
                      Text(
                        'ΤΑΒΛΙ',
                        style: TextStyle(
                          color: TavliColors.primary.withValues(alpha: 0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 6,
                        ),
                      ),
                      const SizedBox(height: TavliSpacing.xl),
                      // Decorative divider.
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 1,
                            color: TavliColors.primary.withValues(alpha: 0.3),
                          ),
                          const SizedBox(width: TavliSpacing.sm),
                          Icon(
                            Icons.casino_outlined,
                            size: 16,
                            color: TavliColors.primary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: TavliSpacing.sm),
                          Container(
                            width: 32,
                            height: 1,
                            color: TavliColors.primary.withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                      const SizedBox(height: TavliSpacing.xxl),
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            TavliColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
