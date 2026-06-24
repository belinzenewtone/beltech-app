import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_motion.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/category_visual.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_capsule.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:flutter/material.dart';

enum _TxTagKind { received, sent, paybill, goods, auto }

class _TxTag {
  const _TxTag(this.kind);

  final _TxTagKind kind;

  String get label => switch (kind) {
    _TxTagKind.received => 'Received',
    _TxTagKind.sent => 'Sent',
    _TxTagKind.paybill => 'Paybill',
    _TxTagKind.goods => 'Goods',
    _TxTagKind.auto => 'Auto',
  };

  Color get color => switch (kind) {
    _TxTagKind.received => AppColors.success,
    _TxTagKind.sent => AppColors.accent,
    _TxTagKind.paybill => AppColors.categoryBill,
    _TxTagKind.goods => AppColors.teal,
    _TxTagKind.auto => AppColors.warning,
  };

  IconData get icon => switch (kind) {
    _TxTagKind.received => Icons.arrow_downward_rounded,
    _TxTagKind.sent => Icons.arrow_upward_rounded,
    _TxTagKind.paybill => Icons.receipt_long_rounded,
    _TxTagKind.goods => Icons.shopping_bag_outlined,
    _TxTagKind.auto => Icons.flash_on_rounded,
  };

  static _TxTag? infer(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('received') || lower.contains('you have received')) {
      return const _TxTag(_TxTagKind.received);
    }
    if (lower.contains('fuliza') || lower.contains('m-shwari')) {
      return const _TxTag(_TxTagKind.auto);
    }
    if (lower.contains('paybill') || lower.contains('pay bill')) {
      return const _TxTag(_TxTagKind.paybill);
    }
    if (lower.contains('buy goods') ||
        lower.contains('buygoods') ||
        lower.contains(' till ')) {
      return const _TxTag(_TxTagKind.goods);
    }
    if (lower.contains('sent to') ||
        lower.contains('send money') ||
        lower.contains('transferred')) {
      return const _TxTag(_TxTagKind.sent);
    }
    return null;
  }
}

class ExpenseTransactionRow extends StatelessWidget {
  const ExpenseTransactionRow({
    super.key,
    required this.dismissKey,
    required this.title,
    required this.amount,
    required this.category,
    required this.occurredAt,
    this.balanceAfterKes,
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final visual = categoryVisual(category);
    final tag = _TxTag.infer(title);

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
        child: GlassCard(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: visual.background,
                  border: Border.all(
                    color: visual.foreground.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(visual.icon, color: visual.foreground, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.cardTitle(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (tag != null)
                          AppCapsule(
                            label: tag.label,
                            color: tag.color,
                            variant: AppCapsuleVariant.subtle,
                            size: AppCapsuleSize.sm,
                            icon: tag.icon,
                          ),
                        AppCapsule(
                          label: category,
                          color: visual.foreground,
                          variant: AppCapsuleVariant.subtle,
                          size: AppCapsuleSize.sm,
                        ),
                        _TimeChip(occurredAt: occurredAt),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: AppTypography.bodyMd(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                  if (balanceAfterKes != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Bal ${CurrencyFormatter.money(balanceAfterKes!)}',
                      style: AppTypography.metaText(
                        context,
                      ).copyWith(color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textMuted.withValues(alpha: 0.9),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.occurredAt});

  final DateTime occurredAt;

  @override
  Widget build(BuildContext context) {
    final hour = occurredAt.hour.toString().padLeft(2, '0');
    final minute = occurredAt.minute.toString().padLeft(2, '0');
    return AppCapsule(
      label: '$hour:$minute',
      color: AppColors.textMuted,
      variant: AppCapsuleVariant.subtle,
      size: AppCapsuleSize.sm,
      icon: Icons.schedule_rounded,
    );
  }
}

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
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      alignment: alignment,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: Icon(icon, color: Colors.white, size: 22)),
          const SizedBox(height: 3),
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
