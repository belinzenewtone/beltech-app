import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:flutter/material.dart';

/// 2×2 grid of summary metric cards — mirrors Kotlin AnalyticsSummaryCardsRow.
/// Spend (error) / Income (success) / Net (success|error) / Avg Tx (primary).
class AnalyticsSummaryCards extends StatelessWidget {
  const AnalyticsSummaryCards({super.key, required this.snapshot});

  final AnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final net = snapshot.netKes;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Spend',
                value: CurrencyFormatter.compact(snapshot.totalSpentThisPeriodKes),
                color: AppColors.danger,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Income',
                value: CurrencyFormatter.compact(snapshot.totalIncomeThisPeriodKes),
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Net',
                value: CurrencyFormatter.compact(net.abs()),
                color: net >= 0 ? AppColors.success : AppColors.danger,
                prefix: net >= 0 ? '+' : '-',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Avg Tx',
                value: CurrencyFormatter.compact(snapshot.avgTransactionKes),
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    this.prefix = '',
  });

  final String label;
  final String value;
  final Color color;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.55),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '$prefix$value',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
