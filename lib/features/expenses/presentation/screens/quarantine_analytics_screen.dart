import 'package:beltech/core/di/expenses_providers.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuarantineAnalyticsScreen extends ConsumerWidget {
  const QuarantineAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quarantineDataAsync = ref.watch(quarantineQueueNotifierProvider);

    return SecondaryPageShell(
      title: 'Quarantine Analytics',
      child: quarantineDataAsync.when(
        data: (items) => _buildAnalytics(context, items),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildAnalytics(BuildContext context, List<dynamic> items) {
    final total = items.length;
    if (total == 0) {
      return Center(
        child: Text(
          'No quarantine data',
          style: AppTypography.bodyMd(
            context,
          ).copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final approvedCount = items
        .where((item) => item.status == 'approved')
        .length;
    final rejectedCount = items
        .where((item) => item.status == 'rejected')
        .length;
    final pendingCount = total - approvedCount - rejectedCount;

    final approvalRate = total > 0
        ? (approvedCount / total * 100).toStringAsFixed(0)
        : '0';

    final highConfidence = items
        .where((item) => item.confidence == 'high')
        .length;
    final mediumConfidence = items
        .where((item) => item.confidence == 'medium')
        .length;
    final lowConfidence = items
        .where((item) => item.confidence == 'low')
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          tone: AppCardTone.muted,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      'Total',
                      total.toString(),
                      AppColors.accent,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      'Approved',
                      approvedCount.toString(),
                      AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      'Rejected',
                      rejectedCount.toString(),
                      AppColors.danger,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      'Pending',
                      pendingCount.toString(),
                      AppColors.warning,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppCard(
          tone: AppCardTone.muted,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Approval Rate', style: AppTypography.cardTitle(context)),
              const SizedBox(height: 8),
              Text(
                '$approvalRate%',
                style: AppTypography.amount(
                  context,
                ).copyWith(color: AppColors.success),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: AppRadius.smAll,
                child: LinearProgressIndicator(
                  value: approvedCount / total,
                  minHeight: 6,
                  backgroundColor: AppColors.danger.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppCard(
          tone: AppCardTone.muted,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Confidence', style: AppTypography.cardTitle(context)),
              const SizedBox(height: AppSpacing.sm),
              _buildConfidenceBar(
                context,
                'High',
                highConfidence,
                total,
                AppColors.success,
              ),
              const SizedBox(height: 10),
              _buildConfidenceBar(
                context,
                'Medium',
                mediumConfidence,
                total,
                AppColors.warning,
              ),
              const SizedBox(height: 10),
              _buildConfidenceBar(
                context,
                'Low',
                lowConfidence,
                total,
                AppColors.danger,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTypography.amount(context).copyWith(color: color),
        ),
        Text(label, style: AppTypography.bodySm(context)),
      ],
    );
  }

  Widget _buildConfidenceBar(
    BuildContext context,
    String label,
    int count,
    int total,
    Color color,
  ) {
    final percentage = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodySm(context)),
            Text(
              '$count',
              style: AppTypography.bodySm(
                context,
              ).copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 4,
            backgroundColor: AppColors.surface.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
