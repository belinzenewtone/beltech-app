import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/features/expenses/domain/entities/merchant_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _merchantDetailProvider = FutureProvider.family<MerchantDetail, String>((ref, title) =>
    ref.watch(expensesRepositoryProvider).fetchMerchantDetail(title));

class MerchantDetailScreen extends ConsumerWidget {
  const MerchantDetailScreen({required this.merchantTitle, super.key});
  final String merchantTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(_merchantDetailProvider(merchantTitle));
    return SecondaryPageShell(
      title: merchantTitle,
      child: detailAsync.when(
        data: (detail) {
          if (detail.transactions.isEmpty) {
            return const Center(child: Text('No transactions found'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatBlock(
                              label: 'Total Spent',
                              value: CurrencyFormatter.money(detail.totalSpent),
                              color: AppColors.warning,
                            ),
                          ),
                          Expanded(
                            child: _StatBlock(
                              label: 'Transactions',
                              value: '${detail.transactionCount}',
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatBlock(
                              label: 'Average',
                              value: CurrencyFormatter.money(detail.averageAmount),
                              color: AppColors.teal,
                            ),
                          ),
                          Expanded(
                            child: _StatBlock(
                              label: 'Monthly Avg',
                              value: CurrencyFormatter.money(detail.monthlyAverage),
                              color: AppColors.violet,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatBlock(
                              label: 'First',
                              value: '${detail.firstSeen.day}/${detail.firstSeen.month}/${detail.firstSeen.year}',
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Expanded(
                            child: _StatBlock(
                              label: 'Last',
                              value: '${detail.lastSeen.day}/${detail.lastSeen.month}/${detail.lastSeen.year}',
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Transactions', style: AppTypography.headlineSm(context)),
              const SizedBox(height: 8),
              for (final tx in detail.transactions) ...[
                GlassCard(
                  child: ListTile(
                    leading: const Icon(Icons.receipt_outlined),
                    title: Text(CurrencyFormatter.money(tx.amount), style: AppTypography.bodyMd(context).copyWith(fontWeight: FontWeight.w700)),
                    subtitle: Text('${tx.date.day}/${tx.date.month}/${tx.date.year} · ${tx.category}', style: AppTypography.bodySm(context)),
                    trailing: tx.balanceAfter != null
                        ? Text('Bal ${CurrencyFormatter.compact(tx.balanceAfter!)}', style: AppTypography.bodySm(context))
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodySm(context).copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.bodyMd(context).copyWith(fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
