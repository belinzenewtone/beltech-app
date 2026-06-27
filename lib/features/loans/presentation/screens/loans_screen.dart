import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/widgets/app_skeleton.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_empty_state.dart';
import 'package:beltech/core/widgets/app_icon_pill_button.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/loans/domain/entities/loan_item.dart';
import 'package:beltech/features/loans/presentation/widgets/fuliza_lifecycle_card.dart';
import 'package:beltech/features/loans/presentation/widgets/loan_form_sheet.dart';
import 'package:beltech/features/loans/presentation/widgets/loan_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _loansProvider = StreamProvider<List<LoanItem>>(
  (ref) => ref.watch(loansRepositoryProvider).watchLoans(),
);

final _loansTotalOutstandingProvider = FutureProvider<double>(
  (ref) => ref.watch(loansRepositoryProvider).totalOutstanding(),
);

class LoansScreen extends ConsumerWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(_loansProvider);
    final outstandingAsync = ref.watch(_loansTotalOutstandingProvider);
    return SecondaryPageShell(
      title: 'Loans',
      scrollable: false,
      actions: [
        AppIconPillButton(
          icon: Icons.add_rounded,
          label: 'Add',
          tone: AppIconPillTone.accent,
          onPressed: () => _showForm(context, ref),
        ),
      ],
      child: Column(
        children: [
          AppCard(
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_outlined,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Outstanding',
                    style: AppTypography.bodyMd(context),
                  ),
                ),
                Text(
                  outstandingAsync.when(
                    data: (v) => CurrencyFormatter.formatKes(v),
                    loading: () => '...',
                    error: (_, _) => '—',
                  ),
                  style: AppTypography.amount(
                    context,
                  ).copyWith(color: AppColors.warning),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const FulizaLifecycleCard(),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: loansAsync.when(
              data: (loans) {
                if (loans.isEmpty) {
                  return ListView(
                    children: const [
                      SizedBox(
                        width: double.infinity,
                        child: AppEmptyState(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'No loans yet',
                          subtitle: 'Add your first loan',
                        ),
                      ),
                    ],
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: loans.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: LoanItemCard(
                      loan: loans[i],
                      onTap: () => _showForm(context, ref, loans[i]),
                      onDelete: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete loan?'),
                            content: Text(
                              'Remove "${loans[i].name}"?',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Color(0xFFF87171)),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await ref
                              .read(loansRepositoryProvider)
                              .deleteLoan(loans[i].id);
                        }
                      },
                    ),
                  ),
                );
              },
              loading: () => Column(
                children: List.generate(
                  4,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppSkeleton.card(context),
                  ),
                ),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref, [LoanItem? loan]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LoanFormSheet(loan: loan),
    );
  }
}
