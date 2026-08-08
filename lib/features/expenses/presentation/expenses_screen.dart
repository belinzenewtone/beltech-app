import 'package:beltech/core/theme/app_motion.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/app_toast.dart';
import 'package:beltech/core/widgets/app_skeleton.dart';
import 'package:beltech/core/widgets/error_message.dart';
import 'package:beltech/core/widgets/page_header.dart';
import 'package:beltech/core/widgets/page_shell.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/budget/presentation/providers/budget_providers.dart';
import 'package:beltech/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:beltech/features/income/presentation/providers/income_providers.dart';
import 'package:beltech/features/expenses/presentation/expenses_screen_helpers.dart';
import 'package:beltech/features/expenses/presentation/widgets/expense_dialogs.dart';
import 'package:beltech/features/expenses/presentation/widgets/expenses_snapshot_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

// ─────────────────────────────────────────────────────────────────────────────
// Spending hero card — "Spent this month" headline with sub-metrics
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
    final bodySm = AppTypography.bodySm(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spent this month',
            style: bodySm.copyWith(color: scheme.onSurfaceVariant),
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
            fontWeight: FontWeight.w700,
            color: isPrimary ? AppColors.teal : scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshotState = ref.watch(expensesSnapshotProvider);
    final selectedFilter = ref.watch(expenseFilterProvider);
    // select() narrows rebuild scope: only rebuild this screen when isLoading
    // actually flips — not on every intermediate writeState emission.
    final writeBusy = ref.watch(
      expenseWriteControllerProvider.select((s) => s.isLoading),
    );
    final budgetSnapshotState = ref.watch(budgetSnapshotProvider);
    final incomeOverview = ref.watch(incomeOverviewProvider);

    // Spending hero metrics — snapshot may still be loading; fall back to 0.
    final monthKes = snapshotState.value?.monthKes ?? 0.0;
    final todayKes = snapshotState.value?.todayKes ?? 0.0;
    final weekKes = snapshotState.value?.weekKes ?? 0.0;
    final incomeKes = incomeOverview.asData?.value.currentMonthIncomeKes ?? 0.0;

    final contentSwitchDuration = AppMotion.duration(
      context,
      normalMs: 180,
      reducedMs: 0,
    );

    // Header items scroll with content inside ExpensesSnapshotContent's ListView.
    final headerItems = <Widget>[
      const SizedBox(height: AppSpacing.screenTop),
      const PageHeader(eyebrow: 'Your Money', title: 'Finance'),
      const SizedBox(height: AppSpacing.sm),
      _SpendingHeroCard(
        monthKes: monthKes,
        todayKes: todayKes,
        weekKes: weekKes,
        incomeKes: incomeKes,
      ),
    ];

    ref.listen<AsyncValue<void>>(expenseWriteControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError) {
        AppFeedback.error(
          context,
          'Unable to save transaction. Please try again.',
          ref: ref,
        );
      }
    });

    return PageShell(
      scrollable: false,
      topPadding: 0,
      horizontalPadding: 0,
      child: Stack(
        children: [
          // Full-size scrollable content — banner floats above, no layout shift.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _searchController,
              builder: (context, _) {
                final snapshotChild = snapshotState.when(
                  data: (snapshot) {
                    consumeExpenseSearchTarget(context, ref, snapshot);
                    return KeyedSubtree(
                      key: const ValueKey<String>('expenses-data'),
                      child: ExpensesSnapshotContent(
                        snapshot: snapshot,
                        selectedFilter: selectedFilter,
                        busy: writeBusy,
                        searchQuery: _searchController.text,
                        budgetSnapshot: budgetSnapshotState.value,
                        headerItems: headerItems,
                        searchController: _searchController,
                        onFilterChanged: (filter) {
                          ref.read(expenseFilterProvider.notifier).state =
                              filter;
                        },
                        onEditExpense: (expense) async {
                          await editExpenseEntry(context, ref, expense);
                        },
                        onMerchantTap: (expense) async {
                          await showExpenseDetailSheet(
                            context,
                            expense: expense,
                            onDelete: () async {
                              await ref
                                  .read(expenseWriteControllerProvider.notifier)
                                  .deleteExpense(expense.id);
                              if (!context.mounted) return;
                              if (ref
                                  .read(expenseWriteControllerProvider)
                                  .hasError) return;
                              ref
                                  .read(toastProvider.notifier)
                                  .showWithUndo(
                                    'Transaction deleted',
                                    onUndo: () async {
                                      // Re-add the original transaction
                                      await ref
                                          .read(expenseWriteControllerProvider.notifier)
                                          .addExpense(
                                            title: expense.title,
                                            category: expense.category,
                                            amountKes: expense.amountKes,
                                            occurredAt: expense.occurredAt,
                                          );
                                    },
                                  );
                            },
                            onEdit: () async {
                              await editExpenseEntry(context, ref, expense);
                            },
                          );
                        },
                        onDeleteExpense: (expense) async {
                          await ref
                              .read(expenseWriteControllerProvider.notifier)
                              .deleteExpense(expense.id);
                          if (!context.mounted) { return; }
                          if (ref
                              .read(expenseWriteControllerProvider)
                              .hasError) { return; }
                          ref
                              .read(toastProvider.notifier)
                              .showWithUndo(
                                'Transaction deleted',
                                onUndo: () async {
                                  await ref
                                      .read(
                                        expenseWriteControllerProvider.notifier,
                                      )
                                      .addExpense(
                                        title: expense.title,
                                        category: expense.category,
                                        amountKes: expense.amountKes,
                                        occurredAt: expense.occurredAt,
                                      );
                                },
                              );
                        },
                      ),
                    );
                  },
                  loading: () => const KeyedSubtree(
                    key: ValueKey<String>('expenses-loading'),
                    child: FinanceSkeletonList(),
                  ),
                  error: (_, _) => KeyedSubtree(
                    key: const ValueKey<String>('expenses-error'),
                    child: ErrorMessage(
                      label: 'Unable to load expenses',
                      onRetry: () => ref.invalidate(expensesSnapshotProvider),
                    ),
                  ),
                );
                return AnimatedSwitcher(
                  duration: contentSwitchDuration,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                    ),
                    child: snapshotChild,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
