import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_detection.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_window.dart';
import 'package:flutter/material.dart';

/// Result of the detect-then-confirm SMS import flow.
class SmsImportPlan {
  const SmsImportPlan({required this.window, required this.filter});

  final ExpenseImportWindow window;
  final ImportSourceFilter filter;
}

/// Kotlin-style detect-then-confirm SMS import bottom sheet.
///
/// Three steps (mirrors the Kotlin reference `SmsImportBottomSheet`):
///  1. Pick provider filter + time window → triggers a detect-only scan
///  2. Show detected institution counts (with a scanning state)
///  3. Confirm "Import All" or Cancel
///
/// Returns an [SmsImportPlan] when the user confirms; `null` on cancel/dismiss.
Future<SmsImportPlan?> showSmsDetectImportDialog(
  BuildContext context, {
  required Future<ExpenseImportDetection> Function(
    ExpenseImportWindow window,
    ImportSourceFilter filter,
  )
  onDetect,
}) {
  return showModalBottomSheet<SmsImportPlan>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _SmsDetectImportSheet(
      onDetect: (window, filter) async {
        final result = await onDetect(window, filter);
        if (sheetContext.mounted) {
          return result;
        }
        return result;
      },
    ),
  );
}

class _SmsDetectImportSheet extends StatefulWidget {
  const _SmsDetectImportSheet({required this.onDetect});

  final Future<ExpenseImportDetection> Function(
    ExpenseImportWindow window,
    ImportSourceFilter filter,
  )
  onDetect;

  @override
  State<_SmsDetectImportSheet> createState() => _SmsDetectImportSheetState();
}

class _SmsDetectImportSheetState extends State<_SmsDetectImportSheet> {
  ImportSourceFilter _filter = ImportSourceFilter.both;
  ExpenseImportWindow? _pendingWindow;
  ExpenseImportDetection? _detection;
  bool _scanning = false;

  static const _windows = [
    (ExpenseImportWindow.last24Hours, 'Last 24 hours'),
    (ExpenseImportWindow.lastMonth, 'Last month'),
    (ExpenseImportWindow.last3Months, 'Last 3 months'),
    (ExpenseImportWindow.last6Months, 'Last 6 months'),
  ];

  static const _filterOptions = [
    (ImportSourceFilter.both, 'M-Pesa + Banks'),
    (ImportSourceFilter.mpesa, 'M-Pesa Only'),
    (ImportSourceFilter.banks, 'Banks Only'),
  ];

  Future<void> _runDetect(ExpenseImportWindow window) async {
    setState(() {
      _pendingWindow = window;
      _detection = null;
      _scanning = true;
    });
    final result = await widget.onDetect(window, _filter);
    if (!mounted) {
      return;
    }
    setState(() {
      _scanning = false;
      _detection = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: AppCardTone.muted,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: 0),
      borderRadius: AppRadius.xxl,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Import SMS Transactions',
                      style: AppTypography.sectionTitle(context),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              if (_scanning)
                _buildScanning()
              else if (_detection != null)
                _buildCounts(_detection!)
              else
                _buildSetup(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetup() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose what to import',
          style: AppTypography.bodySm(context),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final (filter, label) in _filterOptions) ...[
          _SelectableRow(
            selected: _filter == filter,
            title: label,
            onTap: () => setState(() {
              _filter = filter;
              _detection = null;
            }),
          ),
          const SizedBox(height: 6),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(
          'Select time period to scan',
          style: AppTypography.bodySm(context),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final (window, label) in _windows) ...[
          _WindowTile(label: label, onTap: () => _runDetect(window)),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _buildScanning() {
    return Row(
      children: [
        const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Scanning inbox…', style: AppTypography.bodyMd(context)),
              Text(
                'Detecting financial SMS',
                style: AppTypography.metaText(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCounts(ExpenseImportDetection detection) {
    final total = detection.totalMessages;
    final entries = detection.institutionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final pendingWindow = _pendingWindow;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          total == 0
              ? 'No new messages found for this period.'
              : 'Found $total message${total == 1 ? '' : 's'} across '
                    '${entries.length} source${entries.length == 1 ? '' : 's'}',
          style: AppTypography.bodySm(context),
        ),
        if (entries.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          for (final entry in entries) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      institutionDisplayName(entry.key),
                      style: AppTypography.bodyMd(context),
                    ),
                  ),
                  Text(
                    '${entry.value} msg${entry.value == 1 ? '' : 's'}',
                    style: AppTypography.metaText(context),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            if (total > 0) ...[
              const SizedBox(width: 8),
              AppButton(
                label: 'Import All',
                onPressed: () => Navigator.of(context).pop(
                  SmsImportPlan(
                    window: pendingWindow ??
                        detection.window,
                    filter: detection.filter,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _SelectableRow extends StatelessWidget {
  const _SelectableRow({
    required this.selected,
    required this.title,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 18,
              color: selected ? AppColors.accent : AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Text(title, style: AppTypography.bodyMd(context)),
          ],
        ),
      ),
    );
  }
}

class _WindowTile extends StatelessWidget {
  const _WindowTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceMutedFor(Theme.of(context).brightness),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.borderFor(Theme.of(context).brightness),
          ),
        ),
        child: Text(label, style: AppTypography.bodyMd(context)),
      ),
    );
  }
}
