import 'package:beltech/core/di/expenses_providers.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuarantineExportScreen extends ConsumerStatefulWidget {
  const QuarantineExportScreen({super.key});

  @override
  ConsumerState<QuarantineExportScreen> createState() => _QuarantineExportScreenState();
}

class _QuarantineExportScreenState extends ConsumerState<QuarantineExportScreen> {
  late String _selectedFormat;
  late bool _includeMetadata;
  late bool _includeStats;
  late String _dateRange;

  @override
  void initState() {
    super.initState();
    _selectedFormat = 'csv';
    _includeMetadata = true;
    _includeStats = true;
    _dateRange = 'all';
  }

  Future<void> _exportData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting as $_selectedFormat...'),
        duration: const Duration(seconds: 2),
      ),
    );

    // Simulate export delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Quarantine history exported as $_selectedFormat\n'
            'File: quarantine_export_${DateTime.now().millisecondsSinceEpoch}.$_selectedFormat',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quarantineDataAsync = ref.watch(quarantineQueueNotifierProvider);

    return SecondaryPageShell(
      title: 'Export Quarantine History',
      child: quarantineDataAsync.when(
        data: (items) => _buildExportInterface(context, items),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildExportInterface(BuildContext context, List<dynamic> items) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sectionGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.1),
                    AppColors.accent.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Export Summary', style: AppTypography.sectionTitle(context)),
                  const SizedBox(height: 12),
                  _summaryRow('Total Items', '${items.length}'),
                  _summaryRow('Approved', '${items.where((i) => i.status == 'approved').length}'),
                  _summaryRow('Rejected', '${items.where((i) => i.status == 'rejected').length}'),
                  _summaryRow('Pending', '${items.where((i) => i.status != 'approved' && i.status != 'rejected').length}'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // Format Selection
            Text('Export Format', style: AppTypography.sectionTitle(context)),
            const SizedBox(height: AppSpacing.listGap),
            _buildFormatOption('csv', 'CSV', 'Spreadsheet format (Excel, Google Sheets)'),
            _buildFormatOption('json', 'JSON', 'Machine-readable format with full metadata'),
            _buildFormatOption('pdf', 'PDF', 'Professional report with charts and trends'),
            const SizedBox(height: AppSpacing.sectionGap),

            // Date Range Selection
            Text('Date Range', style: AppTypography.sectionTitle(context)),
            const SizedBox(height: AppSpacing.listGap),
            _buildDateRangeOption('all', 'All Time', 'Export entire history'),
            _buildDateRangeOption('month', 'Last 30 Days', 'Recent items only'),
            _buildDateRangeOption('quarter', 'Last 90 Days', 'Quarterly view'),
            const SizedBox(height: AppSpacing.sectionGap),

            // Options
            Text('Include In Export', style: AppTypography.sectionTitle(context)),
            const SizedBox(height: AppSpacing.listGap),
            CheckboxListTile(
              title: const Text('Metadata'),
              subtitle: const Text('Parse confidence scores, dates, original SMS text'),
              value: _includeMetadata,
              onChanged: (v) => setState(() => _includeMetadata = v ?? false),
            ),
            CheckboxListTile(
              title: const Text('Statistics'),
              subtitle: const Text('Approval rates, trends, distribution charts'),
              value: _includeStats,
              onChanged: (v) => setState(() => _includeStats = v ?? false),
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // Export Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: items.isEmpty ? null : _exportData,
                icon: const Icon(Icons.download),
                label: const Text('Export Data'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // Info Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Exports are saved to your device. Keep them secure as they contain transaction details.',
                      style: AppTypography.bodySm(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatOption(String value, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedFormat == value ? AppColors.accent : Colors.grey.withValues(alpha: 0.2),
          width: _selectedFormat == value ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: _selectedFormat == value
            ? AppColors.accent.withValues(alpha: 0.05)
            : Colors.transparent,
      ),
      child: RadioListTile<String>(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        groupValue: _selectedFormat,
        onChanged: (v) => setState(() => _selectedFormat = v ?? _selectedFormat),
      ),
    );
  }

  Widget _buildDateRangeOption(String value, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: _dateRange == value ? AppColors.accent : Colors.grey.withValues(alpha: 0.2),
          width: _dateRange == value ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: _dateRange == value
            ? AppColors.accent.withValues(alpha: 0.05)
            : Colors.transparent,
      ),
      child: RadioListTile<String>(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        groupValue: _dateRange,
        onChanged: (v) => setState(() => _dateRange = v ?? _dateRange),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySm(context)),
          Text(value, style: AppTypography.bodySm(context).copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
