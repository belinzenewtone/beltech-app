import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:flutter/material.dart';

/// Card showing savings projection based on current trends.
class SavingsProjectionCard extends StatelessWidget {
  const SavingsProjectionCard({
    super.key,
    required this.monthlyNetCashflow,
    required this.months,
  });

  final double monthlyNetCashflow;
  final int months;

  @override
  Widget build(BuildContext context) {
    final projectedSavings = monthlyNetCashflow * months;
    final isPositive = projectedSavings >= 0;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Savings Projection',
                  style: AppTypography.cardTitle(context),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPositive ? AppColors.success : AppColors.warning)
                        .withValues(alpha: 0.12),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Text(
                    '$months months',
                    style: AppTypography.bodySm(context).copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isPositive ? AppColors.success : AppColors.warning)
                    .withValues(alpha: 0.08),
                borderRadius: AppRadius.mdAll,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Projected savings',
                        style: AppTypography.bodySm(context),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.money(projectedSavings.abs()),
                        style: AppTypography.amount(context).copyWith(
                          color: isPositive ? AppColors.success : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    color: isPositive ? AppColors.success : AppColors.danger,
                    size: 28,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.08),
                borderRadius: AppRadius.smAll,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Based on ${CurrencyFormatter.money(monthlyNetCashflow)}/month net cashflow',
                      style: AppTypography.bodySm(context).copyWith(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
