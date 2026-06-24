import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/features/expenses/domain/entities/fee_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _feeAnalyticsProvider = FutureProvider<FeeAnalytics>((ref) =>
    ref.watch(expensesRepositoryProvider).fetchFeeAnalytics());

class FeeAnalyticsScreen extends ConsumerWidget {
  const FeeAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feesAsync = ref.watch(_feeAnalyticsProvider);
    return SecondaryPageShell(
      title: 'Fee Analytics',
      child: feesAsync.when(
        data: (fees) {
          if (fees.feeCount == 0) {
            return const Center(child: Text('No fee transactions detected'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatBlock(
                          label: 'Total Fees',
                          value: CurrencyFormatter.money(fees.totalFees),
                          color: AppColors.warning,
                        ),
                      ),
                      Expanded(
                        child: _StatBlock(
                          label: 'Fee Count',
                          value: '${fees.feeCount}',
                          color: AppColors.accent,
                        ),
                      ),
                      Expanded(
                        child: _StatBlock(
                          label: 'Average',
                          value: CurrencyFormatter.money(fees.averageFee),
                          color: AppColors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('By Category', style: AppTypography.headlineSm(context)),
              const SizedBox(height: 8),
              for (final (category, amount) in fees.topFeeCategories) ...[
                GlassCard(
                  child: ListTile(
                    leading: const Icon(Icons.category_outlined),
                    title: Text(category, style: AppTypography.bodyMd(context).copyWith(fontWeight: FontWeight.w600)),
                    trailing: Text(CurrencyFormatter.money(amount), style: AppTypography.bodyMd(context).copyWith(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              Text('Monthly Trend', style: AppTypography.headlineSm(context)),
              const SizedBox(height: 8),
              for (final m in fees.monthlyFees) ...[
                GlassCard(
                  child: ListTile(
                    title: Text('${m.year}-${m.month.toString().padLeft(2, '0')}', style: AppTypography.bodyMd(context)),
                    subtitle: Text('${m.count} transaction(s)', style: AppTypography.bodySm(context)),
                    trailing: Text(CurrencyFormatter.money(m.total), style: AppTypography.bodyMd(context).copyWith(fontWeight: FontWeight.w700)),
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
