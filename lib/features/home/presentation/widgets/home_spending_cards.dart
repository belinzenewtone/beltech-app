import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/category_visual.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_capsule.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/home/domain/entities/home_overview.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'home_spending_cards_balance.dart';
part 'home_spending_cards_insights.dart';

class HomeSpendSnapshotStrip extends StatelessWidget {
  const HomeSpendSnapshotStrip({super.key, required this.overview});
  final HomeOverview overview;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildCell(context, 'Today', overview.todayKes),
        const SizedBox(width: AppSpacing.sm),
        _buildCell(context, 'Week', overview.weekKes),
      ],
    );
  }

  Widget _buildCell(BuildContext context, String label, double amount) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        borderRadius: AppRadius.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.label(context)),
            const SizedBox(height: AppSpacing.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                CurrencyFormatter.money(amount),
                style: AppTypography.amount(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single transaction row used in the dashboard recent transactions list.
class HomeDashboardTransactionTile extends StatelessWidget {
  const HomeDashboardTransactionTile({super.key, required this.tx});
  final HomeTransaction tx;

  @override
  Widget build(BuildContext context) {
    final visual = categoryVisual(tx.category);
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(visual.icon, color: AppColors.textSecondary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  style: AppTypography.cardTitle(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs / 2),
                Text(
                  tx.category,
                  style: AppTypography.bodySm(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.money(tx.amountKes),
            style: AppTypography.bodyMd(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
          ),
        ],
      ),
    );
  }
}
