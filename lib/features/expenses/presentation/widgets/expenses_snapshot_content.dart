import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_capsule.dart';
import 'package:beltech/core/widgets/app_empty_state.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_search_bar.dart';
import 'package:beltech/features/budget/domain/entities/budget_snapshot.dart';
import 'package:beltech/features/expenses/domain/entities/expense_item.dart';
import 'package:beltech/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:beltech/features/expenses/presentation/widgets/transaction_row.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

part 'expenses_snapshot_content_cards.dart';

final _expenseDayHeaderFormat = DateFormat('EEE, MMM d');

class ExpensesSnapshotContent extends StatefulWidget {
  const ExpensesSnapshotContent({
    super.key,
    required this.snapshot,
    required this.selectedFilter,
    required this.busy,
    required this.searchQuery,
    this.budgetSnapshot,
    required this.onFilterChanged,
    required this.onEditExpense,
    required this.onDeleteExpense,
    required this.onMerchantTap,
    this.headerItems = const [],
    this.searchController,
  });

  final ExpensesSnapshot snapshot;
  final ExpenseFilter selectedFilter;
  final bool busy;
  final String searchQuery;
  final BudgetSnapshot? budgetSnapshot;
  final ValueChanged<ExpenseFilter> onFilterChanged;
  final ValueChanged<ExpenseItem> onEditExpense;
  final ValueChanged<ExpenseItem> onDeleteExpense;
  final ValueChanged<ExpenseItem> onMerchantTap;
  final List<Widget> headerItems;
  final TextEditingController? searchController;

  @override
  State<ExpensesSnapshotContent> createState() =>
      _ExpensesSnapshotContentState();
}

class _ExpensesSnapshotContentState extends State<ExpensesSnapshotContent> {
  bool _showAllTransactions = false;

  @override
  Widget build(BuildContext context) {
    final transactions = _transactionsForFilter(
      widget.snapshot.transactions,
      widget.selectedFilter,
    );
    final filteredTransactions = _filterBySearch(
      transactions,
      widget.searchQuery,
    );
    final visibleTransactions = _showAllTransactions
        ? filteredTransactions
        : filteredTransactions.take(20).toList();
    final groupedTransactions = _groupTransactionsByDay(visibleTransactions);

    // Month total — computed from all transactions (no domain change needed).
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthTotal = widget.snapshot.transactions
        .where((t) => !t.occurredAt.isBefore(monthStart))
        .fold(0.0, (s, t) => s + t.amountKes);

    // Week-over-week trend delta for the Week card.
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final prevWeekStart = weekStart.subtract(const Duration(days: 7));
    final prevWeekTotal = widget.snapshot.transactions
        .where(
          (t) =>
              !t.occurredAt.isBefore(prevWeekStart) &&
              t.occurredAt.isBefore(weekStart),
        )
        .fold(0.0, (s, t) => s + t.amountKes);

    String? weekDelta;
    bool? weekDeltaIsGood;
    if (prevWeekTotal > 0) {
      final pct =
          (widget.snapshot.weekKes - prevWeekTotal) / prevWeekTotal * 100;
      weekDelta = '${pct >= 0 ? '+' : ''}${pct.round()}%';
      weekDeltaIsGood = pct <= 0;
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.contentBottomSafe),
      children: [
        // ── Injected header (title, pills, etc.) ─────────────────────────────
        ...widget.headerItems,
        // ── Summary ───────────────────────────────────────────────────────────
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: 160,
                child: _SummaryCard(
                  title: 'Today',
                  amount: CurrencyFormatter.money(widget.snapshot.todayKes),
                  tone: AppCardTone.accent,
                  accentColor: AppColors.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 160,
                child: _SummaryCard(
                  title: 'Week',
                  amount: CurrencyFormatter.money(widget.snapshot.weekKes),
                  tone: AppCardTone.standard,
                  delta: weekDelta,
                  deltaIsGood: weekDeltaIsGood,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 160,
                child: _SummaryCard(
                  title: 'Month',
                  amount: CurrencyFormatter.money(widget.snapshot.monthKes),
                  tone: AppCardTone.standard,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // ── Budget + Forecast ─────────────────────────────────────────────────
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: 170,
                child: _BudgetMiniCard(
                  budgetSnapshot: widget.budgetSnapshot,
                  monthTotal: monthTotal,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 170,
                child: _ForecastMiniCard(monthTotal: monthTotal),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // ── Filter chips ──────────────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: ExpenseFilter.values.map((filter) {
              final selected = widget.selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: AppCapsule(
                  label: switch (filter) {
                    ExpenseFilter.all => 'All',
                    ExpenseFilter.today => 'Today',
                    ExpenseFilter.week => 'This Week',
                    ExpenseFilter.month => 'This Month',
                  },
                  color: AppColors.accent,
                  variant: selected
                      ? AppCapsuleVariant.solid
                      : AppCapsuleVariant.outline,
                  onTap: () => widget.onFilterChanged(filter),
                ),
              );
            }).toList(),
          ),
        ),
        if (widget.searchController != null) ...[
          AppSearchBar(
            controller: widget.searchController!,
            hint: 'Search transactions...',
          ),
          const SizedBox(height: AppSpacing.md),
        ] else
          const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Text(
                'Transactions',
                style: AppTypography.cardTitle(context),
              ),
            ),
            if (filteredTransactions.isNotEmpty)
              Text(
                '${filteredTransactions.length}',
                style: AppTypography.bodySm(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (filteredTransactions.isEmpty)
          const AppEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No transactions',
            subtitle: 'Try a different filter or search.',
          ),
        for (final group in groupedTransactions) ...[
          _TransactionDayHeader(group: group),
          const SizedBox(height: AppSpacing.sm),
          for (final tx in group.items) ...[
            ExpenseTransactionRow(
              dismissKey: 'expense-${tx.id}',
              title: tx.title,
              amount: CurrencyFormatter.money(tx.amountKes),
              category: tx.category,
              onEdit: () => widget.onEditExpense(tx),
              onDelete: () => widget.onDeleteExpense(tx),
              onTap: () => widget.onMerchantTap(tx),
              busy: widget.busy,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
        if (filteredTransactions.length > 20)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showAllTransactions = !_showAllTransactions;
                });
              },
              child: Text(
                _showAllTransactions
                    ? 'Show fewer'
                    : 'Show all (${filteredTransactions.length})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }

  List<ExpenseItem> _transactionsForFilter(
    List<ExpenseItem> source,
    ExpenseFilter filter,
  ) {
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final weekStart = dayStart.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    return source.where((item) {
      switch (filter) {
        case ExpenseFilter.today:
          return !item.occurredAt.isBefore(dayStart);
        case ExpenseFilter.week:
          return !item.occurredAt.isBefore(weekStart);
        case ExpenseFilter.month:
          return !item.occurredAt.isBefore(monthStart);
        case ExpenseFilter.all:
          return true;
      }
    }).toList();
  }

  List<ExpenseItem> _filterBySearch(List<ExpenseItem> source, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return source;
    return source.where((item) {
      return item.title.toLowerCase().contains(normalized) ||
          item.category.toLowerCase().contains(normalized);
    }).toList();
  }

  List<_ExpenseDayGroup> _groupTransactionsByDay(List<ExpenseItem> items) {
    final groups = <_ExpenseDayGroup>[];
    for (final item in items) {
      final day = DateTime(
        item.occurredAt.year,
        item.occurredAt.month,
        item.occurredAt.day,
      );
      if (groups.isEmpty || groups.last.day != day) {
        groups.add(_ExpenseDayGroup(day: day, items: [item]));
      } else {
        groups.last.items.add(item);
      }
    }
    return groups;
  }
}

class _ExpenseDayGroup {
  _ExpenseDayGroup({required this.day, required this.items});

  final DateTime day;
  final List<ExpenseItem> items;
}

class _TransactionDayHeader extends StatelessWidget {
  const _TransactionDayHeader({required this.group});

  final _ExpenseDayGroup group;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        now.year == group.day.year &&
        now.month == group.day.month &&
        now.day == group.day.day;
    final total = group.items.fold<double>(
      0,
      (sum, item) => sum + item.amountKes,
    );

    return Row(
      children: [
        Expanded(
          child: Text(
            isToday ? 'Today' : _expenseDayHeaderFormat.format(group.day),
            style: AppTypography.bodyMd(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          CurrencyFormatter.money(total),
          style: AppTypography.bodySm(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
