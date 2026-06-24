import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_motion.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_form_sheet.dart';
import 'package:beltech/core/widgets/super_add_sheet_sections.dart';
import 'package:beltech/features/bills/domain/entities/bill_item.dart';
import 'package:flutter/material.dart';

Future<BillFormResult?> showBillFormSheet(
  BuildContext context, {
  BillItem? existing,
}) {
  final nameController = TextEditingController(text: existing?.name ?? '');
  final amountController =
      TextEditingController(text: existing != null ? '${existing.amount}' : '');
  DateTime? dueDate = existing?.dueDate;
  BillUrgency urgency = existing?.urgency ?? BillUrgency.medium;
  String? recurrence = existing?.recurrence;
  var paid = existing?.paid ?? false;
  var titleError = false;
  var amountError = false;

  return showModalBottomSheet<BillFormResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final brightness = Theme.of(context).brightness;
        final textPrimary = AppColors.textPrimaryFor(brightness);
        final choiceDuration = AppMotion.content(context);

        return AppFormSheet(
          title: existing == null ? 'New Bill' : 'Edit Bill',
          subtitle: 'Track a bill or subscription payment.',
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
                  label: existing == null ? 'Create' : 'Save',
                  onPressed: () {
                    final name = nameController.text.trim();
                    final amount = double.tryParse(amountController.text.trim());
                    if (name.isEmpty) {
                      setState(() => titleError = true);
                      return;
                    }
                    if (amount == null || amount <= 0) {
                      setState(() => amountError = true);
                      return;
                    }
                    if (dueDate == null) {
                      return;
                    }
                    Navigator.of(context).pop(BillFormResult(
                      name: name,
                      amount: amount,
                      dueDate: dueDate!,
                      urgency: urgency,
                      recurrence: recurrence,
                      paid: paid,
                    ));
                  },
                ),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                onChanged: (_) => setState(() => titleError = false),
                decoration: InputDecoration(
                  hintText: 'Bill name (e.g., Rent, Netflix)',
                  errorText: titleError ? 'Name is required' : null,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() => amountError = false),
                decoration: InputDecoration(
                  hintText: 'Amount (KES)',
                  prefixText: 'KES ',
                  errorText: amountError ? 'Enter a valid amount' : null,
                ),
              ),
              const SizedBox(height: 12),
              SuperAddDateOnlyPickerRow(
                label: 'Due date',
                value: dueDate,
                onPick: (picked) => setState(() => dueDate = picked),
                fallbackDate: DateTime.now(),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: recurrence,
                decoration: const InputDecoration(labelText: 'Recurrence'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('One-time')),
                  const DropdownMenuItem(
                      value: 'monthly', child: Text('Monthly')),
                  const DropdownMenuItem(
                      value: 'weekly', child: Text('Weekly')),
                  const DropdownMenuItem(
                      value: 'yearly', child: Text('Yearly')),
                ],
                onChanged: (value) => setState(() => recurrence = value),
              ),
              const SizedBox(height: 12),
              Text(
                'Urgency',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: BillUrgency.values.map((u) {
                  final selected = u == urgency;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: u == BillUrgency.high ? 0 : 6,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => urgency = u),
                        child: AnimatedContainer(
                          duration: choiceDuration,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? switch (u) {
                                    BillUrgency.low => AppColors.accent,
                                    BillUrgency.medium => AppColors.warning,
                                    BillUrgency.high => AppColors.danger,
                                  }
                                : AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? switch (u) {
                                      BillUrgency.low => AppColors.accent,
                                      BillUrgency.medium => AppColors.warning,
                                      BillUrgency.high => AppColors.danger,
                                    }
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            u.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected ? Colors.white : textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              if (existing != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Mark as paid',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    Switch.adaptive(
                      value: paid,
                      onChanged: (value) => setState(() => paid = value),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    ),
  );
}

class BillFormResult {
  const BillFormResult({
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.urgency,
    this.recurrence,
    required this.paid,
  });

  final String name;
  final double amount;
  final DateTime dueDate;
  final BillUrgency urgency;
  final String? recurrence;
  final bool paid;
}
