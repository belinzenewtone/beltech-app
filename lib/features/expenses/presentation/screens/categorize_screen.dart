import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/category_visual.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/app_form_sheet.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/expenses/domain/entities/expense_item.dart';
import 'package:beltech/features/expenses/presentation/providers/expense_categories_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(expensesSnapshotProvider).valueOrNull;
    final transactions = snapshot?.transactions ?? const [];
    final categoriesAsync = ref.watch(expenseCategoriesProvider);
    final allCategories = categoriesAsync.valueOrNull ?? expenseCategoryDefaults;
    final quickPickCategories = allCategories.take(5).toList();
    final uncategorized = transactions
        .where((t) => !allCategories.contains(t.category))
        .toList();
    final visible = _showOnlyUncategorized ? uncategorized : transactions;

    return SecondaryPageShell(
      title: 'Categorize',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: Row(
              children: [
                Expanded(child: _buildCountBadge(uncategorized.length)),
                const SizedBox(width: AppSpacing.sm),
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
          const SizedBox(height: AppSpacing.md),
          if (visible.isEmpty)
            Expanded(child: _EmptyState(showAll: !_showOnlyUncategorized))
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                itemCount: visible.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) => _CategorizeRow(
                  transaction: visible[i],
                  isSaving: _saving.contains(visible[i].id),
                  quickPick: quickPickCategories,
                  allCategories: allCategories,
                  onCategorySelected: (cat) => _applyCategory(visible[i], cat),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCountBadge(int count) {
    return AppCard(
      tone: count == 0 ? AppCardTone.standard : AppCardTone.muted,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        count == 0 ? 'All categorized' : '$count to review',
        style: AppTypography.bodySm(context).copyWith(
          color: count == 0 ? AppColors.success : AppColors.warning,
          fontWeight: FontWeight.w600,
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
      if (mounted && !ref.read(expenseWriteControllerProvider).hasError) {
        AppFeedback.success(context, '${tx.title} → $category', ref: ref);
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 2,
        ),
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
          style: AppTypography.label(
            context,
          ).copyWith(color: active ? AppColors.accent : AppColors.textMuted),
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
      child: Text(
        showAll ? 'No transactions' : 'All categorized',
        style: AppTypography.bodyMd(
          context,
        ).copyWith(color: AppColors.textSecondary),
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

    return AppCard(
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
                child: Icon(visual.icon, color: visual.foreground, size: 17),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMd(
                        context,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _dateFmt.format(tx.occurredAt),
                      style: AppTypography.bodySm(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.money(tx.amountKes),
                    style: AppTypography.bodyMd(
                      context,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    tx.category,
                    style: AppTypography.bodySm(
                      context,
                    ).copyWith(color: visual.foreground),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (isSaving)
            const SizedBox(
              height: 28,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
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
                    const SizedBox(width: AppSpacing.xs),
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs + 1,
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
            Icon(visual.icon, size: 12, color: visual.foreground),
            const SizedBox(width: AppSpacing.xs),
            Text(
              category,
              style: AppTypography.label(
                context,
              ).copyWith(color: visual.foreground),
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs + 1,
        ),
        decoration: BoxDecoration(
          color: AppColors.textMuted.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.textMuted.withValues(alpha: 0.20),
          ),
        ),
        child: Text(
          'More',
          style: AppTypography.label(
            context,
          ).copyWith(color: AppColors.textMuted),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AppFormSheet(
        title: 'Choose category',
        onClose: () => Navigator.pop(ctx),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
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
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs + 3,
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
                    Icon(visual.icon, size: 14, color: visual.foreground),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      cat,
                      style: AppTypography.bodySm(context).copyWith(
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
      ),
    );
  }
}
