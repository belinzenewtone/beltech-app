import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_form_sheet.dart';
import 'package:beltech/features/recurring/domain/entities/recurring_template.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecurringTemplateInput {
  const RecurringTemplateInput({
    required this.kind,
    required this.title,
    this.description,
    this.category,
    this.amountKes,
    this.priority,
    required this.cadence,
    required this.nextRunAt,
  });

  final RecurringKind kind;
  final String title;
  final String? description;
  final String? category;
  final double? amountKes;
  final String? priority;
  final RecurringCadence cadence;
  final DateTime nextRunAt;
}

Future<RecurringTemplateInput?> showRecurringTemplateDialog(
  BuildContext context, {
  RecurringTemplate? initial,
}) {
  final isEdit = initial != null;
  final titleController = TextEditingController(text: initial?.title ?? '');
  final descriptionController = TextEditingController(
    text: initial?.description ?? '',
  );
  final categoryController = TextEditingController(
    text: initial?.category ?? '',
  );
  final amountController = TextEditingController(
    text: initial?.amountKes != null
        ? initial!.amountKes!.toStringAsFixed(2)
        : '',
  );
  final formKey = GlobalKey<FormState>();
  var kind = initial?.kind ?? RecurringKind.expense;
  var cadence = initial?.cadence ?? RecurringCadence.monthly;
  var priority = initial?.priority ?? 'medium';
  var nextRunAt =
      initial?.nextRunAt ?? DateTime.now().add(const Duration(hours: 1));

  return showModalBottomSheet<RecurringTemplateInput>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final needsAmount =
            kind == RecurringKind.expense || kind == RecurringKind.income;
        final needsCategory = kind == RecurringKind.expense;
        final needsPriority = kind == RecurringKind.task;

        return AppFormSheet(
          title: isEdit ? 'Edit Recurring Item' : 'New Recurring Item',
          onClose: () => Navigator.of(context).pop(),
          footer: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Cancel',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Save',
                  onPressed: () {
                    if (formKey.currentState?.validate() != true) {
                      return;
                    }
                    final parsedAmount = amountController.text.trim().isEmpty
                        ? null
                        : double.tryParse(amountController.text.trim());
                    Navigator.of(context).pop(
                      RecurringTemplateInput(
                        kind: kind,
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                        category: categoryController.text.trim().isEmpty
                            ? null
                            : categoryController.text.trim(),
                        amountKes: parsedAmount,
                        priority: needsPriority ? priority : null,
                        cadence: cadence,
                        nextRunAt: nextRunAt,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type', style: AppTypography.sectionTitle(context)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: RecurringKind.values.map((value) {
                    final selected = kind == value;
                    return AppButton(
                      label:
                          value.name[0].toUpperCase() + value.name.substring(1),
                      size: AppButtonSize.sm,
                      variant: selected
                          ? AppButtonVariant.primary
                          : AppButtonVariant.secondary,
                      onPressed: () => setState(() => kind = value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(hintText: 'Title'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'Description (optional)',
                  ),
                ),
                if (needsCategory) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: categoryController,
                    decoration: const InputDecoration(hintText: 'Category'),
                  ),
                ],
                if (needsAmount) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(hintText: 'Amount (KES)'),
                    validator: (value) {
                      final amount = double.tryParse(value ?? '');
                      if (amount == null || amount <= 0) {
                        return 'Enter valid amount';
                      }
                      return null;
                    },
                  ),
                ],
                if (needsPriority) ...[
                  const SizedBox(height: 14),
                  Text('Priority', style: AppTypography.sectionTitle(context)),
                  const SizedBox(height: 10),
                  Row(
                    children:
                        const [
                          ('low', 'Neutral'),
                          ('medium', 'Important'),
                          ('high', 'Urgent'),
                        ].map((option) {
                          final selected = priority == option.$1;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: option.$1 == 'high' ? 0 : 8,
                              ),
                              child: AppButton(
                                label: option.$2,
                                size: AppButtonSize.sm,
                                variant: selected
                                    ? AppButtonVariant.primary
                                    : AppButtonVariant.secondary,
                                fullWidth: true,
                                onPressed: () =>
                                    setState(() => priority = option.$1),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
                const SizedBox(height: 14),
                Text('Repeat', style: AppTypography.sectionTitle(context)),
                const SizedBox(height: 10),
                Row(
                  children: RecurringCadence.values.map((value) {
                    final selected = cadence == value;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: value == RecurringCadence.monthly ? 0 : 8,
                        ),
                        child: AppButton(
                          label:
                              value.name[0].toUpperCase() +
                              value.name.substring(1),
                          size: AppButtonSize.sm,
                          variant: selected
                              ? AppButtonVariant.primary
                              : AppButtonVariant.secondary,
                          fullWidth: true,
                          onPressed: () => setState(() => cadence = value),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                AppCard(
                  tone: AppCardTone.muted,
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                      initialDate: nextRunAt,
                    );
                    if (pickedDate == null || !context.mounted) {
                      return;
                    }
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(nextRunAt),
                    );
                    if (pickedTime == null) {
                      return;
                    }
                    setState(() {
                      nextRunAt = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                    });
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, color: AppColors.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'First run',
                              style: AppTypography.bodySm(context),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('MMM d, yyyy HH:mm').format(nextRunAt),
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
            ),
          ),
        );
      },
    ),
  );
}
