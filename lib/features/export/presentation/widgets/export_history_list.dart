import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_skeleton.dart';
import 'package:beltech/features/export/domain/entities/export_history_entry.dart';
import 'package:beltech/features/export/domain/entities/export_result.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExportHistoryList extends StatelessWidget {
  const ExportHistoryList({
    super.key,
    required this.entries,
    this.isLoading = false,
  });

  final List<ExportHistoryEntry>? entries;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading || entries == null) {
      return const _HistorySkeleton();
    }
    if (entries!.isEmpty) {
      return Text(
        'No exports yet. Generated exports will appear here.',
        style: AppTypography.bodySm(
          context,
        ).copyWith(color: AppColors.textMuted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('History', style: AppTypography.cardTitle(context)),
        const SizedBox(height: AppSpacing.md),
        ...entries!.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == entries!.length - 1;
          return Column(
            children: [
              _HistoryRow(entry: item),
              if (!isLast)
                const Divider(
                  height: 24,
                  thickness: 1,
                  color: AppColors.border,
                ),
            ],
          );
        }),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final ExportHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(entry.createdAt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${exportScopeLabel(entry.scope).toLowerCase()} · ${entry.format.name.toUpperCase()} · ${entry.status}',
                style: AppTypography.bodyMd(
                  context,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$dateStr · items ${entry.rowsExported}',
          style: AppTypography.bodySm(
            context,
          ).copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('History', style: AppTypography.cardTitle(context)),
        const SizedBox(height: AppSpacing.md),
        for (final _ in [1, 2, 3]) ...[
          const SizedBox(
            width: double.infinity,
            height: 14,
            child: AppSkeleton(
              width: double.infinity,
              height: 14,
              borderRadius: 6,
            ),
          ),
          const SizedBox(height: 6),
          const SizedBox(
            width: 140,
            height: 12,
            child: AppSkeleton(width: 140, height: 12, borderRadius: 6),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
