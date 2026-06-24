import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/features/income/domain/entities/income_overview.dart';
import 'package:flutter/material.dart';

class IncomeOverviewCards extends StatelessWidget {
  const IncomeOverviewCards({
    super.key,
    required this.overview,
  });

  final IncomeOverview overview;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _IncomeMetricCard(
                label: 'Total Income',
                value: CurrencyFormatter.money(overview.totalIncomeKes),
                accent: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.listGap),
            Expanded(
              child: _IncomeMetricCard(
                label: 'This Month',
                value: CurrencyFormatter.money(overview.currentMonthIncomeKes),
                accent: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.listGap),
        _IncomeMetricCard(
          label: 'Net Cashflow',
          value: CurrencyFormatter.money(overview.netCashflowKes),
          accent: overview.netCashflowKes >= 0
              ? AppColors.success
              : AppColors.danger,
          subtitle:
              'Income ${CurrencyFormatter.money(overview.currentMonthIncomeKes)} vs expenses ${CurrencyFormatter.money(overview.currentMonthExpenseKes)}',
        ),
      ],
    );
  }
}

class _IncomeMetricCard extends StatelessWidget {
  const _IncomeMetricCard({
    required this.label,
    required this.value,
    required this.accent,
    this.subtitle,
  });

  final String label;
  final String value;
  final Color accent;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tone: GlassCardTone.muted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.bodySm(context)),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.amount(context).copyWith(color: accent),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: AppTypography.bodySm(context),
            ),
          ],
        ],
      ),
    );
  }
}
