import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

/// A titled list of bullet points for rule display.
class RuleSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const RuleSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: TavliSpacing.xs),
          child: Text(
            title,
            style: theme.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w600,
              color: TavliColors.light,
            ),
          ),
        ),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: Icon(Icons.circle, size: 5, color: TavliColors.light),
                ),
                const SizedBox(width: TavliSpacing.sm),
                Expanded(
                  child: Text(
                    item,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      height: 1.4,
                      color: TavliColors.light,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
