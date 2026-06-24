import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/glass_card.dart';
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
    return GlassCard(
      tone: GlassCardTone.accent,
      accentColor: AppColors.accent,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.30),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accentLight.withValues(alpha: 0.40),
              ),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: AppColors.accentLight,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PDF Statement',
                  style: AppTypography.cardTitle(context),
                ),
                const SizedBox(height: 2),
                Text(
                  'Formatted financial statement with summary, categories, and transactions',
                  style: AppTypography.bodySm(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isLoading ? null : onGenerate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.50)),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accentLight,
                      ),
                    )
                  : const Text(
                      'Generate',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentLight,
                      ),
                    ),
            ),
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
    return GlassCard(
      accentColor: isActive ? meta.color : null,
      tone: GlassCardTone.standard,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.20),
              shape: BoxShape.circle,
              border: Border.all(
                color: meta.color.withValues(alpha: 0.30),
              ),
            ),
            child: Icon(meta.icon, color: meta.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exportScopeLabel(meta.scope),
                  style: AppTypography.cardTitle(context),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        meta.description,
                        style: AppTypography.bodySm(context),
                      ),
                    ),
                    if (rowsExported != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: meta.color.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$rowsExported rows',
                          style: TextStyle(
                            fontSize: 10,
                            color: meta.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isLoading ? null : onExport,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: meta.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: meta.color.withValues(alpha: 0.45)),
              ),
              child: Text(
                'CSV',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: meta.color,
                ),
              ),
            ),
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
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: AppColors.success,
              ),
              const SizedBox(width: 6),
              Text(
                'Last Export',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: AppColors.success),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${result.rowsExported} rows',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.insert_drive_file_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  filename,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isLoading
                  ? null
                  : () async {
                      await Share.shareXFiles(
                        [XFile(result.filePath)],
                        subject: 'BELTECH Export',
                      );
                    },
              icon: const Icon(Icons.share_outlined, size: 16),
              label: const Text('Share File'),
            ),
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
