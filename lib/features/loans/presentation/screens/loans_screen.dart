import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_empty_state.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/features/loans/domain/entities/loan_item.dart';
import 'package:beltech/features/loans/presentation/widgets/loan_form_sheet.dart';
import 'package:beltech/features/loans/presentation/widgets/loan_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _loansProvider = StreamProvider<List<LoanItem>>((ref) =>
    ref.watch(loansRepositoryProvider).watchLoans());

final _loansTotalOutstandingProvider = FutureProvider<double>((ref) =>
    ref.watch(loansRepositoryProvider).totalOutstanding());

class LoansScreen extends ConsumerWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(_loansProvider);
    final outstandingAsync = ref.watch(_loansTotalOutstandingProvider);
    return SecondaryPageShell(
      title: 'Loans',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Loan'),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GlassCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Outstanding',
                            style: AppTypography.bodyMd(context)),
                        const SizedBox(height: 4),
                        Text(
                          outstandingAsync.when(
                            data: (v) => 'KES ${v.toStringAsFixed(0)}',
                            loading: () => '...',
                            error: (_, __) => '—',
                          ),
                          style: AppTypography.headlineMd(context).copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.trending_down_rounded,
                      color: AppColors.warning, size: 32),
                ],
              ),
            ),
          ),
          Expanded(
            child: loansAsync.when(
              data: (loans) {
                if (loans.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: AppEmptyState(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'No loans yet',
                        subtitle: 'Tap + to add your first loan',
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: loans.length,
                  itemBuilder: (context, i) => LoanItemCard(
                    loan: loans[i],
                    onTap: () => _showForm(context, ref, loans[i]),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
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
