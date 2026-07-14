import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
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

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Savings Projection',
                  style: AppTypography.cardTitle(context),
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on ${CurrencyFormatter.money(monthlyNetCashflow)}/month',
                  style: AppTypography.bodySm(context),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.money(projectedSavings.abs()),
                style: AppTypography.amount(context).copyWith(
                  color: isPositive ? AppColors.success : AppColors.danger,
                ),
              ),
              Text('$months months', style: AppTypography.bodySm(context)),
            ],
          ),
        ],
      ),
    );
  }
}
