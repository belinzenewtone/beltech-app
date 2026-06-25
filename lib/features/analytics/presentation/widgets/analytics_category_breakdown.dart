import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/category_visual.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:beltech/features/analytics/presentation/widgets/category_manager_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsCategoryBreakdown extends ConsumerWidget {
  const AnalyticsCategoryBreakdown({
    super.key,
    required this.categories,
    required this.totalKes,
    required this.registry,
  });

  final List<AnalyticsCategoryShare> categories;
  final double totalKes;
  final List<String> registry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final shareMap = {
      for (final share in categories) share.category: share,
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Categories',
                  style: AppTypography.sectionTitle(context),
                ),
              ),
              TextButton(
                onPressed: () => showCategoryManagerSheet(context),
                child: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (registry.isEmpty)
            Text(
              'No categories configured.',
              style: AppTypography.bodySm(context).copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            ...registry.map((category) {
              final share = shareMap[category];
              final visual = categoryVisual(category);
              final percentage = totalKes <= 0 || share == null
                  ? 0.0
                  : (share.totalKes / totalKes).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: visual.background,
                      child: Icon(
                        visual.icon,
                        color: visual.foreground,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMd(context),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage,
                              minHeight: 6,
                              backgroundColor:
                                  AppColors.surfaceMutedFor(brightness),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                visual.foreground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.money(share?.totalKes ?? 0),
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          style: AppTypography.bodySm(context).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${(percentage * 100).toStringAsFixed(0)}%',
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          style: AppTypography.bodySm(context).copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
