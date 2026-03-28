import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/colors.dart';

/// Shell with frosted pill-shaped floating bottom nav — wraps home, profile, customize, settings.
///
/// Architecture: The blur+fill pill and the nav icons are in separate layers.
/// The pill is clipped to its rounded shape, but the icons sit in an unclipped
/// layer so the active circle can protrude above the bar edge.
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

  static const double _barHeight = 58;
  static const double _activeSize = 58;
  static const double _activeProtrusion = 14;

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(state.uri.path);

    return Scaffold(
      body: Stack(
        children: [
          child,
          // Nav bar area.
          Positioned(
            left: TavliSpacing.md,
            right: TavliSpacing.md,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: TavliSpacing.sm),
                child: SizedBox(
                  // Total height = bar + protrusion space above.
                  height: _barHeight + _activeProtrusion,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Layer 1: Frosted glass pill (clipped).
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: _barHeight,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(TavliRadius.full),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: TavliColors.background.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(TavliRadius.full),
                                border: Border.all(
                                  color: TavliColors.light.withValues(alpha: 0.12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Layer 2: Nav items (unclipped — active circle can protrude).
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: _barHeight + _activeProtrusion,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
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
    const double activeSize = ShellScreen._activeSize;
    const double inactiveSize = 44;
    const double barHeight = ShellScreen._barHeight;
    const double protrusion = ShellScreen._activeProtrusion;

    final double size = active ? activeSize : inactiveSize;
    final double iconSize = active ? 26 : 22;

    // Active: centered vertically so it protrudes above the bar.
    // Inactive: centered within the bar height at the bottom.
    final double bottomOffset = active
        ? (barHeight - activeSize) / 2 // vertically center in bar, protrusion handles the rise
        : (barHeight - inactiveSize) / 2;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: activeSize + 8, // tap target
        height: barHeight + protrusion,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              bottom: bottomOffset,
              left: (activeSize + 8 - size) / 2,
              child: active
                  ? Transform.translate(
                      offset: const Offset(0, -protrusion),
                      child: _buildCircle(size, iconSize),
                    )
                  : _buildCircle(size, iconSize),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircle(double size, double iconSize) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? TavliColors.primary : Colors.transparent,
        boxShadow: active
            ? [
                BoxShadow(
                  color: TavliColors.primary.withValues(alpha: 0.45),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: active
            ? TavliColors.light
            : TavliColors.light.withValues(alpha: 0.7),
      ),
    );
  }
}
