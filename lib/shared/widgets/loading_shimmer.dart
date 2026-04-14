import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../providers/accessibility_providers.dart';

/// Shimmer loading placeholder for content that's being fetched.
class LoadingShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingShimmer({
    super.key,
    this.width = double.infinity,
    this.height = TavliSpacing.md,
    this.borderRadius = TavliRadius.xs,
  });

  /// A card-shaped shimmer placeholder.
  const LoadingShimmer.card({super.key})
      : width = double.infinity,
        height = 72,
        borderRadius = TavliRadius.md;

  /// A circle shimmer (avatar placeholder).
  const LoadingShimmer.circle({super.key, this.width = 48})
      : height = 48,
        borderRadius = TavliRadius.full;

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.duration = ReducedMotion.duration(context, const Duration(milliseconds: 1500));
      _controller.repeat();
    });
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
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(-1.0 + 2.0 * _controller.value + 1, 0),
              colors: [
                TavliColors.background.withValues(alpha: 0.12),
                TavliColors.background.withValues(alpha: 0.25),
                TavliColors.background.withValues(alpha: 0.12),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A list of shimmer placeholders.
class LoadingShimmerList extends StatelessWidget {
  final int itemCount;
  const LoadingShimmerList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(TavliSpacing.md),
      child: Column(
        children: List.generate(itemCount, (i) => const Padding(
          padding: EdgeInsets.only(bottom: TavliSpacing.sm),
          child: LoadingShimmer.card(),
        )),
      ),
    );
  }
}
