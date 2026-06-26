import 'package:beltech/core/theme/app_motion.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/app_toast.dart';
import 'package:beltech/core/widgets/app_icon_pill_button.dart';
import 'package:beltech/core/widgets/app_skeleton.dart';
import 'package:beltech/core/widgets/error_message.dart';
import 'package:beltech/core/widgets/page_shell.dart';
import 'package:beltech/features/budget/presentation/providers/budget_providers.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_review.dart';
import 'package:beltech/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:beltech/features/expenses/presentation/expenses_screen_helpers.dart';
import 'package:beltech/features/expenses/presentation/widgets/expense_dialogs.dart';
import 'package:beltech/features/expenses/presentation/widgets/expenses_snapshot_content.dart';
import 'package:beltech/features/expenses/presentation/widgets/fuliza_banner.dart';
import 'package:beltech/features/expenses/presentation/widgets/import_health_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

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

    final contentSwitchDuration = AppMotion.duration(
      context,
      normalMs: 180,
      reducedMs: 0,
    );

    // Header items scroll with content inside ExpensesSnapshotContent's ListView.
    final headerItems = <Widget>[
      const SizedBox(height: AppSpacing.screenTop),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: [
            AppIconPillButton(
              icon: Icons.add_rounded,
              label: 'Add',
              tone: AppIconPillTone.accent,
              onPressed: writeBusy
                  ? null
                  : () async {
                      final input = await showAddExpenseDialog(context);
                      if (input == null) return;
                      await ref
                          .read(expenseWriteControllerProvider.notifier)
                          .addExpense(
                            title: input.title,
                            category: input.category,
                            amountKes: input.amountKes,
                            occurredAt: input.occurredAt,
                          );
                      if (context.mounted &&
                          !ref
                              .read(expenseWriteControllerProvider)
                              .hasError) {
                        AppFeedback.success(
                          context,
                          'Transaction added',
                          ref: ref,
                        );
                      }
                    },
            ),
            const SizedBox(width: 8),
            AppIconPillButton(
              icon: Icons.hub_outlined,
              label: 'Hub',
              tone: AppIconPillTone.subtle,
              onPressed: () => context.pushNamed('import-health'),
            ),
            const SizedBox(width: 8),
            AppIconPillButton(
              icon: Icons.sms_outlined,
              label: 'Import SMS',
              tone: AppIconPillTone.subtle,
              onPressed: writeBusy
                  ? null
                  : () => handleExpenseSmsImport(context, ref),
            ),
            const SizedBox(width: 8),
            AppIconPillButton(
              icon: Icons.upload_file_outlined,
              label: 'Import CSV',
              tone: AppIconPillTone.subtle,
              onPressed: writeBusy
                  ? null
                  : () => context.pushNamed('csv-import'),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Text('Finance', style: AppTypography.pageTitle(context)),
      const SizedBox(height: AppSpacing.md),
      const FulizaBanner(),
    ];

    final snapshotChild = snapshotState.when(
      data: (snapshot) {
        consumeExpenseSearchTarget(context, ref, snapshot);
        return KeyedSubtree(
          key: const ValueKey<String>('expenses-data'),
          child: ExpensesSnapshotContent(
            snapshot: snapshot,
            selectedFilter: selectedFilter,
            busy: writeBusy,
            searchQuery: _searchQuery,
            budgetSnapshot: budgetSnapshotState.valueOrNull,
            headerItems: headerItems,
            searchController: _searchController,
            onFilterChanged: (filter) {
              ref.read(expenseFilterProvider.notifier).state = filter;
            },
            onEditExpense: (expense) async {
              await editExpenseEntry(context, ref, expense);
            },
            onMerchantTap: (expense) async {
              await editExpenseEntry(context, ref, expense);
            },
            onDeleteExpense: (expense) async {
              await ref
                  .read(expenseWriteControllerProvider.notifier)
                  .deleteExpense(expense.id);
              if (!context.mounted) return;
              if (ref.read(expenseWriteControllerProvider).hasError) return;
              ref.read(toastProvider.notifier).showWithUndo(
                'Transaction deleted',
                onUndo: () async {
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
          ),
        );
      },
      loading: () => const KeyedSubtree(
        key: ValueKey<String>('expenses-loading'),
        child: FinanceSkeletonList(),
      ),
      error: (_, __) => KeyedSubtree(
        key: const ValueKey<String>('expenses-error'),
        child: ErrorMessage(
          label: 'Unable to load expenses',
          onRetry: () => ref.invalidate(expensesSnapshotProvider),
        ),
      ),
    );

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

    // Resolve import metrics for the health banner (safe fallback to zeros).
    final importMetrics =
        ref.watch(expenseImportMetricsProvider).valueOrNull ??
        const ExpenseImportMetrics(
          reviewQueueCount: 0,
          quarantineCount: 0,
          retryQueueCount: 0,
          failedQueueCount: 0,
        );

    return PageShell(
      scrollable: false,
      topPadding: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed import health banner above the scrollable content.
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: -AppSpacing.screenHorizontal,
            ),
            child: ImportHealthBanner(
              metrics: importMetrics,
              onTap: () => context.pushNamed('import-health'),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: contentSwitchDuration,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: snapshotChild,
            ),
          ),
        ],
      ),
    );
  }
}
