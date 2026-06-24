import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.label(context)),
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
        Expanded(
          child: Text(label, style: AppTypography.bodyMd(context)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: hasItems
                ? color.withValues(alpha: 0.12)
                : AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            '$count',
            style: AppTypography.bodySm(context).copyWith(
              fontWeight: FontWeight.w600,
              color: hasItems ? color : AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class ImportReviewItemTile extends ConsumerWidget {
  const ImportReviewItemTile({super.key, required this.item});

  final ExpenseReviewItem item;

  Color _getConfidenceColor() {
    if (item.confidence >= 0.8) return AppColors.success;
    if (item.confidence >= 0.5) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confidenceColor = _getConfidenceColor();
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
                  style: AppTypography.bodyMd(context)
                      .copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                CurrencyFormatter.money(item.amountKes),
                style: AppTypography.bodyMd(context)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.categoryColorFor(item.category)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  item.category,
                  style: AppTypography.metaText(context).copyWith(
                    color: AppColors.categoryColorFor(item.category),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Confidence',
                            style: AppTypography.metaText(context)),
                        const SizedBox(width: 4),
                        Text(
                          '${(item.confidence * 100).toStringAsFixed(0)}%',
                          style: AppTypography.metaText(context).copyWith(
                            color: confidenceColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: item.confidence.clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: AppColors.surfaceHeroControl,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(confidenceColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _actionBtn(Icons.check_rounded, AppColors.success,
                  () => ref
                      .read(expenseWriteControllerProvider.notifier)
                      .approveReviewItem(item.id)),
              const SizedBox(width: 4),
              _actionBtn(Icons.close_rounded, AppColors.danger,
                  () => ref
                      .read(expenseWriteControllerProvider.notifier)
                      .rejectReviewItem(item.id)),
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                size: 18, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.displayName,
                    style: AppTypography.bodyMd(context)
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(profile.paybill,
                    style: AppTypography.bodySm(context)),
              ],
            ),
          ),
          Text('${profile.usageCount}x',
              style: AppTypography.bodySm(context).copyWith(
                  fontWeight: FontWeight.w600, color: AppColors.accent)),
        ],
      ),
    );
  }
}

class FulizaItemRow extends StatelessWidget {
  const FulizaItemRow({super.key, required this.event, required this.dateFormat});
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
            isDraw
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            size: 18,
            color: directionColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isDraw ? 'Fuliza Draw' : 'Fuliza Repayment',
                    style: AppTypography.bodyMd(context)
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(dateFormat.format(event.occurredAt),
                    style: AppTypography.bodySm(context)),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.money(event.amountKes),
            style: AppTypography.bodyMd(context)
                .copyWith(fontWeight: FontWeight.w600, color: directionColor),
          ),
        ],
      ),
    );
  }
}
