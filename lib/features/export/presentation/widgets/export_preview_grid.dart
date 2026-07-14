import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_skeleton.dart';
import 'package:beltech/features/export/domain/entities/export_result.dart';
import 'package:flutter/material.dart';

class ExportPreviewGrid extends StatelessWidget {
  const ExportPreviewGrid({
    super.key,
    required this.counts,
    this.isLoading = false,
  });

  final Map<ExportScope, int>? counts;
  final bool isLoading;

  static const _scopes = [
    ExportScope.expenses,
    ExportScope.tasks,
    ExportScope.events,
    ExportScope.budgets,
    ExportScope.incomes,
    ExportScope.recurring,
  ];

  @override
  Widget build(BuildContext context) {
    final total = counts?[ExportScope.all] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Preview', style: AppTypography.cardTitle(context)),
            const Spacer(),
            if (isLoading)
              const SizedBox(
                width: 80,
                height: 14,
                child: AppSkeleton(width: 80, height: 14, borderRadius: 6),
              )
            else
              Text(
                'Total items: $total',
                style: AppTypography.bodySm(
                  context,
                ).copyWith(color: AppColors.textSecondary),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (isLoading || counts == null)
          const _SkeletonGrid()
        else
          _buildGrid(context),
      ],
    );
  }

  Widget _buildGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      children: _scopes.map((scope) {
        final count = counts![scope] ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$count',
              style: AppTypography.amount(
                context,
              ).copyWith(color: AppColors.accent, fontSize: 22),
            ),
            const SizedBox(height: 2),
            Text(
              exportScopePreviewLabel(scope),
              style: AppTypography.bodySm(
                context,
              ).copyWith(color: AppColors.textSecondary),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      children: List.generate(
        6,
        (_) => const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 22,
              child: AppSkeleton(width: 40, height: 22, borderRadius: 6),
            ),
            SizedBox(height: 6),
            SizedBox(
              width: 80,
              height: 12,
              child: AppSkeleton(width: 80, height: 12, borderRadius: 6),
            ),
          ],
        ),
      ),
    );
  }
}
