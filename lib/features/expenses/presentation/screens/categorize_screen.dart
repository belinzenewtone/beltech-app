import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/utils/category_visual.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/expenses/domain/entities/expense_item.dart';
import 'package:beltech/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CategorizeScreen extends ConsumerStatefulWidget {
  const CategorizeScreen({super.key});

  @override
  ConsumerState<CategorizeScreen> createState() => _CategorizeScreenState();
}

class _CategorizeScreenState extends ConsumerState<CategorizeScreen> {
  bool _showOnlyUncategorized = true;
  final Set<int> _saving = {};

  static const _allCategories = [
    'Food & Dining', 'Airtime', 'Transport', 'Utilities', 'Rent',
    'Shopping', 'Healthcare', 'Entertainment', 'Education',
    'Savings', 'Loans', 'Family', 'Other',
  ];

  static const _quickPickCategories = [
    'Food & Dining', 'Transport', 'Utilities', 'Shopping', 'Airtime',
  ];

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(expensesSnapshotProvider).valueOrNull;
    final transactions = snapshot?.transactions ?? const [];
    final uncategorized =
        transactions.where((t) => t.category == 'Other').toList();
    final visible =
        _showOnlyUncategorized ? uncategorized : transactions;

    return SecondaryPageShell(
      title: 'Categorize',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(child: _buildCountBadge(uncategorized.length)),
                const SizedBox(width: 8),
                _ToggleChip(
                  label: _showOnlyUncategorized ? 'Uncategorized' : 'All',
                  active: _showOnlyUncategorized,
                  onTap: () => setState(
                    () => _showOnlyUncategorized = !_showOnlyUncategorized,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            Expanded(
              child: _EmptyState(showAll: !_showOnlyUncategorized),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: visible.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _CategorizeRow(
                  transaction: visible[i],
                  isSaving: _saving.contains(visible[i].id),
                  quickPick: _quickPickCategories,
                  allCategories: _allCategories,
                  onCategorySelected: (cat) =>
                      _applyCategory(visible[i], cat),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCountBadge(int count) {
    if (count == 0) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'All transactions categorized',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.success,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count transaction${count == 1 ? '' : 's'} need review',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.warning,
        ),
      ),
    );
  }

  Future<void> _applyCategory(ExpenseItem tx, String category) async {
    if (_saving.contains(tx.id)) return;
    setState(() => _saving.add(tx.id));
    try {
      await ref
          .read(expenseWriteControllerProvider.notifier)
          .updateExpense(
            transactionId: tx.id,
            title: tx.title,
            category: category,
            amountKes: tx.amountKes,
            occurredAt: tx.occurredAt,
          );
      if (mounted &&
          !ref.read(expenseWriteControllerProvider).hasError) {
        AppFeedback.success(
          context,
          '${tx.title} → $category',
          ref: ref,
        );
      }
    } finally {
      if (mounted) setState(() => _saving.remove(tx.id));
    }
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppColors.accent.withValues(alpha: 0.16)
              : AppColors.textMuted.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppColors.accent.withValues(alpha: 0.5)
                : AppColors.textMuted.withValues(alpha: 0.20),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.accent : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.showAll});

  final bool showAll;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 48,
            color: AppColors.success.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 12),
          Text(
            showAll ? 'No transactions found' : 'Nothing to categorize',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            showAll
                ? 'Import some M-Pesa SMS to get started.'
                : 'All transactions have been reviewed.',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorizeRow extends StatelessWidget {
  const _CategorizeRow({
    required this.transaction,
    required this.isSaving,
    required this.quickPick,
    required this.allCategories,
    required this.onCategorySelected,
  });

  final ExpenseItem transaction;
  final bool isSaving;
  final List<String> quickPick;
  final List<String> allCategories;
  final ValueChanged<String> onCategorySelected;

  static final _dateFmt = DateFormat('MMM d, HH:mm');

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final visual = categoryVisual(tx.category);
    final brightness = Theme.of(context).brightness;
    final cardBg = AppColors.surfaceMutedFor(brightness);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderFor(brightness).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: visual.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(visual.icon, color: visual.foreground, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _dateFmt.format(tx.occurredAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.money(tx.amountKes),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: visual.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tx.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: visual.foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isSaving)
            const SizedBox(
              height: 28,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final cat in quickPick) ...[
                    _QuickPickChip(
                      category: cat,
                      isActive: tx.category == cat,
                      onTap: () => onCategorySelected(cat),
                    ),
                    const SizedBox(width: 6),
                  ],
                  _MoreChip(
                    transaction: tx,
                    allCategories: allCategories,
                    onCategorySelected: onCategorySelected,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickPickChip extends StatelessWidget {
  const _QuickPickChip({
    required this.category,
    required this.isActive,
    required this.onTap,
  });

  final String category;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = categoryVisual(category);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? visual.foreground.withValues(alpha: 0.18)
              : visual.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? visual.foreground.withValues(alpha: 0.6)
                : visual.foreground.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(visual.icon, size: 12, color: visual.foreground),
            const SizedBox(width: 4),
            Text(
              category,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: visual.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreChip extends StatelessWidget {
  const _MoreChip({
    required this.transaction,
    required this.allCategories,
    required this.onCategorySelected,
  });

  final ExpenseItem transaction;
  final List<String> allCategories;
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.textMuted.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.textMuted.withValues(alpha: 0.20),
          ),
        ),
        child: const Text(
          '⋯⋯⋯',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16 + MediaQuery.of(ctx).viewPadding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Choose category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allCategories.map((cat) {
                final visual = categoryVisual(cat);
                final isActive = transaction.category == cat;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    onCategorySelected(cat);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? visual.foreground.withValues(alpha: 0.18)
                          : visual.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? visual.foreground.withValues(alpha: 0.6)
                            : visual.foreground.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          visual.icon,
                          size: 14,
                          color: visual.foreground,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: visual.foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
