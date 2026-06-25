import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_form_sheet.dart';
import 'package:beltech/core/widgets/super_add_sheet_sections.dart';
import 'package:beltech/features/bills/domain/entities/bill_item.dart';
import 'package:flutter/material.dart';

Future<BillFormResult?> showBillFormSheet(
  BuildContext context, {
  BillItem? existing,
}) {
  final nameController = TextEditingController(text: existing?.name ?? '');
  final amountController = TextEditingController(
    text: existing != null ? '${existing.amount}' : '',
  );
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
        return AppFormSheet(
          title: existing == null ? 'New Bill' : 'Edit Bill',
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
                  label: existing == null ? 'Create' : 'Save',
                  fullWidth: true,
                  onPressed: () {
                    final name = nameController.text.trim();
                    final amount = double.tryParse(
                      amountController.text.trim(),
                    );
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
                    Navigator.of(context).pop(
                      BillFormResult(
                        name: name,
                        amount: amount,
                        dueDate: dueDate!,
                        urgency: urgency,
                        recurrence: recurrence,
                        paid: paid,
                      ),
                    );
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
                  hintText: 'Bill name',
                  errorText: titleError ? 'Name is required' : null,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() => amountError = false),
                decoration: InputDecoration(
                  hintText: 'Amount (KES)',
                  errorText: amountError ? 'Enter a valid amount' : null,
                ),
              ),
              const SizedBox(height: 14),
              SuperAddDateOnlyPickerRow(
                label: 'Due date',
                value: dueDate,
                onPick: (picked) => setState(() => dueDate = picked),
                fallbackDate: DateTime.now(),
              ),
              const SizedBox(height: 14),
              Text('Repeat', style: AppTypography.sectionTitle(context)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                      (null, 'One-time'),
                      ('monthly', 'Monthly'),
                      ('weekly', 'Weekly'),
                      ('yearly', 'Yearly'),
                    ].map((option) {
                      final selected = recurrence == option.$1;
                      return AppButton(
                        label: option.$2,
                        size: AppButtonSize.sm,
                        variant: selected
                            ? AppButtonVariant.primary
                            : AppButtonVariant.secondary,
                        onPressed: () => setState(() => recurrence = option.$1),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 14),
              Text('Urgency', style: AppTypography.sectionTitle(context)),
              const SizedBox(height: 10),
              Row(
                children: BillUrgency.values.map((u) {
                  final selected = u == urgency;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: u == BillUrgency.high ? 0 : 8,
                      ),
                      child: AppButton(
                        label: u.label,
                        size: AppButtonSize.sm,
                        variant: selected
                            ? AppButtonVariant.primary
                            : AppButtonVariant.secondary,
                        fullWidth: true,
                        onPressed: () => setState(() => urgency = u),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              if (existing != null)
                AppCard(
                  tone: AppCardTone.muted,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Mark as paid',
                          style: AppTypography.bodyMd(context),
                        ),
                      ),
                      Switch.adaptive(
                        value: paid,
                        onChanged: (value) => setState(() => paid = value),
                      ),
                    ],
                  ),
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
