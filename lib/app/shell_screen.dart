import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/colors.dart';

/// Shell with pill-shaped floating bottom nav — wraps home, profile, customize, settings.
class ShellScreen extends StatelessWidget {
  final GoRouterState state;
  final Widget child;

  const ShellScreen({super.key, required this.state, required this.child});

  int _currentIndex(String location) {
    if (location.startsWith('/profile')) return 1;
    if (location.startsWith('/customize')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(state.uri.path);

    return Scaffold(
      body: Stack(
        children: [
          child,
          // Bottom gradient fade + nav bar.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.5, 1.0],
                  colors: [
                    Color(0x00D4C2A8),
                    Color(0x88A67F5B),
                    TavliColors.surface,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TavliSpacing.md, TavliSpacing.xl,
                    TavliSpacing.md, TavliSpacing.md,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                    decoration: BoxDecoration(
                      color: TavliColors.background,
                      borderRadius: BorderRadius.circular(TavliRadius.full),
                      border: Border.all(color: TavliColors.background, width: 1),
                      boxShadow: TavliShadows.xsmall,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _NavItem(
                          icon: Icons.home,
                          active: index == 0,
                          onTap: () => context.go('/home'),
                        ),
                        _NavItem(
                          icon: Icons.person,
                          active: index == 1,
                          onTap: () => context.go('/profile'),
                        ),
                        _NavItem(
                          icon: Icons.palette,
                          active: index == 2,
                          onTap: () => context.go('/customize'),
                        ),
                        _NavItem(
                          icon: Icons.settings,
                          active: index == 3,
                          onTap: () => context.go('/settings'),
                        ),
                      ],
                    ),
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? TavliColors.primary : TavliColors.background,
        ),
        child: Icon(
          icon,
          size: 24,
          color: active ? TavliColors.light : TavliColors.primary,
        ),
      ),
    );
  }
}
