import 'package:beltech/core/di/expenses_providers.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text('No quarantine data yet', style: AppTypography.bodySm(context)),
          ],
        ),
      );
    }

    final approvedCount = items.where((item) => item.status == 'approved').length;
    final rejectedCount = items.where((item) => item.status == 'rejected').length;
    final pendingCount = total - approvedCount - rejectedCount;

    final approvalRate = total > 0 ? (approvedCount / total * 100).toStringAsFixed(1) : '0.0';
    final rejectionRate = total > 0 ? (rejectedCount / total * 100).toStringAsFixed(1) : '0.0';

    // Confidence distribution
    final highConfidence = items.where((item) => item.confidence == 'high').length;
    final mediumConfidence = items.where((item) => item.confidence == 'medium').length;
    final lowConfidence = items.where((item) => item.confidence == 'low').length;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sectionGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Key Metrics
            Text(
              'Overview',
              style: AppTypography.sectionTitle(context),
            ),
            const SizedBox(height: AppSpacing.listGap),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.listGap,
              mainAxisSpacing: AppSpacing.listGap,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMetricCard(
                  context,
                  'Total Items',
                  total.toString(),
                  AppColors.accent,
                  Icons.inbox,
                ),
                _buildMetricCard(
                  context,
                  'Approved',
                  approvedCount.toString(),
                  AppColors.success,
                  Icons.check_circle,
                ),
                _buildMetricCard(
                  context,
                  'Rejected',
                  rejectedCount.toString(),
                  AppColors.danger,
                  Icons.cancel,
                ),
                _buildMetricCard(
                  context,
                  'Pending',
                  pendingCount.toString(),
                  AppColors.warning,
                  Icons.hourglass_bottom,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // Approval Rate Gauge
            Text(
              'Approval Metrics',
              style: AppTypography.sectionTitle(context),
            ),
            const SizedBox(height: AppSpacing.listGap),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Approval Rate', style: AppTypography.bodySm(context)),
                          const SizedBox(height: 8),
                          Text(
                            '$approvalRate%',
                            style: AppTypography.sectionTitle(context)
                                .copyWith(color: AppColors.success),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rejection Rate', style: AppTypography.bodySm(context)),
                          const SizedBox(height: 8),
                          Text(
                            '$rejectionRate%',
                            style: AppTypography.sectionTitle(context)
                                .copyWith(color: AppColors.danger),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: approvedCount / total,
                      minHeight: 8,
                      backgroundColor: AppColors.danger.withValues(alpha: 0.2),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.success),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // Confidence Distribution
            Text(
              'Confidence Distribution',
              style: AppTypography.sectionTitle(context),
            ),
            const SizedBox(height: AppSpacing.listGap),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildConfidenceBar(
                    context,
                    'High Confidence',
                    highConfidence,
                    total,
                    AppColors.success,
                  ),
                  const SizedBox(height: 12),
                  _buildConfidenceBar(
                    context,
                    'Medium Confidence',
                    mediumConfidence,
                    total,
                    AppColors.warning,
                  ),
                  const SizedBox(height: 12),
                  _buildConfidenceBar(
                    context,
                    'Low Confidence',
                    lowConfidence,
                    total,
                    AppColors.danger,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // Statistics
            Text(
              'Statistics',
              style: AppTypography.sectionTitle(context),
            ),
            const SizedBox(height: AppSpacing.listGap),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildStatRow(
                    'Average Processing Rate',
                    total > 0
                        ? '${(total / (approvedCount + rejectedCount + 1)).toStringAsFixed(1)} items/action'
                        : 'N/A',
                  ),
                  const Divider(height: 16),
                  _buildStatRow(
                    'Approval Success Rate',
                    approvalRate == '0.0'
                        ? 'No data'
                        : '${approvedCount}/${approvedCount + rejectedCount} items',
                  ),
                  const Divider(height: 16),
                  _buildStatRow(
                    'Items Under Review',
                    '$pendingCount item${pendingCount == 1 ? '' : 's'}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.bodySm(context)),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTypography.sectionTitle(context).copyWith(color: color),
              ),
            ],
          ),
        ],
      ),
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
              '$count (${(percentage * 100).toStringAsFixed(0)}%)',
              style: AppTypography.bodySm(context),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 6,
            backgroundColor: AppColors.surface.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
