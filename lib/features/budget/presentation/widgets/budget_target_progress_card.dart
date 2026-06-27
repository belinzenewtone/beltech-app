import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/budget/domain/entities/budget_target_progress.dart';
import 'package:flutter/material.dart';

class BudgetTargetProgressCard extends StatelessWidget {
  const BudgetTargetProgressCard({
    super.key,
    required this.item,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  final BudgetTargetProgress item;
  final bool busy;
  final Future<void> Function() onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final accent = item.isOverLimit
        ? AppColors.danger
        : item.isNearLimit
        ? AppColors.warning
        : AppColors.accent;
    final status = item.isOverLimit
        ? 'Over by ${CurrencyFormatter.money(item.spentKes - item.monthlyLimitKes)}'
        : item.isNearLimit
        ? 'Near limit'
        : '${CurrencyFormatter.money(item.remainingKes)} left';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.category,
                      style: AppTypography.cardTitle(context),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${CurrencyFormatter.money(item.spentKes)} of ${CurrencyFormatter.money(item.monthlyLimitKes)}',
                      style: AppTypography.bodySm(context),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: busy ? null : onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
              IconButton(
                onPressed: busy ? null : onDelete,
                icon: const Icon(Icons.delete_outline, size: 20),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: item.usageRatio,
              minHeight: 6,
              backgroundColor: AppColors.surfaceMutedFor(brightness),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            status,
            style: AppTypography.bodySm(context).copyWith(color: accent),
          ),
        ],
      ),
    );
  }
}
