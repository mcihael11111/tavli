import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../shared/widgets/content_module.dart';
import '../../../../shared/widgets/gradient_scaffold.dart';
import '../../domain/mechanic_comparisons.dart';
import '../widgets/comparison_table.dart';

/// Deep-dive comparison screen showing rule differences across variants
/// within a single mechanic family (hitting, pinning, or running).
class MechanicComparisonScreen extends StatelessWidget {
  final String family;

  const MechanicComparisonScreen({super.key, required this.family});

  MechanicComparison get _comparison => switch (family) {
        'hitting' => hittingComparison,
        'pinning' => pinningComparison,
        'running' => runningComparison,
        _ => hittingComparison,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final comparison = _comparison;

    return GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TavliColors.light),
          onPressed: () => context.pop(),
        ),
        title: Text(
          comparison.title,
          style: theme.textTheme.titleLarge!.copyWith(
            color: TavliColors.light,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TavliSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: TavliSpacing.sm),

              // Description.
              ContentModule(
                body: comparison.description,
              ),

              const SizedBox(height: TavliSpacing.lg),

              // Comparison table.
              ContentModule(
                title: 'Rule Comparison',
                child: Padding(
                  padding: const EdgeInsets.only(top: TavliSpacing.sm),
                  child: ComparisonTable(comparison: comparison),
                ),
              ),

              const SizedBox(height: TavliSpacing.lg),

              // Variant tradition labels.
              ContentModule(
                title: 'Traditions',
                child: Padding(
                  padding: const EdgeInsets.only(top: TavliSpacing.sm),
                  child: Column(
                    children: [
                      for (final variant in comparison.variants)
                        Padding(
                          padding: const EdgeInsets.only(bottom: TavliSpacing.xs),
                          child: Row(
                            children: [
                              Text(
                                variant.tradition.flagEmoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: TavliSpacing.sm),
                              Text(
                                '${variant.displayName} (${variant.nativeName})',
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  color: TavliColors.light,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                variant.tradition.displayName,
                                style: theme.textTheme.bodySmall!.copyWith(
                                  color: TavliColors.disabledOnPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: TavliSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
