import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_motion.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/category_visual.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseTransactionRow extends StatelessWidget {
  const ExpenseTransactionRow({
    super.key,
    required this.dismissKey,
    required this.title,
    required this.amount,
    required this.category,
    required this.occurredAt,
    this.balanceAfterKes,
    this.feeKes,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
    required this.busy,
  });

  final String dismissKey;
  final String title;
  final String amount;
  final String category;
  final DateTime occurredAt;
  final double? balanceAfterKes;
  final double? feeKes;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final visual = categoryVisual(category);
    final amountNumber = amount.replaceFirst('KES ', '');
    final scheme = Theme.of(context).colorScheme;

    // Subtitle: "Category · MMM d, h:mm a" — mirrors Kotlin row
    final dateLabel = DateFormat('MMM d, h:mm a').format(occurredAt);
    final subtitle = '$category · $dateLabel';

    // Secondary info line: balance and/or fee when present
    final hasBalance = balanceAfterKes != null;
    final hasFee = feeKes != null && feeKes! > 0;

    return RepaintBoundary(
      child: Dismissible(
        key: ValueKey(dismissKey),
        direction: busy ? DismissDirection.none : DismissDirection.horizontal,
        movementDuration: AppMotion.swipe(context),
        resizeDuration: AppMotion.resize(context),
        dismissThresholds: const {
          DismissDirection.startToEnd: 0.4,
          DismissDirection.endToStart: 0.4,
        },
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            onEdit();
          } else if (direction == DismissDirection.endToStart) {
            onDelete();
          }
          return false;
        },
        background: const _ExpenseSwipeBackground(
          color: AppColors.warningMuted,
          icon: Icons.edit_outlined,
          label: 'Edit',
          alignment: Alignment.centerLeft,
        ),
        secondaryBackground: const _ExpenseSwipeBackground(
          color: AppColors.dangerMuted,
          icon: Icons.delete_outline,
          label: 'Delete',
          alignment: Alignment.centerRight,
        ),
        child: AppCard(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Category icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: visual.background,
                ),
                child: Icon(visual.icon, color: visual.foreground, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              // Title + subtitle + optional balance/fee line
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.cardTitle(context).copyWith(
                            color: scheme.primary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySm(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasBalance || hasFee) ...[
                      const SizedBox(height: 3),
                      _SecondaryInfo(
                        balanceAfterKes: balanceAfterKes,
                        feeKes: feeKes,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Amount
              Text(
                amountNumber,
                style: AppTypography.bodyMd(context)
                    .copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textMuted.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Secondary info row — balance after and/or transaction cost
// ─────────────────────────────────────────────────────────────────────────────

class _SecondaryInfo extends StatelessWidget {
  const _SecondaryInfo({this.balanceAfterKes, this.feeKes});

  final double? balanceAfterKes;
  final double? feeKes;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45);
    final style = AppTypography.bodySm(context).copyWith(
          color: muted,
          fontSize: 11,
        );

    return Row(
      children: [
        if (balanceAfterKes != null) ...[
          Icon(Icons.account_balance_wallet_outlined, size: 11, color: muted),
          const SizedBox(width: 3),
          Text(
            'Bal ${CurrencyFormatter.money(balanceAfterKes!)}',
            style: style,
          ),
        ],
        if (balanceAfterKes != null && feeKes != null && feeKes! > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Text('·', style: style),
          ),
        if (feeKes != null && feeKes! > 0) ...[
          Icon(Icons.receipt_outlined, size: 11, color: muted),
          const SizedBox(width: 3),
          Text(
            'Fee ${CurrencyFormatter.money(feeKes!)}',
            style: style,
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Swipe action background
// ─────────────────────────────────────────────────────────────────────────────

class _ExpenseSwipeBackground extends StatelessWidget {
  const _ExpenseSwipeBackground({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignment,
  });

  final Color color;
  final IconData icon;
  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: alignment,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: Icon(icon, color: Colors.white, size: 22)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
