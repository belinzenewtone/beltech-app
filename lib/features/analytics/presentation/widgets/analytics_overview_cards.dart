import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:flutter/material.dart';

class AnalyticsOverviewCards extends StatelessWidget {
  const AnalyticsOverviewCards({
    super.key,
    required this.snapshot,
  });

  final AnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'This Month',
                  value: CurrencyFormatter.money(snapshot.totalSpentThisMonthKes),
                  icon: Icons.payments_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  title: 'Daily Avg',
                  value:
                      CurrencyFormatter.money(snapshot.averageDailySpendingKes),
                  icon: Icons.show_chart,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Tasks',
                  value: '${snapshot.totalTasksCompleted} done',
                  secondaryValue: '${snapshot.totalTasksPending} pending',
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  title: 'Productivity',
                  value: '${snapshot.productivityScore.toStringAsFixed(0)}%',
                  icon: Icons.bolt_outlined,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    this.secondaryValue,
  });

  final String title;
  final String value;
  final String? secondaryValue;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.titleMedium,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
          ),
          if (secondaryValue != null) ...[
            const SizedBox(height: 3),
            Text(
              secondaryValue!,
              style: textTheme.bodyMedium,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
            ),
          ],
        ],
      ),
    );
  }
}
