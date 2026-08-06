import 'package:beltech/core/utils/category_visual.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_form_sheet.dart';
import 'package:beltech/features/expenses/presentation/providers/expense_categories_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BudgetInput {
  const BudgetInput({required this.category, required this.monthlyLimitKes});

  final String category;
  final double monthlyLimitKes;
}

Future<BudgetInput?> showBudgetTargetDialog(
  BuildContext context, {
  String? initialCategory,
  double? initialLimit,
}) async {
  return showModalBottomSheet<BudgetInput>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _BudgetDialogSheet(
      initialCategory: initialCategory,
      initialLimit: initialLimit,
    ),
  );
}

class _BudgetDialogSheet extends ConsumerStatefulWidget {
  const _BudgetDialogSheet({this.initialCategory, this.initialLimit});

  final String? initialCategory;
  final double? initialLimit;

  @override
  ConsumerState<_BudgetDialogSheet> createState() => _BudgetDialogSheetState();
}

class _BudgetDialogSheetState extends ConsumerState<_BudgetDialogSheet> {
  String? _selectedCategory;
  final _limitController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _limitController.text = widget.initialLimit == null
        ? ''
        : widget.initialLimit!.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(expenseCategoriesProvider);
    final categories = categoriesAsync.value ?? expenseCategoryDefaults;

    return AppFormSheet(
      title: widget.initialCategory == null ? 'New Budget' : 'Edit Budget',
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
              label: 'Save',
              fullWidth: true,
              onPressed: () {
                if (_formKey.currentState?.validate() != true) return;
                Navigator.of(context).pop(
                  BudgetInput(
                    category: _selectedCategory!,
                    monthlyLimitKes:
                        double.parse(_limitController.text.trim()),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category picker — official app categories only
            FormField<String>(
              initialValue: _selectedCategory,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Select a category' : null,
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((name) {
                      final selected = _selectedCategory == name;
                      final visual = categoryVisual(name);
                      return ChoiceChip(
                        avatar: CircleAvatar(
                          backgroundColor: selected
                              ? visual.foreground.withOpacity(0.2)
                              : visual.background,
                          child: Icon(visual.icon,
                              color: visual.foreground, size: 13),
                        ),
                        label: Text(name),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => _selectedCategory = name);
                          field.didChange(name);
                        },
                      );
                    }).toList(),
                  ),
                  if (field.hasError) ...[
                    const SizedBox(height: 6),
                    Text(
                      field.errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _limitController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(hintText: 'Monthly Limit (KES)'),
              validator: (value) {
                final parsed = double.tryParse(value ?? '');
                if (parsed == null || parsed <= 0) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
