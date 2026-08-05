import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:flutter/material.dart';

/// "vs Last Period" card with two stacked horizontal progress bars.
/// Mirrors Kotlin SpendingComparisonCard.
class SpendingComparisonCard extends StatelessWidget {
  const SpendingComparisonCard({super.key, required this.snapshot});

  final AnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final current = snapshot.totalSpentThisPeriodKes;
    final previous = snapshot.previousPeriodTotalKes;
    if (current == 0 && previous == 0) return const SizedBox.shrink();

    final maxVal = [current, previous].reduce((a, b) => a > b ? a : b);
    final currentFrac = maxVal > 0 ? (current / maxVal).clamp(0.0, 1.0) : 0.0;
    final prevFrac = maxVal > 0 ? (previous / maxVal).clamp(0.0, 1.0) : 0.0;

    final changeText = snapshot.periodChangePercent?.abs().toStringAsFixed(1);
    final spentMore = (snapshot.periodChangePercent ?? 0) > 0;
    final delta = (current - previous).abs();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'vs Last Period',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              if (changeText != null)
                _DeltaPill(spentMore: spentMore, delta: delta),
            ],
          ),
          const SizedBox(height: 14),
          _BarRow(
            label: 'Last period',
            fraction: prevFrac,
            amount: previous,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
          ),
          const SizedBox(height: 10),
          _BarRow(
            label: 'This period',
            fraction: currentFrac,
            amount: current,
            color: spentMore ? AppColors.danger : AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.fraction,
    required this.amount,
    required this.color,
  });

  final String label;
  final double fraction;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
            Text(
              CurrencyFormatter.money(amount),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _DeltaPill extends StatelessWidget {
  const _DeltaPill({required this.spentMore, required this.delta});

  final bool spentMore;
  final double delta;

  @override
  Widget build(BuildContext context) {
    final color = spentMore ? AppColors.danger : AppColors.success;
    final text = spentMore
        ? 'Spent KSh ${CurrencyFormatter.compact(delta)} more'
        : 'Saved KSh ${CurrencyFormatter.compact(delta)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
