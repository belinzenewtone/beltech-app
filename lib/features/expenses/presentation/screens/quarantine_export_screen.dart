import 'package:beltech/core/di/expenses_providers.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuarantineExportScreen extends ConsumerStatefulWidget {
  const QuarantineExportScreen({super.key});

  @override
  ConsumerState<QuarantineExportScreen> createState() =>
      _QuarantineExportScreenState();
}

class _QuarantineExportScreenState
    extends ConsumerState<QuarantineExportScreen> {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          tone: AppCardTone.muted,
          child: Column(
            children: [
              _summaryRow('Total', '${items.length}'),
              _summaryRow(
                'Approved',
                '${items.where((i) => i.status == 'approved').length}',
              ),
              _summaryRow(
                'Rejected',
                '${items.where((i) => i.status == 'rejected').length}',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        Text('Format', style: AppTypography.sectionTitle(context)),
        const SizedBox(height: AppSpacing.sm),
        RadioGroup<String>(
          groupValue: _selectedFormat,
          onChanged: (v) =>
              setState(() => _selectedFormat = v ?? _selectedFormat),
          child: Column(
            children: [
              _buildFormatOption('csv', 'CSV'),
              _buildFormatOption('json', 'JSON'),
              _buildFormatOption('pdf', 'PDF'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        Text('Date Range', style: AppTypography.sectionTitle(context)),
        const SizedBox(height: AppSpacing.sm),
        RadioGroup<String>(
          groupValue: _dateRange,
          onChanged: (v) => setState(() => _dateRange = v ?? _dateRange),
          child: Column(
            children: [
              _buildDateRangeOption('all', 'All Time'),
              _buildDateRangeOption('month', 'Last 30 Days'),
              _buildDateRangeOption('quarter', 'Last 90 Days'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppCard(
          tone: AppCardTone.muted,
          child: Column(
            children: [
              CheckboxListTile(
                title: const Text('Metadata'),
                value: _includeMetadata,
                onChanged: (v) => setState(() => _includeMetadata = v ?? false),
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Statistics'),
                value: _includeStats,
                onChanged: (v) => setState(() => _includeStats = v ?? false),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppButton(
          onPressed: items.isEmpty ? null : _exportData,
          label: 'Export',
          fullWidth: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          onPressed: () => Navigator.pop(context),
          label: 'Cancel',
          variant: AppButtonVariant.secondary,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildFormatOption(String value, String title) {
    return AppCard(
      tone: _selectedFormat == value
          ? AppCardTone.accent
          : AppCardTone.standard,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: RadioListTile<String>(
        title: Text(title, style: AppTypography.bodyMd(context)),
        value: value,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildDateRangeOption(String value, String title) {
    return AppCard(
      tone: _dateRange == value ? AppCardTone.accent : AppCardTone.standard,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: RadioListTile<String>(
        title: Text(title, style: AppTypography.bodyMd(context)),
        value: value,
        contentPadding: EdgeInsets.zero,
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
          Text(
            value,
            style: AppTypography.bodySm(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
