import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/glass_card.dart';
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
    final textTheme = Theme.of(context).textTheme;
    final accent = item.isOverLimit
        ? AppColors.danger
        : item.isNearLimit
            ? AppColors.warning
            : AppColors.success;
    final status = item.isOverLimit
        ? 'Over by ${CurrencyFormatter.money(item.spentKes - item.monthlyLimitKes)}'
        : item.isNearLimit
            ? 'Near limit'
            : '${CurrencyFormatter.money(item.remainingKes)} left';

    return GlassCard(
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
                    Text(item.category, style: textTheme.bodyLarge),
                    const SizedBox(height: 4),
                    Text(
                      '${CurrencyFormatter.money(item.spentKes)} of ${CurrencyFormatter.money(item.monthlyLimitKes)}',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: busy ? null : onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                onPressed: busy ? null : onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.listGap),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: item.usageRatio,
              minHeight: 9,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.insights_outlined, color: accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status,
                  style: textTheme.bodySmall?.copyWith(color: accent),
                ),
              ),
              Text(
                '${(item.usageRatio * 100).round()}%',
                style: textTheme.bodySmall?.copyWith(color: accent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
