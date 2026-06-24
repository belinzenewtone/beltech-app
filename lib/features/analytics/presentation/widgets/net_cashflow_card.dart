import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:flutter/material.dart';

/// Net cashflow card showing income, expenses, and net savings.
class NetCashflowCard extends StatelessWidget {
  const NetCashflowCard({
    super.key,
    required this.income,
    required this.expenses,
    required this.period,
  });

  final double income;
  final double expenses;
  final String period;

  @override
  Widget build(BuildContext context) {
    final net = income - expenses;
    final savingsRate = income > 0 ? (net / income * 100).round() : 0;
    final isPositive = net >= 0;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Net Cashflow',
                  style: AppTypography.cardTitle(context),
                ),
                if (income > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isPositive ? AppColors.success : AppColors.warning)
                          .withValues(alpha: 0.12),
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Text(
                      '$savingsRate% saved',
                      style: AppTypography.bodySm(context).copyWith(
                        color: isPositive ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _CashflowItem(
                    label: 'Income',
                    amount: income,
                    color: AppColors.success,
                    icon: Icons.arrow_downward_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _CashflowItem(
                    label: 'Expenses',
                    amount: expenses,
                    color: AppColors.danger,
                    icon: Icons.arrow_upward_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isPositive ? AppColors.success : AppColors.warning)
                    .withValues(alpha: 0.08),
                borderRadius: AppRadius.mdAll,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Net',
                    style: AppTypography.bodySm(context),
                  ),
                  Text(
                    CurrencyFormatter.money(net),
                    style: AppTypography.bodyMd(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: isPositive ? AppColors.success : AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CashflowItem extends StatelessWidget {
  const _CashflowItem({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.bodySm(context).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.money(amount),
          style: AppTypography.bodyMd(context).copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
