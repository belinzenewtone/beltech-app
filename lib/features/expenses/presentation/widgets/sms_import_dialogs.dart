import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_dialog.dart';
import 'package:beltech/core/widgets/app_form_sheet.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_window.dart';
import 'package:flutter/material.dart';

class SmsImportInput {
  const SmsImportInput({required this.payload, required this.window});

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
                  label: 'Import',
                  fullWidth: true,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Import period', style: AppTypography.sectionTitle(context)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    const [
                      ExpenseImportWindow.last24Hours,
                      ExpenseImportWindow.last7Days,
                      ExpenseImportWindow.last30Days,
                      ExpenseImportWindow.last90Days,
                    ].map((window) {
                      final selected = selectedWindow == window;
                      return AppButton(
                        label: importWindowLabel(window),
                        size: AppButtonSize.sm,
                        variant: selected
                            ? AppButtonVariant.primary
                            : AppButtonVariant.secondary,
                        onPressed: () =>
                            setState(() => selectedWindow = window),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                minLines: 6,
                maxLines: 12,
                decoration: const InputDecoration(
                  hintText: 'Paste MPESA messages here',
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
    builder: (context) => AlertDialog(
      title: Text('Import period', style: AppTypography.sectionTitle(context)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            const [
                  ExpenseImportWindow.last24Hours,
                  ExpenseImportWindow.last7Days,
                  ExpenseImportWindow.last30Days,
                  ExpenseImportWindow.last90Days,
                ]
                .map(
                  (window) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppButton(
                      label: importWindowLabel(window),
                      fullWidth: true,
                      variant: AppButtonVariant.secondary,
                      onPressed: () => Navigator.of(context).pop(window),
                    ),
                  ),
                )
                .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}

Future<SmsImportMethod?> showSmsImportMethodDialog(BuildContext context) {
  return showModalBottomSheet<SmsImportMethod>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AppFormSheet(
      title: 'Import messages',
      onClose: () => Navigator.of(context).pop(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppCard(
            tone: AppCardTone.muted,
            onTap: () => Navigator.of(context).pop(SmsImportMethod.deviceInbox),
            child: Row(
              children: [
                const Icon(Icons.sms, color: AppColors.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Import from device',
                    style: AppTypography.bodyMd(context),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            tone: AppCardTone.muted,
            onTap: () =>
                Navigator.of(context).pop(SmsImportMethod.pasteMessages),
            child: Row(
              children: [
                const Icon(Icons.paste, color: AppColors.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Paste messages',
                    style: AppTypography.bodyMd(context),
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
}

String importWindowLabel(ExpenseImportWindow window) {
  return switch (window) {
    ExpenseImportWindow.last24Hours => 'Last 24 hours',
    ExpenseImportWindow.last7Days => 'Last 7 days',
    ExpenseImportWindow.last30Days => 'Last 30 days',
    ExpenseImportWindow.last90Days => 'Last 90 days',
  };
}
