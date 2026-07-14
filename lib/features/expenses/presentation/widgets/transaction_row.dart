import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_motion.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/category_visual.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:flutter/material.dart';

class ExpenseTransactionRow extends StatelessWidget {
  const ExpenseTransactionRow({
    super.key,
    required this.dismissKey,
    required this.title,
    required this.amount,
    required this.category,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
    required this.busy,
  });

  final String dismissKey;
  final String title;
  final String amount;
  final String category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final visual = categoryVisual(category);
    final amountNumber = amount.replaceFirst('KES ', '');

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: visual.background,
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
                    const SizedBox(height: 4),
                    Text(
                      category,
                      style: AppTypography.bodySm(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                amountNumber,
                style: AppTypography.bodyMd(
                  context,
                ).copyWith(fontWeight: FontWeight.w700),
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
