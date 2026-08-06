import 'package:beltech/core/forms/form_schemas.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/widgets/app_toast.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/category_visual.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_form_sheet.dart';
import 'package:beltech/features/expenses/domain/entities/expense_item.dart';
import 'package:beltech/features/expenses/presentation/providers/expense_categories_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

