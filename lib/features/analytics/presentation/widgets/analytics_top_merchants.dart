import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AnalyticsTopMerchants extends StatelessWidget {
  const AnalyticsTopMerchants({super.key, required this.merchants});

  final List<AnalyticsMerchantShare> merchants;

  @override
  Widget build(BuildContext context) {
    if (merchants.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Merchants',
            style: AppTypography.sectionTitle(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...merchants.map((m) => _MerchantRow(merchant: m)),
        ],
      ),
    );
  }
}

class _MerchantRow extends StatelessWidget {
  const _MerchantRow({required this.merchant});

  final AnalyticsMerchantShare merchant;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.pushNamed('merchant-detail', extra: merchant.merchant),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    merchant.merchant,
                    style: AppTypography.bodyMd(
                      context,
                    ).copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${merchant.transactionCount} transaction${merchant.transactionCount == 1 ? '' : 's'}',
                    style: AppTypography.bodySm(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.formatKes(merchant.totalKes),
              style: AppTypography.bodyMd(
                context,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
