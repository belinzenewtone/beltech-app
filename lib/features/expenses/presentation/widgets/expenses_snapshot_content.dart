import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_capsule.dart';
import 'package:beltech/core/widgets/app_empty_state.dart';
import 'package:beltech/core/widgets/app_form_sheet.dart';
import 'package:beltech/core/utils/category_visual.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/category_chip.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_intelligence.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_review.dart';
import 'package:beltech/features/expenses/domain/entities/expense_item.dart';
import 'package:beltech/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:beltech/features/expenses/presentation/widgets/transaction_row.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

part 'expenses_snapshot_content_cards.dart';
part 'expenses_snapshot_content_imports.dart';

final _expenseDayHeaderFormat = DateFormat('EEE, MMM d');
final _txDateFormat = DateFormat('MMM d, HH:mm');

class ExpensesSnapshotContent extends StatefulWidget {
  const ExpensesSnapshotContent({
    super.key,
    required this.snapshot,
    required this.selectedFilter,
    required this.busy,
    required this.onFilterChanged,
    required this.onEditExpense,
    required this.onDeleteExpense,
    required this.onMerchantTap,
    required this.importMetrics,
    required this.reviewItems,
    required this.quarantineItems,
    required this.paybillProfiles,
    required this.fulizaEvents,
    required this.onApproveReview,
    required this.onRejectReview,
    required this.onDismissQuarantine,
    required this.onReplayImportQueue,
  });

  final ExpensesSnapshot snapshot;
  final ExpenseFilter selectedFilter;
  final bool busy;
  final ValueChanged<ExpenseFilter> onFilterChanged;
  final ValueChanged<ExpenseItem> onEditExpense;
  final ValueChanged<ExpenseItem> onDeleteExpense;
  final ValueChanged<ExpenseItem> onMerchantTap;
  final ExpenseImportMetrics importMetrics;
  final List<ExpenseReviewItem> reviewItems;
  final List<ExpenseQuarantineItem> quarantineItems;
  final List<PaybillProfile> paybillProfiles;
  final List<FulizaLifecycleEvent> fulizaEvents;
  final ValueChanged<ExpenseReviewItem> onApproveReview;
  final ValueChanged<ExpenseReviewItem> onRejectReview;
  final ValueChanged<ExpenseQuarantineItem> onDismissQuarantine;
  final Future<void> Function() onReplayImportQueue;

  @override
  State<ExpensesSnapshotContent> createState() =>
      _ExpensesSnapshotContentState();
}

class _ExpensesSnapshotContentState extends State<ExpensesSnapshotContent> {
  bool _showAllTransactions = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final transactions = _transactionsForFilter(
      widget.snapshot.transactions,
      widget.selectedFilter,
    );
    final visibleTransactions = _showAllTransactions
        ? transactions
        : transactions.take(20).toList();
    final groupedTransactions = _groupTransactionsByDay(visibleTransactions);
    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Today',
                amount: CurrencyFormatter.money(widget.snapshot.todayKes),
                tone: GlassCardTone.accent,
                accentColor: AppColors.accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                title: 'Week',
                amount: CurrencyFormatter.money(widget.snapshot.weekKes),
                tone: GlassCardTone.accent,
                accentColor: AppColors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ExpenseFilter.values.map((filter) {
            return CategoryChip(
              label: switch (filter) {
                ExpenseFilter.all => 'All',
                ExpenseFilter.today => 'Today',
                ExpenseFilter.week => 'This Week',
                ExpenseFilter.month => 'This Month',
              },
              selected: widget.selectedFilter == filter,
              onTap: () => widget.onFilterChanged(filter),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _CategoryCard(categories: widget.snapshot.categories),
        if (widget.fulizaEvents.isNotEmpty) ...[
          const SizedBox(height: 14),
          _FulizaSummaryCard(events: widget.fulizaEvents),
        ],
        const SizedBox(height: 14),
        _ImportPipelineCard(
          metrics: widget.importMetrics,
          reviewItems: widget.reviewItems,
          quarantineItems: widget.quarantineItems,
          paybillProfiles: widget.paybillProfiles,
          fulizaEvents: widget.fulizaEvents,
          busy: widget.busy,
          onApproveReview: widget.onApproveReview,
          onRejectReview: widget.onRejectReview,
          onDismissQuarantine: widget.onDismissQuarantine,
          onReplayImportQueue: widget.onReplayImportQueue,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Text('Transactions', style: textTheme.titleMedium)),
            if (transactions.isNotEmpty)
              Text(
                '${transactions.length} total',
                style: textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          const AppEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No transactions yet',
            subtitle: 'Import from M-Pesa SMS or add one manually.',
          ),
        for (final group in groupedTransactions) ...[
          _TransactionDayHeader(group: group),
          const SizedBox(height: 8),
          for (final tx in group.items) ...[
            ExpenseTransactionRow(
              dismissKey: 'expense-${tx.id}',
              title: tx.title,
              amount: CurrencyFormatter.money(tx.amountKes),
              category: tx.category,
              occurredAt: tx.occurredAt,
              balanceAfterKes: tx.balanceAfterKes,
              onEdit: () => widget.onEditExpense(tx),
              onDelete: () => widget.onDeleteExpense(tx),
              onTap: () => widget.onMerchantTap(tx),
              busy: widget.busy,
            ),
            const SizedBox(height: 10),
          ],
        ],
        if (transactions.length > 20)
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
                    ? 'Show fewer transactions'
                    : 'Show all transactions (${transactions.length})',
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
            style: Theme.of(context).textTheme.bodyLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          CurrencyFormatter.money(total),
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
