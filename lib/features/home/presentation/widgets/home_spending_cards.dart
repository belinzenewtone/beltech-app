import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/category_visual.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_capsule.dart';
import 'package:beltech/core/widgets/glass_card.dart';
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
    // Determine month approximation since data layer doesn't expose it directly yet
    final approxMonthKes = overview.weekKes * 4.2;

    return Row(
      children: [
        _buildCell(context, 'Today', overview.todayKes),
        const SizedBox(width: AppSpacing.sm),
        _buildCell(context, 'Week', overview.weekKes),
        const SizedBox(width: AppSpacing.sm),
        _buildCell(context, 'Month', approxMonthKes),
      ],
    );
  }

  Widget _buildCell(BuildContext context, String label, double amount) {
    final brightness = Theme.of(context).brightness;

    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        borderRadius: AppRadius.xl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondaryFor(brightness),
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                CurrencyFormatter.money(amount),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryFor(brightness),
                  letterSpacing: -0.2,
                ),
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
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: visual.background,
              shape: BoxShape.circle,
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
                Text(tx.title,
                    style: AppTypography.cardTitle(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                  tx.category,
                  style: AppTypography.label(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.money(tx.amountKes),
            style: AppTypography.bodyMd(context)
                .copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
          ),
        ],
      ),
    );
  }
}
