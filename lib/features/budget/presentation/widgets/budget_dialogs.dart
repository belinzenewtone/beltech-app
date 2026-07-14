import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_form_sheet.dart';
import 'package:flutter/material.dart';

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
  final categoryController = TextEditingController(text: initialCategory ?? '');
  final limitController = TextEditingController(
    text: initialLimit == null ? '' : initialLimit.toStringAsFixed(2),
  );
  final formKey = GlobalKey<FormState>();

  try {
    return await showModalBottomSheet<BudgetInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AppFormSheet(
          title: initialCategory == null ? 'New Budget' : 'Edit Budget',
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
                    if (formKey.currentState?.validate() != true) {
                      return;
                    }
                    Navigator.of(context).pop(
                      BudgetInput(
                        category: categoryController.text.trim(),
                        monthlyLimitKes: double.parse(
                          limitController.text.trim(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: categoryController,
                  decoration: const InputDecoration(hintText: 'Category'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Category is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: limitController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Monthly Limit (KES)',
                  ),
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
      },
    );
  } finally {
    categoryController.dispose();
    limitController.dispose();
  }
}
