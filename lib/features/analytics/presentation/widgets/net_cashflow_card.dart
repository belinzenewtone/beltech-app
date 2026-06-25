import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
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
    final isPositive = net >= 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Net Cashflow', style: AppTypography.cardTitle(context)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _CashflowItem(
                  label: 'Income',
                  amount: income,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _CashflowItem(
                  label: 'Expenses',
                  amount: expenses,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Net', style: AppTypography.bodySm(context)),
              Text(
                CurrencyFormatter.money(net),
                style: AppTypography.bodyMd(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: isPositive ? AppColors.success : AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CashflowItem extends StatelessWidget {
  const _CashflowItem({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySm(
            context,
          ).copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.money(amount),
          style: AppTypography.bodyMd(
            context,
          ).copyWith(fontWeight: FontWeight.w600, color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
