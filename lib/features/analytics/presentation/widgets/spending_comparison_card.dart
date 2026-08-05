import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/chart_semantics.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:beltech/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "vs Last Period" card with toggle between vs prior period and vs same period last year.
class SpendingComparisonCard extends ConsumerStatefulWidget {
  const SpendingComparisonCard({super.key, required this.snapshot});

  final AnalyticsSnapshot snapshot;

  @override
  ConsumerState<SpendingComparisonCard> createState() =>
      _SpendingComparisonCardState();
}

class _SpendingComparisonCardState
    extends ConsumerState<SpendingComparisonCard> {
  bool _vsLastYear = false;

  @override
  Widget build(BuildContext context) {
    final current = widget.snapshot.totalSpentThisPeriodKes;

    // When _vsLastYear is true, load the same month from last year via the
    // real SQL query. Show a spinner while it's loading.
    double previous;
    bool loadingYoY = false;

    if (_vsLastYear) {
      final now = DateTime.now();
      final yoyAsync =
          ref.watch(monthTotalSpendProvider((now.year - 1, now.month)));
      loadingYoY = yoyAsync.isLoading;
      previous = yoyAsync.value ?? 0.0;
    } else {
      previous = widget.snapshot.previousPeriodTotalKes;
    }

    if (current == 0 && previous == 0 && !loadingYoY) {
      return const SizedBox.shrink();
    }

    final maxVal = [current, previous, 1.0].reduce((a, b) => a > b ? a : b);
    final currentFrac = maxVal > 0 ? (current / maxVal).clamp(0.0, 1.0) : 0.0;
    final prevFrac = maxVal > 0 ? (previous / maxVal).clamp(0.0, 1.0) : 0.0;

    final rawChange = previous > 0 ? ((current - previous) / previous) * 100 : null;
    final changeText = rawChange?.abs().toStringAsFixed(1);
    final spentMore = (rawChange ?? 0) > 0;
    final delta = (current - previous).abs();

    return ChartSemantics(
      label: _vsLastYear
          ? 'Spend comparison: this period vs same period last year'
          : 'Spend comparison: this period vs last period',
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _vsLastYear ? 'vs Same Period Last Year' : 'vs Last Period',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                if (changeText != null && !loadingYoY)
                  _DeltaPill(spentMore: spentMore, delta: delta),
                GestureDetector(
                  onTap: () => setState(() => _vsLastYear = !_vsLastYear),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _vsLastYear
                            ? AppColors.accent.withValues(alpha: 0.5)
                            : Colors.transparent,
                      ),
                      color: _vsLastYear
                          ? AppColors.accent.withValues(alpha: 0.12)
                          : Colors.transparent,
                    ),
                    child: Text(
                      _vsLastYear ? 'Last Year ✓' : 'Last Year',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _vsLastYear
                            ? AppColors.accent
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (loadingYoY)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else ...[
              _BarRow(
                label: _vsLastYear ? 'Same period last year' : 'Last period',
                fraction: prevFrac,
                amount: previous,
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 10),
              _BarRow(
                label: 'This period',
                fraction: currentFrac,
                amount: current,
                color: spentMore ? AppColors.danger : AppColors.success,
              ),
            ],
          ],
        ),
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
