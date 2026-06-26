import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Inline banner shown on the Finance screen when there is an outstanding
/// Fuliza M-Pesa balance. Tapping it navigates to Settings to manage the limit.
class FulizaBanner extends ConsumerWidget {
  const FulizaBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(fulizaOutstandingBalanceProvider);
    final balance = balanceAsync.valueOrNull ?? 0;
    if (balance <= 0) return const SizedBox.shrink();

    final brightness = Theme.of(context).brightness;

    return GestureDetector(
      onTap: () => context.pushNamed('settings'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 16,
              color: AppColors.warning,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Fuliza balance outstanding',
                    style: AppTypography.bodySm(context).copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatKes(balance),
                    style: AppTypography.bodySm(context).copyWith(
                      color: AppColors.textSecondaryFor(brightness),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.warning.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}
