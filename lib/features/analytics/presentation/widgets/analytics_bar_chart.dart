import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Daily spend bar chart.
///
/// Each bar is colored by whether the day's spend is above or below the
/// average of days with spend — success (below avg) / danger (above avg),
/// zero days render as a muted stub — matching the Monthly Trend theme.
/// Tapping a bar highlights it and shows its value in a floating tooltip.
class AnalyticsBarChart extends StatefulWidget {
  const AnalyticsBarChart({
    super.key,
    required this.title,
    required this.points,
  });

  final String title;
  final List<AnalyticsPoint> points;

  @override
  State<AnalyticsBarChart> createState() => _AnalyticsBarChartState();
}

class _AnalyticsBarChartState extends State<AnalyticsBarChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final axisColor = AppColors.textSecondaryFor(brightness);
    final maxY = _maxY(widget.points);
    final avg = _avgOfNonZero(widget.points);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: AppTypography.sectionTitle(context)),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxY <= 0 ? 1 : maxY * 1.2,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: maxY <= 0 ? 1 : maxY / 3,
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent) {
                      setState(() {
                        _selectedIndex =
                            response?.spot?.touchedBarGroupIndex;
                      });
                    }
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.tooltipBackground,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    tooltipBorderRadius: BorderRadius.circular(8),
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final index = group.x.toInt();
                      if (index < 0 || index >= widget.points.length) {
                        return null;
                      }
                      final point = widget.points[index];
                      return BarTooltipItem(
                        '${point.label}\n${CurrencyFormatter.money(point.amountKes)}',
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
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      // For monthly data (>10 points) only label every 5th bar
                      // to avoid the unreadable "1 2 3 4 5..." wall of numbers.
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < 0 || index >= widget.points.length) {
                          return const SizedBox.shrink();
                        }
                        final isMonthly = widget.points.length > 10;
                        if (isMonthly && index % 5 != 0) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            widget.points[index].label,
                            style: TextStyle(color: axisColor, fontSize: 11),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List<BarChartGroupData>.generate(
                  widget.points.length,
                  (index) {
                    final point = widget.points[index];
                    final isZero = point.amountKes <= 0;
                    final aboveAvg = avg > 0 && point.amountKes > avg;
                    final baseColor = isZero
                        ? theme.colorScheme.outline.withValues(alpha: 0.3)
                        : aboveAvg
                            ? AppColors.danger
                            : AppColors.success;
                    final isSelected = _selectedIndex == index;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: point.amountKes <= 0 ? 0 : point.amountKes,
                          color: isSelected
                              ? baseColor.withValues(alpha: 0.45)
                              : baseColor,
                          width: widget.points.length > 12 ? 8 : 12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    );
                  },
                ),
              ),
              duration: const Duration(milliseconds: 420),
            ),
          ),
        ],
      ),
    );
  }

  double _maxY(List<AnalyticsPoint> points) {
    var max = 0.0;
    for (final point in points) {
      if (point.amountKes > max) {
        max = point.amountKes;
      }
    }
    return max;
  }

  double _avgOfNonZero(List<AnalyticsPoint> points) {
    final nonzero = points.where((p) => p.amountKes > 0).toList();
    if (nonzero.isEmpty) return 0;
    return nonzero.fold<double>(0, (s, p) => s + p.amountKes) /
        nonzero.length;
  }
}
