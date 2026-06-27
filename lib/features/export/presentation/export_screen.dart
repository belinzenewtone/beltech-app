import 'dart:async';

import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/export/domain/entities/export_format.dart';
import 'package:beltech/features/export/domain/entities/export_result.dart';
import 'package:beltech/features/export/presentation/providers/export_providers.dart';
import 'package:beltech/features/export/presentation/widgets/export_dropdown_field.dart';
import 'package:beltech/features/export/presentation/widgets/export_format_selector.dart';
import 'package:beltech/features/export/presentation/widgets/export_history_list.dart';
import 'package:beltech/features/export/presentation/widgets/export_preview_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  ExportFormat _format = ExportFormat.csv;
  ExportScope _domain = ExportScope.all;
  ExportDateWindow _window = ExportDateWindow.allTime;
  bool _encrypt = false;
  DateTime? _customStart;
  DateTime? _customEnd;
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exportState = ref.watch(exportControllerProvider);
    final previewAsync = ref.watch(exportPreviewCountsProvider);
    final historyAsync = ref.watch(exportHistoryProvider);

    ref.listen<AsyncValue<ExportResult?>>(exportControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError) {
        AppFeedback.error(
          context,
          '${next.error}'.replaceFirst('Exception: ', ''),
        );
      } else if (previous is AsyncLoading && next.hasValue) {
        final result = next.value;
        if (result != null) {
          AppFeedback.success(
            context,
            'Export complete: ${result.rowsExported} row(s).${result.isEncrypted ? ' Encrypted.' : ''}',
          );
          ref.invalidate(exportHistoryProvider);
          unawaited(_shareExportFile(result));
        }
      }
    });

    return SecondaryPageShell(
      title: '',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data Portability',
                style: AppTypography.eyebrow(
                  context,
                ).copyWith(color: AppColors.accent),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('Export Center', style: AppTypography.pageTitle(context)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Export or backup your data',
                style: AppTypography.bodyMd(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Form card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a format, scope, and date window before generating the export.',
                  style: AppTypography.bodySm(context),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Format', style: AppTypography.label(context)),
                const SizedBox(height: AppSpacing.sm),
                ExportFormatSelector(
                  selected: _format,
                  onChanged: (f) => setState(() => _format = f),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Domain', style: AppTypography.label(context)),
                const SizedBox(height: AppSpacing.sm),
                ExportDropdownField<ExportScope>(
                  value: _domain,
                  items: ExportScope.values
                      .map(
                        (s) => ExportDropdownItem(
                          value: s,
                          label: exportScopeLabel(s),
                        ),
                      )
                      .toList(),
                  onChanged: (s) => setState(() => _domain = s),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Date window', style: AppTypography.label(context)),
                const SizedBox(height: AppSpacing.sm),
                ExportDropdownField<ExportDateWindow>(
                  value: _window,
                  items: const [
                    ExportDropdownItem(
                      value: ExportDateWindow.allTime,
                      label: 'all time',
                    ),
                    ExportDropdownItem(
                      value: ExportDateWindow.last7Days,
                      label: 'last 7 days',
                    ),
                    ExportDropdownItem(
                      value: ExportDateWindow.last30Days,
                      label: 'last 30 days',
                    ),
                    ExportDropdownItem(
                      value: ExportDateWindow.thisMonth,
                      label: 'this month',
                    ),
                    ExportDropdownItem(
                      value: ExportDateWindow.custom,
                      label: 'custom',
                    ),
                  ],
                  onChanged: (w) => setState(() => _window = w),
                ),
                if (_window == ExportDateWindow.custom) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          label: 'Start',
                          date: _customStart,
                          lastDate: _customEnd,
                          onChanged: (d) => setState(() => _customStart = d),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: Text(
                          'to',
                          style: AppTypography.bodySm(
                            context,
                          ).copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                      Expanded(
                        child: _DateField(
                          label: 'End',
                          date: _customEnd,
                          firstDate: _customStart,
                          onChanged: (d) => setState(() => _customEnd = d),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Encrypt file',
                            style: AppTypography.bodyMd(
                              context,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Protect the export with a passphrase when the file is leaving your device.',
                            style: AppTypography.bodySm(context),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _encrypt,
                      onChanged: (v) => setState(() => _encrypt = v),
                      activeThumbColor: AppColors.accent,
                      activeTrackColor: AppColors.accent.withValues(alpha: 0.4),
                    ),
                  ],
                ),
                if (_encrypt) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline, size: 18),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: _format == ExportFormat.pdf
                      ? 'Export PDF'
                      : 'Export now',
                  fullWidth: true,
                  loading: exportState.isLoading,
                  onPressed: exportState.isLoading ? null : _onExport,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),

          // Preview card
          AppCard(
            child: ExportPreviewGrid(
              counts: previewAsync.value,
              isLoading: previewAsync.isLoading,
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),

          // History card
          AppCard(
            child: ExportHistoryList(
              entries: historyAsync.value,
              isLoading: historyAsync.isLoading,
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
        ],
      ),
    );
  }

  Future<void> _onExport() async {
    await ref
        .read(exportControllerProvider.notifier)
        .export(
          scope: _domain,
          format: _format,
          window: _window,
          password: _encrypt && _passwordCtrl.text.isNotEmpty
              ? _passwordCtrl.text
              : null,
          customStart: _customStart,
          customEnd: _customEnd,
        );
  }

  Future<void> _shareExportFile(ExportResult result) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(result.filePath)],
          subject: 'BELTECH Export - ${exportScopeLabel(result.scope)}',
        ),
      );
    } catch (_) {
      // Best-effort share trigger: export remains available via history.
    }
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
  });

  final String label;
  final DateTime? date;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: firstDate ?? DateTime(2020),
          lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.accent,
                onPrimary: Colors.white,
                surface: AppColors.surfaceFor(brightness),
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceMutedFor(brightness),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: date != null
                ? AppColors.accent.withValues(alpha: 0.40)
                : AppColors.borderFor(brightness),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: date != null
                  ? AppColors.accentLight
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                date != null ? _fmt(date!) : label,
                style:
                    (date != null
                            ? AppTypography.bodySm(
                                context,
                              ).copyWith(fontWeight: FontWeight.w600)
                            : AppTypography.bodySm(context))
                        .copyWith(
                          color: date != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}
