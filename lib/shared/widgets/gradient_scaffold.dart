import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

/// A Scaffold replacement that paints a gradient background for depth.
///
/// Wraps a standard [Scaffold] with a [DecoratedBox] behind the body.
/// AppBar is transparent by default so the gradient shows through.
class GradientScaffold extends StatelessWidget {
  final Gradient? gradient;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  const GradientScaffold({
    super.key,
    this.gradient,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveGradient = gradient ??
        (isDark ? TavliGradients.warmScaffoldDark : TavliGradients.warmScaffold);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: backgroundColor ?? Colors.transparent,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: effectiveGradient),
        child: body,
      ),
    );
  }
}
