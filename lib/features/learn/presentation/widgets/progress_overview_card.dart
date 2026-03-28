import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../shared/widgets/content_module.dart';

/// Shows overall learn-to-play progress with a progress bar.
class ProgressOverviewCard extends StatelessWidget {
  final double progress;
  final int completed;
  final int total;

  const ProgressOverviewCard({
    super.key,
    required this.progress,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();

    return ContentModule(
      icon: Icons.school_outlined,
      title: 'Your Progress',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: TavliSpacing.xs),
          // Progress bar.
          ClipRRect(
            borderRadius: BorderRadius.circular(TavliRadius.xs),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: TavliColors.primary.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation(TavliColors.light),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: TavliSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completed of $total lessons complete',
                style: TextStyle(
                  fontSize: 13,
                  color: TavliColors.light.withValues(alpha: 0.8),
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: TavliColors.light,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
