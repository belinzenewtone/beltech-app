import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:flutter/material.dart';

/// CSV import preview and validation screen.
/// Shows preview of transactions to be imported with validation status.
class CsvImportPreviewScreen extends StatelessWidget {
  const CsvImportPreviewScreen({
    super.key,
    required this.fileName,
    required this.transactions,
    this.onImport,
  });

  final String fileName;
  final List<CsvTransactionPreview> transactions;
  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    final validCount = transactions.where((t) => t.isValid).length;
    final invalidCount = transactions.where((t) => !t.isValid).length;

    return SecondaryPageShell(
      title: 'Import Preview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.description_outlined, color: AppColors.accent),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    fileName,
                    style: AppTypography.bodyMd(
                      context,
                    ).copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _SummaryBadge(
                  label: 'Valid',
                  value: '$validCount',
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.sm),
                _SummaryBadge(
                  label: 'Issues',
                  value: '$invalidCount',
                  color: AppColors.warning,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          if (transactions.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No transactions to import',
                  style: AppTypography.bodySm(context),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: transactions.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, index) =>
                    _CsvTransactionRow(transaction: transactions[index]),
              ),
            ),
          if (validCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sectionGap),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: 'Import $validCount',
                      onPressed: onImport,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: AppTypography.bodyMd(
            context,
          ).copyWith(fontWeight: FontWeight.w700, color: color),
        ),
        Text(
          label,
          style: AppTypography.bodySm(
            context,
          ).copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _CsvTransactionRow extends StatelessWidget {
  const _CsvTransactionRow({required this.transaction});

  final CsvTransactionPreview transaction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: transaction.isValid ? AppCardTone.standard : AppCardTone.muted,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: AppTypography.bodyMd(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.category,
                  style: AppTypography.bodySm(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.money(transaction.amount),
                style: AppTypography.bodyMd(
                  context,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                transaction.isValid ? 'Valid' : 'Review',
                style: AppTypography.bodySm(context).copyWith(
                  color: transaction.isValid
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Preview model for CSV transaction during import preview.
class CsvTransactionPreview {
  const CsvTransactionPreview({
    required this.description,
    required this.category,
    required this.amount,
    required this.date,
    this.isValid = true,
    this.validationMessage,
  });

  final String description;
  final String category;
  final double amount;
  final DateTime date;
  final bool isValid;
  final String? validationMessage;
}
