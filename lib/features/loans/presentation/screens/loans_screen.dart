import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/widgets/app_skeleton.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_empty_state.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/loans/domain/entities/loan_item.dart';
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Loan'),
      ),
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
                    error: (_, __) => '—',
                  ),
                  style: AppTypography.amount(
                    context,
                  ).copyWith(color: AppColors.warning),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: loansAsync.when(
              data: (loans) {
                if (loans.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenHorizontal,
                      ),
                      child: AppEmptyState(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'No loans yet',
                        subtitle: 'Add your first loan',
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: loans.length,
                  itemBuilder: (context, i) => Padding(
                    padding: EdgeInsets.only(
                      bottom: i < loans.length - 1 ? AppSpacing.sm : 0,
                    ),
                    child: LoanItemCard(
                      loan: loans[i],
                      onTap: () => _showForm(context, ref, loans[i]),
                    ),
                  ),
                );
              },
              loading: () => Column(
                children: List.generate(4, (_) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppSkeleton.card(context),
                )),
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
