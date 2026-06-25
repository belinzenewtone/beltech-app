import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/export/domain/entities/export_result.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class PdfStatementCard extends StatelessWidget {
  const PdfStatementCard({
    super.key,
    required this.isLoading,
    required this.onGenerate,
    this.result,
  });

  final bool isLoading;
  final VoidCallback onGenerate;
  final ExportResult? result;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: AppCardTone.accent,
      accentColor: AppColors.accent,
      child: Row(
        children: [
          const Icon(
            Icons.picture_as_pdf_rounded,
            color: AppColors.accentLight,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'PDF Statement',
              style: AppTypography.bodyMd(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          AppButton(
            size: AppButtonSize.sm,
            onPressed: isLoading ? null : onGenerate,
            label: 'Generate',
          ),
        ],
      ),
    );
  }
}

class ExportScopeMeta {
  const ExportScopeMeta({
    required this.scope,
    required this.icon,
    required this.color,
    required this.description,
  });

  final ExportScope scope;
  final IconData icon;
  final Color color;
  final String description;
}

const exportScopeMetas = [
  ExportScopeMeta(
    scope: ExportScope.expenses,
    icon: Icons.receipt_long_outlined,
    color: AppColors.accent,
    description: 'All M-Pesa & manual transactions',
  ),
  ExportScopeMeta(
    scope: ExportScope.incomes,
    icon: Icons.trending_up_rounded,
    color: AppColors.success,
    description: 'Income records and sources',
  ),
  ExportScopeMeta(
    scope: ExportScope.tasks,
    icon: Icons.task_alt_rounded,
    color: AppColors.teal,
    description: 'Tasks, priorities, due dates',
  ),
  ExportScopeMeta(
    scope: ExportScope.events,
    icon: Icons.event_outlined,
    color: AppColors.violet,
    description: 'Calendar events and reminders',
  ),
  ExportScopeMeta(
    scope: ExportScope.budgets,
    icon: Icons.donut_large_outlined,
    color: AppColors.warning,
    description: 'Budget targets by category',
  ),
  ExportScopeMeta(
    scope: ExportScope.recurring,
    icon: Icons.repeat_rounded,
    color: AppColors.categoryBill,
    description: 'Recurring payment templates',
  ),
];

class ExportScopeCard extends StatelessWidget {
  const ExportScopeCard({
    super.key,
    required this.meta,
    required this.isLoading,
    required this.isActive,
    required this.rowsExported,
    required this.onExport,
  });

  final ExportScopeMeta meta;
  final bool isLoading;
  final bool isActive;
  final int? rowsExported;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      accentColor: isActive ? meta.color : null,
      tone: AppCardTone.standard,
      child: Row(
        children: [
          Icon(meta.icon, color: meta.color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exportScopeLabel(meta.scope),
                  style: AppTypography.bodyMd(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                if (rowsExported != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$rowsExported rows',
                    style: AppTypography.bodySm(
                      context,
                    ).copyWith(color: meta.color),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppButton(
            size: AppButtonSize.sm,
            variant: AppButtonVariant.secondary,
            onPressed: isLoading ? null : onExport,
            label: 'CSV',
          ),
        ],
      ),
    );
  }
}

class LatestExportCard extends StatelessWidget {
  const LatestExportCard({
    super.key,
    required this.result,
    required this.isLoading,
  });

  final ExportResult result;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final filename = result.filePath.split('/').last;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Last Export',
                style: AppTypography.bodyMd(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${result.rowsExported} rows',
                style: AppTypography.bodySm(
                  context,
                ).copyWith(color: AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            filename,
            style: AppTypography.bodySm(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          AppButton(
            onPressed: isLoading
                ? null
                : () async {
                    await Share.shareXFiles([
                      XFile(result.filePath),
                    ], subject: 'BELTECH Export');
                  },
            icon: Icons.share_outlined,
            label: 'Share',
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}

String exportScopeLabel(ExportScope scope) {
  return switch (scope) {
    ExportScope.all => 'All Data',
    ExportScope.expenses => 'Expenses',
    ExportScope.incomes => 'Incomes',
    ExportScope.tasks => 'Tasks',
    ExportScope.events => 'Events',
    ExportScope.budgets => 'Budgets',
    ExportScope.recurring => 'Recurring',
  };
}
