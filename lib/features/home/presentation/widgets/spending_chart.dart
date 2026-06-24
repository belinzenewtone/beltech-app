import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SpendingChart extends StatelessWidget {
  const SpendingChart({
    super.key,
    required this.dayValues,
  });

  final Map<String, double> dayValues;

  @override
  Widget build(BuildContext context) {
    final entries = dayValues.entries.toList();
    final maxValue = _maxValue(entries);
    final brightness = Theme.of(context).brightness;
    final axisColor = AppColors.textSecondaryFor(brightness);
    final barColor = brightness == Brightness.light
        ? Theme.of(context).colorScheme.primary
        : AppColors.accent;

    return SizedBox(
      height: 150,
      child: BarChart(
        BarChartData(
          maxY: maxValue <= 0 ? 1 : maxValue * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.tooltipBackground,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final entry = entries[group.x.toInt()];
                return BarTooltipItem(
                  '${entry.key}\n${CurrencyFormatter.money(entry.value)}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                );
              },
            ),
          ),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: maxValue <= 0 ? 1 : maxValue / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.textMuted.withValues(alpha: 0.2),
              strokeWidth: 1,
              dashArray: [3, 3],
            ),
          ),
          extraLinesData: ExtraLinesData(
            extraLinesOnTop: true,
            horizontalLines: maxValue <= 0
                ? const []
                : [
                    HorizontalLine(
                      y: maxValue,
                      color: AppColors.accent.withValues(alpha: 0.8),
                      strokeWidth: 1.2,
                      dashArray: [6, 4],
                    ),
                  ],
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      entries[index].key,
                      style: AppTypography.metaText(context)
                          .copyWith(color: axisColor),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(entries.length, (index) {
            final value = entries[index].value;
            return BarChartGroupData(
              x: index,
              barsSpace: 2,
              barRods: [
                BarChartRodData(
                  toY: value,
                  width: 18,
                  color: barColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            );
          }),
        ),
        duration: const Duration(milliseconds: 420),
      ),
    );
  }

  double _maxValue(List<MapEntry<String, double>> entries) {
    var result = 0.0;
    for (final entry in entries) {
      if (entry.value > result) {
        result = entry.value;
      }
    }
    return result;
  }
}
