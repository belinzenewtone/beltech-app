import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_dialog.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/expenses/presentation/providers/csv_import_providers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CsvImportScreen extends ConsumerStatefulWidget {
  const CsvImportScreen({super.key});

  @override
  ConsumerState<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends ConsumerState<CsvImportScreen> {
  String? _filePath;

  static const _fieldKeys = ['date', 'title', 'category', 'amount', 'balance'];
  static const _fieldLabels = {
    'date': 'Date',
    'title': 'Title / Description',
    'category': 'Category',
    'amount': 'Amount (KES)',
    'balance': 'Balance',
  };
  static const _entityFieldMap = {
    'date': 'occurred_at',
    'title': 'title',
    'category': 'category',
    'amount': 'amountKes',
    'balance': 'balanceAfterKes',
  };

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(csvImportStatusProvider);
    return SecondaryPageShell(
      title: 'Import CSV',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilePicker(),
          if (status == CsvImportStatus.previewReady ||
              status == CsvImportStatus.importing) ...[
            const SizedBox(height: AppSpacing.sectionGap),
            _buildColumnMapping(),
            const SizedBox(height: AppSpacing.sectionGap),
            _buildPreview(),
            const SizedBox(height: AppSpacing.sectionGap),
            _buildImportButton(),
          ],
          if (status == CsvImportStatus.done) _buildDoneCard(),
        ],
      ),
    );
  }

  Widget _buildFilePicker() {
    final status = ref.watch(csvImportStatusProvider);
    final isLoading = status == CsvImportStatus.loading;

    return AppCard(
      tone: AppCardTone.accent,
      accentColor: AppColors.accent,
      child: Row(
        children: [
          const Icon(Icons.upload_file_rounded, color: AppColors.accentLight),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _filePath != null
                  ? _filePath!.split('/').last
                  : 'Select a CSV file',
              style: AppTypography.bodyMd(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          AppButton(
            size: AppButtonSize.sm,
            onPressed: isLoading ? null : _pickFile,
            label: 'Browse',
          ),
        ],
      ),
    );
  }

  Widget _buildColumnMapping() {
    final preview = ref.watch(csvImportPreviewProvider)!;
    final mapping = ref.watch(csvImportColumnMappingProvider);
    final headers = preview.headers;
    final brightness = Theme.of(context).brightness;

    return AppCard(
      tone: AppCardTone.muted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Column Mapping', style: AppTypography.cardTitle(context)),
          const SizedBox(height: AppSpacing.md),
          for (final key in _fieldKeys) ...[
            if (key != _fieldKeys.first) const SizedBox(height: AppSpacing.sm),
            _buildMappingRow(key, headers, mapping, brightness),
          ],
        ],
      ),
    );
  }

  Widget _buildMappingRow(
    String fieldKey,
    List<String> headers,
    Map<String, String?> mapping,
    Brightness brightness,
  ) {
    final selectedCol = mapping[fieldKey];
    final items = [null, ...headers];

    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            _fieldLabels[fieldKey]!,
            style: AppTypography.bodySm(context),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceMutedFor(brightness),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selectedCol != null
                    ? AppColors.accent.withValues(alpha: 0.40)
                    : AppColors.borderFor(brightness),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: selectedCol,
                isExpanded: true,
                dropdownColor: AppColors.surfaceElevated,
                style: AppTypography.bodySm(
                  context,
                ).copyWith(color: AppColors.textPrimaryFor(brightness)),
                hint: Text('Skip', style: AppTypography.bodySm(context)),
                items: items.map((col) {
                  return DropdownMenuItem<String?>(
                    value: col,
                    child: Text(
                      col ?? '-- Skip --',
                      style: AppTypography.bodySm(context).copyWith(
                        color: col == null
                            ? AppColors.textMutedFor(brightness)
                            : AppColors.textPrimaryFor(brightness),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  final updated = Map<String, String?>.from(mapping);
                  updated[fieldKey] = val;
                  ref.read(csvImportColumnMappingProvider.notifier).state =
                      updated;
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final preview = ref.watch(csvImportPreviewProvider)!;
    final mapping = ref.watch(csvImportColumnMappingProvider);

    final mappedRows = _mapSamples(
      preview.sampleRows,
      preview.headers,
      mapping,
    );
    if (mappedRows.isEmpty) {
      return AppCard(
        tone: AppCardTone.muted,
        child: Text(
          'Map a column to preview rows.',
          style: AppTypography.bodySm(context),
        ),
      );
    }

    return AppCard(
      tone: AppCardTone.muted,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Preview', style: AppTypography.cardTitle(context)),
              const Spacer(),
              Text(
                '${preview.sampleRows.length} / ${preview.totalRows}',
                style: AppTypography.bodySm(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.surfaceSubtle),
              dataRowMinHeight: 36,
              dataRowMaxHeight: 44,
              headingRowHeight: 36,
              columnSpacing: 16,
              columns: _fieldKeys
                  .where((k) => mapping[k] != null)
                  .map(
                    (k) => DataColumn(
                      label: Text(
                        _fieldLabels[k]!,
                        style: AppTypography.metaText(context).copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryFor(
                            Theme.of(context).brightness,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
              rows: mappedRows.map((row) {
                return DataRow(
                  cells: _fieldKeys
                      .where((k) => mapping[k] != null)
                      .map(
                        (k) => DataCell(
                          Text(
                            row[k] ?? '',
                            style: AppTypography.metaText(context),
                          ),
                        ),
                      )
                      .toList(),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _mapSamples(
    List<List<String>> sampleRows,
    List<String> headers,
    Map<String, String?> mapping,
  ) {
    final colIndex = <String, int>{};
    for (var i = 0; i < headers.length; i++) {
      colIndex[headers[i]] = i;
    }

    return sampleRows.map((row) {
      final mapped = <String, String>{};
      for (final key in _fieldKeys) {
        final col = mapping[key];
        if (col != null) {
          final idx = colIndex[col];
          mapped[key] = idx != null && idx < row.length ? row[idx] : '';
        }
      }
      return mapped;
    }).toList();
  }

  Widget _buildImportButton() {
    final status = ref.watch(csvImportStatusProvider);
    final preview = ref.watch(csvImportPreviewProvider)!;
    final isImporting = status == CsvImportStatus.importing;

    return AppButton(
      onPressed: isImporting ? null : _confirmImport,
      label: isImporting
          ? 'Importing...'
          : 'Import ${preview.totalRows} row${preview.totalRows == 1 ? '' : 's'}',
      fullWidth: true,
    );
  }

  Widget _buildDoneCard() {
    final importCount = ref.watch(csvImportControllerProvider).value ?? 0;
    return AppCard(
      tone: AppCardTone.accent,
      accentColor: AppColors.success,
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.success,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '$importCount transaction${importCount == 1 ? '' : 's'} imported',
              style: AppTypography.bodyMd(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          AppButton(
            size: AppButtonSize.sm,
            variant: AppButtonVariant.secondary,
            onPressed: () {
              ref.read(csvImportControllerProvider.notifier).reset();
              setState(() => _filePath = null);
            },
            label: 'Import Another',
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final platformFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (platformFile == null) return;

      final path = platformFile.path;
      if (path == null) return;

      setState(() => _filePath = path);
      await ref.read(csvImportControllerProvider.notifier).loadPreview(path);
    } catch (e) {
      if (mounted) {
        AppFeedback.error(context, 'Failed to pick file: $e');
      }
    }
  }

  Future<void> _confirmImport() async {
    final mapping = ref.read(csvImportColumnMappingProvider);
    final hasMapping = mapping.values.any((v) => v != null);
    if (!hasMapping) {
      AppFeedback.warning(context, 'Map at least one column before importing.');
      return;
    }

    final entityMapping = <String, String>{};
    for (final key in _fieldKeys) {
      final col = mapping[key];
      if (col != null) {
        entityMapping[_entityFieldMap[key]!] = col;
      }
    }

    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Confirm Import',
          style: AppTypography.sectionTitle(dialogContext),
        ),
        content: Text(
          'Import ${ref.read(csvImportPreviewProvider)!.totalRows} rows from CSV?',
          style: AppTypography.bodyMd(dialogContext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Import',
            size: AppButtonSize.sm,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true || _filePath == null) return;

    try {
      final count = await ref
          .read(csvImportControllerProvider.notifier)
          .runImport(filePath: _filePath!, columnMapping: entityMapping);
      if (mounted) {
        AppFeedback.success(
          context,
          '$count transaction${count == 1 ? '' : 's'} imported.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.error(context, 'Import failed: $e');
      }
    }
  }
}
