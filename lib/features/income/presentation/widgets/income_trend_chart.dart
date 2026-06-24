import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:beltech/features/analytics/presentation/widgets/analytics_trend_chart.dart';
import 'package:beltech/features/income/domain/entities/income_overview.dart';
import 'package:flutter/material.dart';

class IncomeTrendChart extends StatelessWidget {
  const IncomeTrendChart({
    super.key,
    required this.trend,
  });

  final List<IncomeTrendPoint> trend;

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return const GlassCard(
        tone: GlassCardTone.muted,
        child: Text('Add more income entries to unlock a monthly trend.'),
      );
    }

    return AnalyticsTrendChart(
      title: 'Income Trend',
      points: trend
          .map(
            (item) => AnalyticsPoint(
              label: item.label,
              amountKes: item.incomeKes,
            ),
          )
          .toList(),
    );
  }
}
