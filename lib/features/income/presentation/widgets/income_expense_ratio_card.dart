import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_card.dart';
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

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: AppRadius.mdAll,
            child: Row(
              children: [
                Expanded(
                  flex: incomePercent.toInt(),
                  child: Container(height: 6, color: AppColors.success),
                ),
                Expanded(
                  flex: expensePercent.toInt(),
                  child: Container(height: 6, color: AppColors.danger),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${incomePercent.toStringAsFixed(0)}% income',
                style: AppTypography.bodySm(
                  context,
                ).copyWith(color: AppColors.success),
              ),
              Text(
                '${expensePercent.toStringAsFixed(0)}% expenses',
                style: AppTypography.bodySm(
                  context,
                ).copyWith(color: AppColors.danger),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
