import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/constants/colors.dart';
import '../../domain/mechanic_comparisons.dart';

/// Comparison table showing rule differences across variants.
class ComparisonTable extends StatelessWidget {
  final MechanicComparison comparison;

  const ComparisonTable({super.key, required this.comparison});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column headers.
        Padding(
          padding: const EdgeInsets.only(bottom: TavliSpacing.sm),
          child: Row(
            children: [
              const SizedBox(width: 100),
              for (final variant in comparison.variants)
                Expanded(
                  child: Text(
                    variant.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: TavliTheme.serifFamily,
                      fontWeight: FontWeight.w600,
                      color: TavliColors.light,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),

        // Rows.
        for (final row in comparison.rows) _buildRow(row),
      ],
    );
  }

  Widget _buildRow(ComparisonRow row) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: TavliSpacing.xs,
        horizontal: TavliSpacing.xs,
      ),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: TavliColors.background.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(TavliRadius.sm),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              row.rule,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: TavliColors.light,
              ),
            ),
          ),
          for (final variant in comparison.variants)
            Expanded(
              child: _ValueCell(
                value: row.values[variant] ?? '—',
              ),
            ),
        ],
      ),
    );
  }
}

class _ValueCell extends StatelessWidget {
  final String value;

  const _ValueCell({required this.value});

  @override
  Widget build(BuildContext context) {
    final isYes = value == 'Yes';
    final isNo = value == 'No';

    if (isYes) {
      return const Icon(
        Icons.check_circle,
        size: 16,
        color: TavliColors.light,
      );
    }
    if (isNo) {
      return Icon(
        Icons.cancel_outlined,
        size: 16,
        color: TavliColors.light.withValues(alpha: 0.4),
      );
    }

    return Text(
      value,
      style: TextStyle(
        fontSize: 11,
        color: value == '—'
            ? TavliColors.light.withValues(alpha: 0.3)
            : TavliColors.light.withValues(alpha: 0.8),
      ),
      textAlign: TextAlign.center,
    );
  }
}
