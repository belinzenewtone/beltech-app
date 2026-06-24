import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:flutter/material.dart';

/// Card showing income/expense ratio and visualization.
class IncomeExpenseRatioCard extends StatelessWidget {
  const IncomeExpenseRatioCard({
    super.key,
    required this.income,
    required this.expenses,
  });

  final double income;
  final double expenses;

  @override
  Widget build(BuildContext context) {
    final total = income + expenses;
    final incomePercent = total > 0 ? (income / total * 100) : 0.0;
    final expensePercent = 100 - incomePercent;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Income vs Expenses',
              style: AppTypography.cardTitle(context),
            ),
            const SizedBox(height: 16),
            // Ratio visualization
            ClipRRect(
              borderRadius: AppRadius.mdAll,
              child: Row(
                children: [
                  Expanded(
                    flex: incomePercent.toInt(),
                    child: Container(
                      height: 8,
                      color: AppColors.success,
                    ),
                  ),
                  Expanded(
                    flex: expensePercent.toInt(),
                    child: Container(
                      height: 8,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _RatioLabel(
                  label: 'Income',
                  percentage: incomePercent,
                  color: AppColors.success,
                ),
                _RatioLabel(
                  label: 'Expenses',
                  percentage: expensePercent,
                  color: AppColors.danger,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RatioLabel extends StatelessWidget {
  const _RatioLabel({
    required this.label,
    required this.percentage,
    required this.color,
  });

  final String label;
  final double percentage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.bodySm(context),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: AppTypography.bodyMd(context).copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
