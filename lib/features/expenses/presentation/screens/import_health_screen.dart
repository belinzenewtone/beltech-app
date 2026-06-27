import 'dart:math' as math;

import 'package:beltech/core/di/database_providers.dart';
import 'package:beltech/core/sync/data_integrity_service.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/core/widgets/app_toast.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_review.dart';
import 'package:beltech/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:beltech/features/expenses/presentation/widgets/import_health_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
          _pipelineCardSection(),
          const SizedBox(height: AppSpacing.sectionGap),
          _alertsSection(),
          const SizedBox(height: AppSpacing.sectionGap),
          _overviewMetricsSection(),
          const SizedBox(height: AppSpacing.sectionGap),
          _queueStatusSection(),
          const SizedBox(height: AppSpacing.sectionGap),
          _breakdownSection(),
          const SizedBox(height: AppSpacing.sectionGap),
          _trendsSection(),
          const SizedBox(height: AppSpacing.sectionGap),
          _actionCardsSection(),
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

  Widget _pipelineCardSection() {
    final metricsAsync = ref.watch(expenseImportMetricsProvider);
    final busy = ref.watch(expenseWriteControllerProvider).isLoading;
    return metricsAsync.when(
      data: (metrics) => ImportPipelineCard(
        metrics: metrics,
        busy: busy,
        onRetry: () async {
          final imported = await ref
              .read(expenseWriteControllerProvider.notifier)
              .replayImportQueue();
          if (!mounted) return;
          ref
              .read(toastProvider.notifier)
              .success('Retried: $imported processed');
        },
      ),
      loading: () => const AppCard(
        tone: AppCardTone.muted,
        child: SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _alertsSection() {
    final metricsAsync = ref.watch(expenseImportMetricsProvider);
    return metricsAsync.when(
      data: (metrics) {
        if (metrics.alerts.isEmpty) return const SizedBox.shrink();
        return AppCard(
          tone: AppCardTone.muted,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Alerts', style: AppTypography.cardTitle(context)),
              const SizedBox(height: AppSpacing.sm),
              for (final alert in metrics.alerts)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alert,
                          style: AppTypography.bodySm(context),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
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
    final busy = ref.watch(expenseWriteControllerProvider).isLoading;
    return metricsAsync.when(
      data: (metrics) {
        final pendingCount = metrics.retryQueueCount + metrics.failedQueueCount;
        return AppCard(
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
              const SizedBox(height: AppSpacing.sm),
              ImportQueueRow(
                icon: Icons.content_copy_rounded,
                label: 'Duplicates Skipped',
                count: metrics.duplicateSkipCount,
                color: AppColors.info,
              ),
              if (pendingCount > 0) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () async {
                            final imported = await ref
                                .read(expenseWriteControllerProvider.notifier)
                                .replayImportQueue();
                            if (!mounted) return;
                            ref
                                .read(toastProvider.notifier)
                                .success('Retried: $imported processed');
                          },
                    icon: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry now'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _breakdownSection() {
    final metricsAsync = ref.watch(expenseImportMetricsProvider);
    return metricsAsync.when(
      data: (metrics) {
        final breakdown = metrics.quarantineReasonBreakdown;
        if (breakdown.isEmpty) return const SizedBox.shrink();
        final entries = breakdown.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return AppCard(
          tone: AppCardTone.muted,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quarantine Breakdown',
                style: AppTypography.cardTitle(context),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final (index, entry) in entries.indexed) ...[
                if (index > 0)
                  const Divider(color: AppColors.borderSubtle, height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: AppTypography.bodyMd(context),
                        ),
                      ),
                      Text(
                        '${entry.value}',
                        style: AppTypography.bodyMd(
                          context,
                        ).copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _trendsSection() {
    final metricsAsync = ref.watch(expenseImportMetricsProvider);
    return metricsAsync.when(
      data: (metrics) {
        final trends = metrics.dailyTrends;
        if (trends.isEmpty) return const SizedBox.shrink();
        final dateFormat = DateFormat.MMMd();
        final maxTotal = trends.map((t) => t.total).fold(0, math.max);
        return AppCard(
          tone: AppCardTone.muted,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('30-Day Trend', style: AppTypography.cardTitle(context)),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 160,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final trend in trends.reversed)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final totalHeight = maxTotal > 0
                                        ? (trend.total / maxTotal) *
                                            constraints.maxHeight
                                        : 0.0;
                                    final quarantineHeight = maxTotal > 0
                                        ? (trend.quarantineCount / maxTotal) *
                                            constraints.maxHeight
                                        : 0.0;
                                    return Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          height: math.max(
                                            totalHeight - quarantineHeight,
                                            0.0,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.accent
                                                .withValues(alpha: 0.5),
                                            borderRadius: const BorderRadius.all(
                                              Radius.circular(AppRadius.sm),
                                            ),
                                          ),
                                        ),
                                        if (quarantineHeight > 0)
                                          Container(
                                            width: double.infinity,
                                            height: quarantineHeight,
                                            decoration: const BoxDecoration(
                                              color: AppColors.danger,
                                              borderRadius:
                                                  BorderRadius.all(
                                                Radius.circular(AppRadius.sm),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateFormat.format(trend.date),
                                style: AppTypography.metaText(context),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TrendLegend(
                    color: AppColors.accent.withValues(alpha: 0.5),
                    label: 'Imported',
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const _TrendLegend(
                    color: AppColors.danger,
                    label: 'Quarantined',
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _actionCardsSection() {
    final metricsAsync = ref.watch(expenseImportMetricsProvider);
    final busy = ref.watch(expenseWriteControllerProvider).isLoading;
    return metricsAsync.when(
      data: (metrics) {
        final hasQuarantine = metrics.quarantineCount > 0;
        final hasReview = metrics.reviewQueueCount > 0;
        final hasFailed = metrics.retryQueueCount > 0 || metrics.failedQueueCount > 0;
        if (!hasQuarantine && !hasReview && !hasFailed) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Actions', style: AppTypography.cardTitle(context)),
            const SizedBox(height: AppSpacing.md),
            if (hasQuarantine)
              _ActionCard(
                icon: Icons.warning_amber_rounded,
                iconColor: AppColors.danger,
                title: 'Review quarantined messages',
                subtitle: '${metrics.quarantineCount} need attention',
                onTap: () => context.pushNamed('quarantine-queue'),
              ),
            if (hasReview) ...[
              const SizedBox(height: AppSpacing.sm),
              _ActionCard(
                icon: Icons.fact_check_rounded,
                iconColor: AppColors.warning,
                title: 'Approve pending review items',
                subtitle: '${metrics.reviewQueueCount} waiting',
                onTap: () {
                  final position = Scrollable.maybeOf(context)?.position;
                  if (position == null) return;
                  position.animateTo(
                    position.maxScrollExtent * 0.6,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ],
            if (hasFailed) ...[
              const SizedBox(height: AppSpacing.sm),
              _ActionCard(
                icon: Icons.refresh_rounded,
                iconColor: AppColors.accent,
                title: 'Retry failed imports',
                subtitle: '${metrics.retryQueueCount + metrics.failedQueueCount} queued',
                busy: busy,
                onTap: () async {
                  final imported = await ref
                      .read(expenseWriteControllerProvider.notifier)
                      .replayImportQueue();
                  if (!mounted) return;
                  ref
                      .read(toastProvider.notifier)
                      .success('Retried: $imported processed');
                },
              ),
            ],
          ],
        );
      },
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

class _TrendLegend extends StatelessWidget {
  const _TrendLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.bodySm(context)),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.busy = false,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: AppCardTone.muted,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: busy ? null : onTap,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: AppRadius.mdAll,
            ),
            child: busy
                ? Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: iconColor,
                      ),
                    ),
                  )
                : Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMd(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.bodySm(context)),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
        ],
      ),
    );
  }
}
