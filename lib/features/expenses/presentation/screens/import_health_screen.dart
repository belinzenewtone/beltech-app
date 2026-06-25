import 'package:beltech/core/di/database_providers.dart';
import 'package:beltech/core/sync/data_integrity_service.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_review.dart';
import 'package:beltech/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:beltech/features/expenses/presentation/widgets/import_health_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final class _ImportOverview {
  const _ImportOverview({
    required this.totalProcessed,
    required this.successRate,
    required this.metrics,
  });
  final int totalProcessed;
  final double successRate;
  final ExpenseImportMetrics metrics;
}

final _importOverviewProvider = FutureProvider<_ImportOverview>((ref) async {
  final metrics = await ref.watch(expenseImportMetricsProvider.future);
  final snapshot = await ref.watch(expensesSnapshotProvider.future);
  final totalProcessed = snapshot.transactions.length;
  final totalItems =
      totalProcessed +
      metrics.reviewQueueCount +
      metrics.quarantineCount +
      metrics.retryQueueCount +
      metrics.failedQueueCount;
  final successRate = totalItems > 0
      ? (totalProcessed / totalItems * 100)
      : 100.0;
  return _ImportOverview(
    totalProcessed: totalProcessed,
    successRate: successRate,
    metrics: metrics,
  );
});

class ImportHealthScreen extends ConsumerStatefulWidget {
  const ImportHealthScreen({super.key});

  @override
  ConsumerState<ImportHealthScreen> createState() => _ImportHealthScreenState();
}

class _ImportHealthScreenState extends ConsumerState<ImportHealthScreen> {
  @override
  Widget build(BuildContext context) {
    return SecondaryPageShell(
      title: 'Import Health',
      child: Column(
        children: [
          _overviewMetricsSection(),
          const SizedBox(height: AppSpacing.sectionGap),
          _queueStatusSection(),
          const SizedBox(height: AppSpacing.sectionGap),
          _reviewItemsSection(),
          const SizedBox(height: AppSpacing.sectionGap),
          _paybillSection(),
          const SizedBox(height: AppSpacing.sectionGap),
          _fulizaSection(),
          _integritySection(),
        ],
      ),
    );
  }

  Widget _overviewMetricsSection() {
    final overviewAsync = ref.watch(_importOverviewProvider);
    return overviewAsync.when(
      data: (overview) {
        final rateColor = overview.successRate >= 90
            ? AppColors.success
            : overview.successRate >= 70
            ? AppColors.warning
            : AppColors.danger;
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Overview', style: AppTypography.cardTitle(context)),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: ImportMetricTile(
                      label: 'Total Processed',
                      value: '${overview.totalProcessed}',
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ImportMetricTile(
                      label: 'Success Rate',
                      value: '${overview.successRate.toStringAsFixed(0)}%',
                      color: rateColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: ImportMetricTile(
                      label: 'Pending Review',
                      value: '${overview.metrics.reviewQueueCount}',
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ImportMetricTile(
                      label: 'Quarantine',
                      value: '${overview.metrics.quarantineCount}',
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error: $e', style: AppTypography.bodySm(context)),
      ),
    );
  }

  Widget _queueStatusSection() {
    final metricsAsync = ref.watch(expenseImportMetricsProvider);
    return metricsAsync.when(
      data: (metrics) => AppCard(
        tone: AppCardTone.muted,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Queue Status', style: AppTypography.cardTitle(context)),
            const SizedBox(height: AppSpacing.md),
            ImportQueueRow(
              icon: Icons.refresh_rounded,
              label: 'Retry Queue',
              count: metrics.retryQueueCount,
              color: AppColors.warning,
            ),
            const SizedBox(height: AppSpacing.sm),
            ImportQueueRow(
              icon: Icons.error_outline_rounded,
              label: 'Failed',
              count: metrics.failedQueueCount,
              color: AppColors.danger,
            ),
          ],
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _reviewItemsSection() {
    final reviewAsync = ref.watch(expenseReviewQueueProvider);
    return reviewAsync.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return AppCard(
          tone: AppCardTone.muted,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Review Items', style: AppTypography.cardTitle(context)),
              const SizedBox(height: AppSpacing.sm),
              for (final (index, item) in items.indexed) ...[
                if (index > 0)
                  const Divider(color: AppColors.borderSubtle, height: 1),
                ImportReviewItemTile(item: item),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _paybillSection() {
    final paybillAsync = ref.watch(expensePaybillProfilesProvider);
    return paybillAsync.when(
      data: (profiles) {
        if (profiles.isEmpty) return const SizedBox.shrink();
        return AppCard(
          tone: AppCardTone.muted,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Paybill Registry', style: AppTypography.cardTitle(context)),
              const SizedBox(height: AppSpacing.sm),
              for (final (index, p) in profiles.indexed) ...[
                if (index > 0)
                  const Divider(color: AppColors.borderSubtle, height: 1),
                PaybillItemRow(profile: p),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _fulizaSection() {
    final fulizaAsync = ref.watch(expenseFulizaLifecycleProvider);
    final dateFormat = DateFormat.yMMMd();
    return fulizaAsync.when(
      data: (events) {
        if (events.isEmpty) return const SizedBox.shrink();
        return AppCard(
          tone: AppCardTone.muted,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fuliza Lifecycle', style: AppTypography.cardTitle(context)),
              const SizedBox(height: AppSpacing.sm),
              for (final (index, e) in events.indexed) ...[
                if (index > 0)
                  const Divider(color: AppColors.borderSubtle, height: 1),
                FulizaItemRow(event: e, dateFormat: dateFormat),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _integritySection() {
    final store = ref.watch(appDriftStoreProvider);
    return FutureBuilder<IntegrityReport>(
      future: DataIntegrityService(store).runChecks(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final report = snapshot.data!;
        return Column(
          children: [
            const SizedBox(height: AppSpacing.sectionGap),
            AppCard(
              tone: AppCardTone.muted,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Data Integrity',
                        style: AppTypography.cardTitle(context),
                      ),
                      const Spacer(),
                      Icon(
                        report.isHealthy ? Icons.check_circle : Icons.warning,
                        color: report.isHealthy
                            ? AppColors.success
                            : AppColors.danger,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...report.checks.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            c.passed ? Icons.check : Icons.close,
                            size: 14,
                            color: c.passed
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c.message,
                              style: AppTypography.bodySm(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
