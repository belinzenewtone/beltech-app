import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:flutter/material.dart';

/// Spend Anatomy card — shows distribution of transaction sizes.
/// Micro < KES 500 / Medium KES 500–2k / Large ≥ KES 2k.
/// Mirrors Kotlin "Spend Anatomy" in InsightsScreen Insights tab.
class SpendAnatomyCard extends StatelessWidget {
  const SpendAnatomyCard({super.key, required this.snapshot});

  final AnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final total = snapshot.totalTxCount;
    if (total == 0) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spend Anatomy',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'How your $total transactions break down by size',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.55),
                ),
          ),
          const SizedBox(height: 16),
          _AnatomyBar(
            label: 'Micro',
            sublabel: '< KES 500',
            count: snapshot.microTxCount,
            total: total,
            color: AppColors.success,
          ),
          const SizedBox(height: 10),
          _AnatomyBar(
            label: 'Medium',
            sublabel: 'KES 500–2k',
            count: snapshot.mediumTxCount,
            total: total,
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 10),
          _AnatomyBar(
            label: 'Large',
            sublabel: '≥ KES 2k',
            count: snapshot.largeTxCount,
            total: total,
            color: AppColors.danger,
          ),
        ],
      ),
    );
  }
}

class _AnatomyBar extends StatelessWidget {
  const _AnatomyBar({
    required this.label,
    required this.sublabel,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final String sublabel;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;
    final pct = (fraction * 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                Text(
                  sublabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      ),
                ),
              ],
            ),
            Text(
              '$count tx · $pct%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
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
            minHeight: 7,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
