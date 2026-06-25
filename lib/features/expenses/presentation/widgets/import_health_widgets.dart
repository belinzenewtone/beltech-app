import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_capsule.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_intelligence.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_review.dart';
import 'package:beltech/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ImportMetricTile extends StatelessWidget {
  const ImportMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: AppCardTone.muted,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySm(
              context,
            ).copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.headlineSm(context).copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class ImportQueueRow extends StatelessWidget {
  const ImportQueueRow({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hasItems = count > 0;
    return Row(
      children: [
        Icon(icon, size: 18, color: hasItems ? color : AppColors.textMuted),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: AppTypography.bodyMd(context))),
        Text(
          '$count',
          style: AppTypography.bodyMd(context).copyWith(
            fontWeight: FontWeight.w600,
            color: hasItems ? color : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class ImportReviewItemTile extends ConsumerWidget {
  const ImportReviewItemTile({super.key, required this.item});

  final ExpenseReviewItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: AppTypography.bodyMd(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                CurrencyFormatter.money(item.amountKes),
                style: AppTypography.bodyMd(
                  context,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item.category} · ${(item.confidence * 100).toStringAsFixed(0)}% confidence',
                  style: AppTypography.bodySm(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _actionBtn(
                Icons.check_rounded,
                AppColors.success,
                () => ref
                    .read(expenseWriteControllerProvider.notifier)
                    .approveReviewItem(item.id),
              ),
              const SizedBox(width: 8),
              _actionBtn(
                Icons.close_rounded,
                AppColors.danger,
                () => ref
                    .read(expenseWriteControllerProvider.notifier)
                    .rejectReviewItem(item.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) => Material(
    color: color.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(AppRadius.sm),
    child: InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: color),
      ),
    ),
  );
}

class PaybillItemRow extends StatelessWidget {
  const PaybillItemRow({super.key, required this.profile});
  final PaybillProfile profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet_rounded,
            size: 18,
            color: AppColors.accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: AppTypography.bodyMd(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                Text(profile.paybill, style: AppTypography.bodySm(context)),
              ],
            ),
          ),
          Text(
            '${profile.usageCount}x',
            style: AppTypography.bodySm(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class FulizaItemRow extends StatelessWidget {
  const FulizaItemRow({
    super.key,
    required this.event,
    required this.dateFormat,
  });
  final FulizaLifecycleEvent event;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final isDraw = event.kind == FulizaLifecycleKind.draw;
    final directionColor = isDraw ? AppColors.danger : AppColors.success;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            isDraw ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            size: 18,
            color: directionColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDraw ? 'Draw' : 'Repayment',
                  style: AppTypography.bodyMd(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  dateFormat.format(event.occurredAt),
                  style: AppTypography.bodySm(context),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.money(event.amountKes),
            style: AppTypography.bodyMd(
              context,
            ).copyWith(fontWeight: FontWeight.w600, color: directionColor),
          ),
        ],
      ),
    );
  }
}


/// A top-level health card for the import pipeline.
///
/// Shows a three-column count row (Review · Quarantine · Pending) plus the
/// most recent import timestamp, M-Pesa code, and error. A “Retry now” CTA
/// appears whenever there are retry/failed items waiting.
class ImportPipelineCard extends StatelessWidget {
  const ImportPipelineCard({
    super.key,
    required this.metrics,
    this.busy = false,
    this.onRetry,
  });

  final ExpenseImportMetrics metrics;
  final bool busy;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final pendingCount = metrics.retryQueueCount + metrics.failedQueueCount;
    final hasNoActivity = metrics.reviewQueueCount == 0 &&
        metrics.quarantineCount == 0 &&
        pendingCount == 0 &&
        metrics.lastImportAt == null;
    if (hasNoActivity) {
      return const SizedBox.shrink();
    }
    return AppCard(
      tone: AppCardTone.muted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Import pipeline', style: AppTypography.cardTitle(context)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _PipelineCountColumn(
                  label: 'Review',
                  count: metrics.reviewQueueCount,
                  color: AppColors.warning,
                ),
              ),
              Expanded(
                child: _PipelineCountColumn(
                  label: 'Quarantine',
                  count: metrics.quarantineCount,
                  color: AppColors.danger,
                ),
              ),
              Expanded(
                child: _PipelineCountColumn(
                  label: 'Pending',
                  count: pendingCount,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          if (metrics.lastImportAt != null) ...[
            const SizedBox(height: AppSpacing.md),
            _PipelineInfoRow(
              icon: Icons.schedule_rounded,
              label: 'Last import',
              value: DateFormat.yMMMd().add_jm().format(metrics.lastImportAt!),
            ),
          ],
          if (metrics.lastMpesaCode != null &&
              metrics.lastMpesaCode!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _PipelineInfoRow(
              icon: Icons.confirmation_num_outlined,
              label: 'Last code',
              value: metrics.lastMpesaCode!,
            ),
          ],
          if (metrics.lastError != null &&
              metrics.lastError!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _PipelineInfoRow(
              icon: Icons.error_outline_rounded,
              label: 'Last error',
              value: metrics.lastError!,
              valueColor: AppColors.danger,
            ),
          ],
          if (pendingCount > 0) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: busy ? null : onRetry,
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
  }
}

class _PipelineCountColumn extends StatelessWidget {
  const _PipelineCountColumn({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppCapsule(
          label: '$count',
          color: color,
          variant: AppCapsuleVariant.subtle,
          size: AppCapsuleSize.md,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.bodySm(context).copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _PipelineInfoRow extends StatelessWidget {
  const _PipelineInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: AppTypography.bodySm(context).copyWith(
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodySm(context).copyWith(
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
