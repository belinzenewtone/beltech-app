import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:flutter/material.dart';

/// 6-month rolling spend bar chart — tappable bars navigate to Monthly Wrapped.
/// Mirrors Kotlin "Monthly Trend" bar chart in InsightsScreen Insights tab.
class MonthlyTrendBars extends StatelessWidget {
  const MonthlyTrendBars({
    super.key,
    required this.monthlyHistory,
    this.onTapMonth,
  });

  final List<MonthlyTotalPoint> monthlyHistory;

  /// Called with (year, month) when a bar is tapped.
  final void Function(int year, int month)? onTapMonth;

  @override
  Widget build(BuildContext context) {
    if (monthlyHistory.isEmpty) return const SizedBox.shrink();

    final maxKes = monthlyHistory
        .map((p) => p.totalKes)
        .fold<double>(0, (prev, v) => v > prev ? v : prev);

    // Determine average to colour bars above/below avg.
    final nonZero = monthlyHistory.where((p) => p.totalKes > 0).toList();
    final avg = nonZero.isEmpty
        ? 0.0
        : nonZero.map((p) => p.totalKes).reduce((a, b) => a + b) /
            nonZero.length;

    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Trend',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              // Legend
              Row(
                children: [
                  _LegendDot(color: AppColors.success, label: 'Below avg'),
                  const SizedBox(width: 10),
                  _LegendDot(color: AppColors.danger, label: 'Above avg'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              'Tap a bar to view Wrapped →',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: monthlyHistory.map((point) {
                final frac = maxKes > 0
                    ? (point.totalKes / maxKes).clamp(0.0, 1.0)
                    : 0.0;
                final barHeight = point.totalKes > 0
                    ? (frac * 90).clamp(4.0, 90.0)
                    : 4.0;
                final aboveAvg = avg > 0 && point.totalKes > avg;
                final barColor = point.totalKes == 0
                    ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
                    : aboveAvg
                        ? AppColors.danger
                        : AppColors.success;
                final isCurrent = point.year == currentYear && point.month == currentMonth;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => onTapMonth?.call(point.year, point.month),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                            child: Container(
                              height: barHeight,
                              color: barColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            point.monthLabel,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      fontWeight: isCurrent ? FontWeight.w700 : null,
                                      color: isCurrent
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6),
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.6),
              ),
        ),
      ],
    );
  }
}
