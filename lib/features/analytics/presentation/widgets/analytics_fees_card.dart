import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:flutter/material.dart';

/// Fees card — total transaction fees paid in the period.
/// Mirrors Kotlin FeesCard in InsightsScreen Analytics tab.
class AnalyticsFeesCard extends StatelessWidget {
  const AnalyticsFeesCard({super.key, required this.snapshot});

  final AnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    if (snapshot.feesPaidKes <= 0) return const SizedBox.shrink();
    final avgFee = snapshot.totalTxCount > 0
        ? snapshot.feesPaidKes / snapshot.totalTxCount
        : 0.0;
    final topCat = snapshot.topFeeCategory;

    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                size: 20, color: AppColors.warning),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction Fees',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${snapshot.totalTxCount} transactions · avg ${CurrencyFormatter.money(avgFee)}'
                  '${topCat != null ? ' · Most in $topCat' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.55),
                      ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.money(snapshot.feesPaidKes),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning,
                ),
          ),
        ],
      ),
    );
  }
}
