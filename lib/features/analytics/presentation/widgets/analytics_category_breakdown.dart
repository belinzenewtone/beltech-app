import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/category_visual.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:flutter/material.dart';

class AnalyticsCategoryBreakdown extends StatelessWidget {
  const AnalyticsCategoryBreakdown({super.key, required this.categories});

  final List<AnalyticsCategoryShare> categories;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (categories.isEmpty)
            const Text('No spending data available.')
          else
            for (int i = 0; i < categories.take(8).length; i++) ...[
              if (i > 0) ...[
                const Divider(height: 1, thickness: 1, color: AppColors.border),
                const SizedBox(height: AppSpacing.sm),
              ],
              _CategoryRow(entry: categories[i]),
              if (i < categories.take(8).length - 1)
                const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.entry});

  final AnalyticsCategoryShare entry;

  @override
  Widget build(BuildContext context) {
    final visual = categoryVisual(entry.category);
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: visual.background,
          child: Icon(visual.icon, color: visual.foreground, size: 16),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            entry.category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMd(context),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.money(entry.totalKes),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: AppTypography.bodySm(context),
            ),
            Text(
              '${entry.percentage.toStringAsFixed(1)}%',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: AppTypography.bodySm(context),
            ),
          ],
        ),
      ],
    );
  }
}
