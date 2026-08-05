import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 6-month rolling spend bar chart — staggered entry animation,
/// tap-to-highlight with floating tooltip, current month highlighted.
class MonthlyTrendBars extends StatefulWidget {
  const MonthlyTrendBars({
    super.key,
    required this.monthlyHistory,
    this.onTapMonth,
  });

  final List<MonthlyTotalPoint> monthlyHistory;
  final void Function(int year, int month)? onTapMonth;

  @override
  State<MonthlyTrendBars> createState() => _MonthlyTrendBarsState();
}

class _MonthlyTrendBarsState extends State<MonthlyTrendBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int? _selectedBarIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration:
          Duration(milliseconds: 350 + widget.monthlyHistory.length * 50),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = widget.monthlyHistory;
    if (history.isEmpty) return const SizedBox.shrink();

    final maxKes = history
        .map((p) => p.totalKes)
        .fold<double>(0, (prev, v) => v > prev ? v : prev);

    final nonZero = history.where((p) => p.totalKes > 0).toList();
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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(history.length, (i) {
                final point = history[i];
                final frac = maxKes > 0
                    ? (point.totalKes / maxKes).clamp(0.0, 1.0)
                    : 0.0;
                final barHeight = point.totalKes > 0
                    ? (frac * 90).clamp(4.0, 90.0)
                    : 4.0;
                final aboveAvg = avg > 0 && point.totalKes > avg;
                final barColor = point.totalKes == 0
                    ? Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.3)
                    : aboveAvg
                        ? AppColors.danger
                        : AppColors.success;
                final isCurrent =
                    point.year == currentYear && point.month == currentMonth;
                final isSelected = _selectedBarIndex == i;

                final staggerStart = (i * 0.05).clamp(0.0, 1.0);
                final barAnim = Tween<double>(begin: 0, end: barHeight).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: Interval(
                      staggerStart,
                      (staggerStart + 0.35).clamp(0.0, 1.0),
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                );

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedBarIndex =
                            _selectedBarIndex == i ? null : i);
                        widget.onTapMonth?.call(point.year, point.month);
                      },
                      onLongPress: () =>
                          widget.onTapMonth?.call(point.year, point.month),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Stack(
                            alignment: Alignment.topCenter,
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedBuilder(
                                animation: _controller,
                                builder: (_, child) => ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4)),
                                  child: Container(
                                    height: barAnim.value,
                                    color: isSelected
                                        ? barColor.withValues(alpha: 0.55)
                                        : barColor,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  top: -22,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.tooltipBackground,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      CurrencyFormatter.compact(point.totalKes),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            point.monthLabel,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  fontSize: 10,
                                  fontWeight:
                                      isCurrent ? FontWeight.w700 : null,
                                  color: isCurrent
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
      ],
    );
  }
}
