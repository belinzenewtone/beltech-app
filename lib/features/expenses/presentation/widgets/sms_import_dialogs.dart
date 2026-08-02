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
  const selectedWindow = ExpenseImportWindow.lastMonth;

  return showModalBottomSheet<SmsImportInput>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AppFormSheet(
      title: 'Paste SMS',
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
          TextField(
            controller: controller,
            minLines: 6,
            maxLines: 12,
            decoration: const InputDecoration(
              hintText: 'Paste M-Pesa or bank messages here',
            ),
          ),
        ],
      ),
    ),
  );
}

Future<ExpenseImportWindow?> showSmsWindowDialog(BuildContext context) async {
  const windows = [
    ExpenseImportWindow.last24Hours,
    ExpenseImportWindow.lastMonth,
    ExpenseImportWindow.last3Months,
    ExpenseImportWindow.last6Months,
  ];

  return showAppDialog<ExpenseImportWindow>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Import period', style: AppTypography.sectionTitle(context)),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: windows
            .map(
              (window) => SizedBox(
                width: (MediaQuery.of(context).size.width - 96) / 2,
                child: AppButton(
                  label: importWindowLabel(window),
                  size: AppButtonSize.sm,
                  variant: AppButtonVariant.secondary,
                  fullWidth: true,
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
    ExpenseImportWindow.lastMonth => 'Last month',
    ExpenseImportWindow.last3Months => 'Last 3 months',
    ExpenseImportWindow.last6Months => 'Last 6 months',
  };
}

String importFilterLabel(ImportSourceFilter filter) {
  return switch (filter) {
    ImportSourceFilter.mpesa => 'M-Pesa only',
    ImportSourceFilter.banks => 'Banks only',
    ImportSourceFilter.both => 'M-Pesa + Banks',
  };
}

/// Lets the user choose which providers to scan for — mirrors the Kotlin
/// reference (M-Pesa only / Banks only / both).
Future<ImportSourceFilter?> showSmsFilterDialog(BuildContext context) {
  return showModalBottomSheet<ImportSourceFilter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AppFormSheet(
      title: 'What to import',
      onClose: () => Navigator.of(context).pop(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in const [
            (ImportSourceFilter.both, Icons.all_inbox_rounded),
            (ImportSourceFilter.mpesa, Icons.smartphone_rounded),
            (ImportSourceFilter.banks, Icons.account_balance_rounded),
          ]) ...[
            AppCard(
              tone: AppCardTone.muted,
              onTap: () => Navigator.of(context).pop(option.$1),
              child: Row(
                children: [
                  Icon(option.$2, color: AppColors.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      importFilterLabel(option.$1),
                      style: AppTypography.bodyMd(context),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    ),
  );
}
