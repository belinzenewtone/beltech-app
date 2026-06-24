import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/glass_card.dart';
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
          // File summary
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'File: $fileName',
                        style: AppTypography.bodyMd(context)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      Icon(
                        Icons.description_outlined,
                        color: AppColors.accent,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryItem(
                          label: 'Total',
                          value: '${transactions.length}',
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _SummaryItem(
                          label: 'Valid',
                          value: '$validCount',
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _SummaryItem(
                          label: 'Issues',
                          value: '$invalidCount',
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),

          // Transactions list
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
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.listGap),
                itemBuilder: (_, index) => _CsvTransactionRow(
                  transaction: transactions[index],
                ),
              ),
            ),

          // Import button
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

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
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
          label,
          style: AppTypography.bodySm(context)
              .copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodyMd(context).copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
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
    return GlassCard(
      tone: transaction.isValid ? GlassCardTone.standard : GlassCardTone.muted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      style: AppTypography.cardTitle(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.category,
                      style: AppTypography.bodySm(context)
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.money(transaction.amount),
                    style: AppTypography.amount(context),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (transaction.isValid
                              ? AppColors.success
                              : AppColors.warning)
                          .withValues(alpha: 0.12),
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Text(
                      transaction.isValid ? 'Valid' : 'Review',
                      style: AppTypography.bodySm(context).copyWith(
                        color: transaction.isValid
                            ? AppColors.success
                            : AppColors.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (transaction.validationMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: AppRadius.smAll,
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      transaction.validationMessage!,
                      style: AppTypography.bodySm(context).copyWith(
                        color: AppColors.warning,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
