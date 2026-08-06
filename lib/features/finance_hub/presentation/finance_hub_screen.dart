import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/category_visual.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/budget/domain/entities/budget_target_progress.dart';
import 'package:beltech/features/budget/presentation/providers/budget_providers.dart';
import 'package:beltech/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:beltech/features/income/presentation/providers/income_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FinanceHubScreen extends ConsumerWidget {
  const FinanceHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(expensesSnapshotProvider);
    final incomeAsync = ref.watch(incomeOverviewProvider);
    final budgetAsync = ref.watch(budgetTargetProgressProvider);

    final todayKes = snapshotAsync.asData?.value.todayKes ?? 0;
    final weekKes = snapshotAsync.asData?.value.weekKes ?? 0;
    final monthKes = snapshotAsync.asData?.value.monthKes ?? 0;
    final incomeKes = incomeAsync.asData?.value.currentMonthIncomeKes ?? 0;

    return SecondaryPageShell(
      title: 'Finance Hub',
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Spending hero card ────────────────────────────────────────
          _SpendingHeroCard(
            monthKes: monthKes,
            todayKes: todayKes,
            weekKes: weekKes,
            incomeKes: incomeKes,
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Budget snapshot (only when user has set budgets) ──────────
          _BudgetSection(budgetAsync: budgetAsync),

          // ── Navigation cards ──────────────────────────────────────────
          _HubCard(
            icon: Icons.account_balance_outlined,
            title: 'Budgets',
            subtitle: 'Set spending limits by category and track progress',
            onTap: () { AppHaptics.lightImpact(); context.pushNamed('budget'); },
          ),
          const SizedBox(height: AppSpacing.md),
          _HubCard(
            icon: Icons.attach_money_rounded,
            title: 'Income',
            subtitle: 'Log and review income sources',
            onTap: () { AppHaptics.lightImpact(); context.pushNamed('income'); },
          ),
          const SizedBox(height: AppSpacing.md),
          _HubCard(
            icon: Icons.repeat_rounded,
            title: 'Recurring',
            subtitle: 'Subscriptions, salaries, and scheduled payments',
            onTap: () { AppHaptics.lightImpact(); context.pushNamed('recurring'); },
          ),
          const SizedBox(height: AppSpacing.md),
          _HubCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Loans & Fuliza',
            subtitle: 'Track outstanding Fuliza draws and repayment history',
            onTap: () { AppHaptics.lightImpact(); context.pushNamed('loans'); },
          ),
          const SizedBox(height: AppSpacing.md),
          _HubCard(
            icon: Icons.receipt_long_outlined,
            title: 'Bills',
            subtitle: 'Track recurring bills and subscriptions with due dates',
            onTap: () { AppHaptics.lightImpact(); context.pushNamed('bills'); },
          ),
          const SizedBox(height: AppSpacing.md),
          _HubCard(
            icon: Icons.search_rounded,
            title: 'Search Finance',
            subtitle: 'Search transactions, budgets, and recurring entries',
            onTap: () { AppHaptics.lightImpact(); context.pushNamed('search'); },
          ),
          const SizedBox(height: AppSpacing.md),
          _HubCard(
            icon: Icons.download_rounded,
            title: 'Export',
            subtitle: 'Export your data as CSV or share a report',
            onTap: () { AppHaptics.lightImpact(); context.pushNamed('export'); },
          ),
          const SizedBox(height: AppSpacing.sectionGap),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero spending card — mirrors Kotlin FinanceSpendingHeroCard
// ─────────────────────────────────────────────────────────────────────────────

class _SpendingHeroCard extends StatelessWidget {
  const _SpendingHeroCard({
    required this.monthKes,
    required this.todayKes,
    required this.weekKes,
    required this.incomeKes,
  });

  final double monthKes;
  final double todayKes;
  final double weekKes;
  final double incomeKes;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spent this month',
            style: AppTypography.bodySm(context)
                .copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.money(monthKes),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Metric(label: 'Today', value: todayKes),
              _Metric(label: 'This week', value: weekKes),
              _Metric(label: 'Income', value: incomeKes, isPrimary: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.isPrimary = false,
  });

  final String label;
  final double value;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySm(context).copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 11,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          CurrencyFormatter.money(value),
          style: AppTypography.bodyMd(context).copyWith(
                fontWeight: FontWeight.w600,
                color: isPrimary ? scheme.primary : scheme.onSurface,
              ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Budget snapshot — reads real budgetTargetProgressProvider data.
// Only shown when the user has set at least one budget target.
// ─────────────────────────────────────────────────────────────────────────────

class _BudgetSection extends StatelessWidget {
  const _BudgetSection({required this.budgetAsync});

  final AsyncValue<List<BudgetTargetProgress>> budgetAsync;

  @override
  Widget build(BuildContext context) {
    return budgetAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (targets) {
        if (targets.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Budgets', style: AppTypography.sectionTitle(context)),
                GestureDetector(
                  onTap: () => GoRouter.of(context).pushNamed('budget'),
                  child: Text(
                    'View all',
                    style: AppTypography.bodySm(context).copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                children: [
                  for (int i = 0; i < targets.length && i < 3; i++) ...[
                    if (i > 0) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Divider(
                        height: 1,
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    _BudgetRow(progress: targets[i]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.progress});

  final BudgetTargetProgress progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = progress.usageRatio.clamp(0.0, 1.0);
    final barColor =
        (progress.isOverLimit || progress.isNearLimit)
            ? AppColors.danger
            : scheme.primary;
    final visual = categoryVisual(progress.category);
    final pctDisplay = (progress.usageRatio * 100).round();

    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: visual.background,
              child:
                  Icon(visual.icon, color: visual.foreground, size: 12),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                progress.category,
                style: AppTypography.bodyMd(context)
                    .copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              '$pctDisplay%',
              style: AppTypography.bodySm(context).copyWith(
                    color: barColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7,
            backgroundColor: scheme.outlineVariant,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${CurrencyFormatter.money(progress.spentKes)} spent',
              style: AppTypography.bodySm(context).copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
            ),
            Text(
              CurrencyFormatter.money(progress.monthlyLimitKes),
              style: AppTypography.bodySm(context).copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Navigation hub card
// ─────────────────────────────────────────────────────────────────────────────

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 76),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMd(context)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySm(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
