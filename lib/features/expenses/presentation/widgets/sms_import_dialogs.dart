import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_dialog.dart';
import 'package:beltech/core/widgets/app_dropdown_field.dart';
import 'package:beltech/core/widgets/app_form_sheet.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_window.dart';
import 'package:flutter/material.dart';

class SmsImportInput {
  const SmsImportInput({
    required this.payload,
    required this.window,
  });

  final String payload;
  final ExpenseImportWindow window;
}

enum SmsImportMethod { deviceInbox, pasteMessages }

Future<SmsImportInput?> showSmsImportDialog(BuildContext context) async {
  final controller = TextEditingController();
  var selectedWindow = ExpenseImportWindow.last30Days;

  return showModalBottomSheet<SmsImportInput>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AppFormSheet(
          title: 'Import MPESA SMS',
          subtitle:
              'Use the same cleaner import controls as the rest of the app.',
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
                  label: 'Import',
                  onPressed: () => Navigator.of(context).pop(
                    SmsImportInput(
                      payload: controller.text.trim(),
                      window: selectedWindow,
                    ),
                  ),
                ),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppDropdownField<ExpenseImportWindow>(
                label: 'Import period',
                value: selectedWindow,
                items: const [
                  DropdownMenuItem(
                    value: ExpenseImportWindow.last24Hours,
                    child: Text('Last 24 hours'),
                  ),
                  DropdownMenuItem(
                    value: ExpenseImportWindow.last7Days,
                    child: Text('Last 7 days'),
                  ),
                  DropdownMenuItem(
                    value: ExpenseImportWindow.last30Days,
                    child: Text('Last 30 days'),
                  ),
                  DropdownMenuItem(
                    value: ExpenseImportWindow.last90Days,
                    child: Text('Last 90 days'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedWindow = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                minLines: 6,
                maxLines: 12,
                decoration: const InputDecoration(
                  labelText: 'SMS text',
                  hintText:
                      'Paste MPESA SMS lines only.\nExample:\nQW12AB34CD Confirmed. Ksh1,250.00 sent to DELITOS HOTEL on 7/3/26 at 6:24 PM.',
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

Future<ExpenseImportWindow?> showSmsWindowDialog(BuildContext context) async {
  return showAppDialog<ExpenseImportWindow>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(Theme.of(context).brightness)
              .withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: AppColors.borderFor(Theme.of(context).brightness)
                .withValues(alpha: 0.75),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Import MPESA SMS',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Select time period to scan:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ...const [
              ExpenseImportWindow.last24Hours,
              ExpenseImportWindow.last7Days,
              ExpenseImportWindow.last30Days,
              ExpenseImportWindow.last90Days,
            ].map(
              (window) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ImportWindowOption(window: window),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<SmsImportMethod?> showSmsImportMethodDialog(BuildContext context) {
  return showModalBottomSheet<SmsImportMethod>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: GlassCard(
          borderRadius: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.sms, color: AppColors.accent),
                title: const Text('Import From Device Inbox'),
                subtitle: const Text('Reads MPESA SMS in last 24h/7d/30d/90d'),
                onTap: () =>
                    Navigator.of(context).pop(SmsImportMethod.deviceInbox),
              ),
              const Divider(height: 1, color: AppColors.border),
              ListTile(
                leading: const Icon(Icons.paste, color: AppColors.accent),
                title: const Text('Paste SMS Messages'),
                subtitle: const Text('Paste MPESA SMS text manually'),
                onTap: () =>
                    Navigator.of(context).pop(SmsImportMethod.pasteMessages),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String importWindowLabel(ExpenseImportWindow window) {
  return switch (window) {
    ExpenseImportWindow.last24Hours => 'Last 24 hours',
    ExpenseImportWindow.last7Days => 'Last 7 days',
    ExpenseImportWindow.last30Days => 'Last 30 days',
    ExpenseImportWindow.last90Days => 'Last 90 days',
  };
}

class _ImportWindowOption extends StatelessWidget {
  const _ImportWindowOption({required this.window});

  final ExpenseImportWindow window;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.of(context).pop(window),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceMutedFor(Theme.of(context).brightness)
              .withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.borderFor(Theme.of(context).brightness)
                .withValues(alpha: 0.65),
          ),
        ),
        child: Text(
          importWindowLabel(window),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
