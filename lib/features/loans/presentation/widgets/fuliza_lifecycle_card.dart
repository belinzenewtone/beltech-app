import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_intelligence.dart';
import 'package:beltech/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Summary card for M-Pesa Fuliza lifecycle shown on the Loans screen.
class FulizaLifecycleCard extends ConsumerWidget {
  const FulizaLifecycleCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(fulizaOutstandingBalanceProvider);
    final eventsAsync = ref.watch(expenseFulizaLifecycleProvider);

    final balance = balanceAsync.valueOrNull ?? 0;
    final events = eventsAsync.valueOrNull ?? const <FulizaLifecycleEvent>[];

    if (balance <= 0 && events.isEmpty) {
      return const SizedBox.shrink();
    }

    final brightness = Theme.of(context).brightness;
    final latestEvent = events.isNotEmpty ? events.first : null;

    return AppCard(
      tone: AppCardTone.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Fuliza M-PESA',
                style: AppTypography.bodyMd(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Outstanding balance',
            style: AppTypography.bodySm(
              context,
            ).copyWith(color: AppColors.textSecondaryFor(brightness)),
          ),
          const SizedBox(height: 2),
          Text(
            CurrencyFormatter.formatKes(balance),
            style: AppTypography.amount(context).copyWith(
              color: AppColors.warning,
            ),
          ),
          if (latestEvent != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.smAll,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _eventLabel(latestEvent.kind),
                    style: AppTypography.bodySm(context),
                  ),
                  Text(
                    CurrencyFormatter.formatKes(latestEvent.amountKes),
                    style: AppTypography.bodySm(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: _eventColor(latestEvent.kind),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _eventLabel(FulizaLifecycleKind kind) => switch (kind) {
    FulizaLifecycleKind.draw => 'Latest draw',
    FulizaLifecycleKind.repayment => 'Latest repayment',
  };

  Color _eventColor(FulizaLifecycleKind kind) => switch (kind) {
    FulizaLifecycleKind.draw => AppColors.danger,
    FulizaLifecycleKind.repayment => AppColors.success,
  };
}
