import 'package:beltech/core/forms/form_schemas.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/widgets/app_toast.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/category_visual.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_form_sheet.dart';
import 'package:beltech/features/expenses/domain/entities/expense_item.dart';
import 'package:beltech/features/expenses/presentation/providers/expense_categories_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ManualExpenseInput {
  const ManualExpenseInput({
    required this.title,
    required this.category,
    required this.amountKes,
    required this.occurredAt,
  });

  final String title;
  final String category;
  final double amountKes;
  final DateTime occurredAt;
}

Future<ManualExpenseInput?> showAddExpenseDialog(BuildContext context) {
  return _showExpenseDialog(context);
}

Future<ManualExpenseInput?> showEditExpenseDialog(
  BuildContext context, {
  required ExpenseItem expense,
}) {
  return _showExpenseDialog(context, initialExpense: expense);
}

Future<ManualExpenseInput?> _showExpenseDialog(
  BuildContext context, {
  ExpenseItem? initialExpense,
}) {
  return showModalBottomSheet<ManualExpenseInput>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) =>
        _ExpenseFormSheet(initialExpense: initialExpense),
  );
}

class _ExpenseFormSheet extends ConsumerStatefulWidget {
  const _ExpenseFormSheet({this.initialExpense});

  final ExpenseItem? initialExpense;

  @override
  ConsumerState<_ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends ConsumerState<_ExpenseFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late DateTime _occurredAt;
  late String _selectedCategory;

  bool get _isEdit => widget.initialExpense != null;
  bool get _isImported => widget.initialExpense?.isImported ?? false;

  @override
  void initState() {
    super.initState();
    final initialExpense = widget.initialExpense;
    _titleController = TextEditingController(text: initialExpense?.title ?? '');
    _amountController = TextEditingController(
      text: initialExpense == null
          ? ''
          : initialExpense.amountKes.toStringAsFixed(2),
    );
    _occurredAt = initialExpense?.occurredAt ?? DateTime.now();
    _selectedCategory = initialExpense?.category ?? expenseCategoryDefaults.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(expenseCategoriesProvider);
    final categories = categoriesAsync.value ?? expenseCategoryDefaults;
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = categories.first;
    }

    return AppFormSheet(
      title: _isEdit ? 'Edit Transaction' : 'Add Transaction',
      onClose: () => Navigator.of(context).pop(),
      footer: Row(
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              label: _isEdit ? 'Save' : 'Add',
              fullWidth: true,
              onPressed: categoriesAsync.isLoading ? null : _submit,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imported transactions: show locked fields as read-only info,
          // then only expose the category picker.
          if (_isImported) ...[
            AppCard(
              tone: AppCardTone.muted,
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Detected transaction — only category can be changed.',
                      style: AppTypography.bodySm(context).copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (!_isImported) ...[
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Title'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: 'Amount (KES)'),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: const InputDecoration(labelText: 'Category'),
            items: categories.map((c) {
              final visual = categoryVisual(c);
              return DropdownMenuItem<String>(
                value: c,
                child: Row(
                  children: [
                    Icon(visual.icon, size: 16, color: visual.foreground),
                    const SizedBox(width: 10),
                    Text(c),
                  ],
                ),
              );
            }).toList(),
            onChanged: categoriesAsync.isLoading
                ? null
                : (v) {
                    if (v != null) setState(() => _selectedCategory = v);
                  },
          ),
          if (!_isImported) ...[
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              tone: AppCardTone.muted,
              onTap: _pickOccurredAt,
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Occurred At',
                            style: AppTypography.bodySm(context)),
                        const SizedBox(height: 2),
                        Text(
                          _formatOccurredAt(_occurredAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMd(context),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickOccurredAt() async {
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _occurredAt,
    );
    if (pickedDate == null || !mounted) {
      return;
    }
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    if (pickedTime == null || !mounted) {
      return;
    }
    setState(() {
      _occurredAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _submit() {
    if (_isImported) {
      // Only category changes — pass through original values for the rest.
      final expense = widget.initialExpense!;
      Navigator.of(context).pop(
        ManualExpenseInput(
          title: expense.title,
          category: _selectedCategory,
          amountKes: expense.amountKes,
          occurredAt: expense.occurredAt,
        ),
      );
      return;
    }

    final result = FormSchemas.expenseSchema.validate({
      'title': _titleController.text,
      'amount': _amountController.text,
      'category': _selectedCategory,
    });
    if (!result.isValid) {
      final firstError = result.errors.values.first;
      ref.read(toastProvider.notifier).error(firstError);
      return;
    }
    final amount = double.tryParse(_amountController.text.trim())!;
    Navigator.of(context).pop(
      ManualExpenseInput(
        title: _titleController.text.trim(),
        category: _selectedCategory,
        amountKes: amount,
        occurredAt: _occurredAt,
      ),
    );
  }

  String _formatOccurredAt(DateTime value) {
    final date =
        '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year}';
    final time = TimeOfDay.fromDateTime(value).format(context);
    return '$date at $time';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transaction detail sheet — read-only view shown when a row is tapped.
// ─────────────────────────────────────────────────────────────────────────────

/// Opens a clean read-only bottom sheet for [expense].
/// [onDelete] is called if the user confirms deletion.
/// [onEdit] is called if the user wants to open the edit form.
Future<void> showExpenseDetailSheet(
  BuildContext context, {
  required ExpenseItem expense,
  required VoidCallback onDelete,
  required VoidCallback onEdit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ExpenseDetailSheet(
      expense: expense,
      onDelete: onDelete,
      onEdit: onEdit,
    ),
  );
}

/// Maps a raw category/type string (e.g. FULIZA_CHARGE) to a readable label.
String _cleanLabel(String raw) {
  if (raw.isEmpty) return raw;
  // SCREAMING_SNAKE_CASE → Title Case
  if (raw == raw.toUpperCase() && raw.contains('_')) {
    return raw
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0]}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
  return raw;
}

/// Maps the [source] field to a human-readable type label.
String _sourceLabel(String source) {
  return switch (source) {
    'mpesa_sms' => 'M-Pesa SMS',
    'airtel_sms' => 'Airtel Money SMS',
    'csv' => 'CSV import',
    'manual' => 'Manual entry',
    _ => source.replaceAll('_', ' '),
  };
}

class _ExpenseDetailSheet extends StatelessWidget {
  const _ExpenseDetailSheet({
    required this.expense,
    required this.onDelete,
    required this.onEdit,
  });

  final ExpenseItem expense;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final visual = categoryVisual(expense.category);
    final dateStr = DateFormat('EEE, d MMM yyyy · h:mm a').format(expense.occurredAt);
    final categoryDisplay = _cleanLabel(expense.category);
    final typeDisplay = _sourceLabel(expense.source);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Amount hero
            AppCard(
              tone: AppCardTone.accent,
              accentColor: visual.foreground,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: visual.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(visual.icon, color: visual.foreground, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.title,
                          style: AppTypography.bodyMd(context)
                              .copyWith(fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: AppTypography.bodySm(context).copyWith(
                            color: AppColors.textSecondaryFor(brightness),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    CurrencyFormatter.money(expense.amountKes),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Detail rows
            AppCard(
              tone: AppCardTone.muted,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.label_outline_rounded,
                    label: 'Category',
                    value: categoryDisplay,
                  ),
                  _DetailDivider(),
                  _DetailRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Source',
                    value: typeDisplay,
                  ),
                  if (expense.balanceAfterKes != null) ...[
                    _DetailDivider(),
                    _DetailRow(
                      icon: Icons.savings_outlined,
                      label: 'Balance after',
                      value: CurrencyFormatter.money(expense.balanceAfterKes!),
                    ),
                  ],
                  if (expense.feeKes != null && expense.feeKes! > 0) ...[
                    _DetailDivider(),
                    _DetailRow(
                      icon: Icons.receipt_outlined,
                      label: 'Transaction fee',
                      value: CurrencyFormatter.money(expense.feeKes!),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Action row
            Row(
              children: [
                // Delete
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: BorderSide(
                        color: AppColors.danger.withValues(alpha: 0.4),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDelete();
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Edit
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(expense.isImported ? 'Edit category' : 'Edit'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onEdit();
                    },
                  ),
                ),
              ],
            ),
            // Close
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 16, color: scheme.onSurface.withValues(alpha: 0.45)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySm(context).copyWith(
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: AppTypography.bodyMd(context)
                  .copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
    );
  }
}

