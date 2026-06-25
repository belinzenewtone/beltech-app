import 'dart:async';

import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_dialog.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/export/domain/entities/export_result.dart';
import 'package:beltech/features/export/presentation/providers/export_providers.dart';
import 'package:beltech/features/export/presentation/widgets/export_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  bool _encrypt = false;
  DateTime? _startDate;
  DateTime? _endDate;
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exportState = ref.watch(exportControllerProvider);
    final latestResult = exportState.valueOrNull;

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
        final result = next.valueOrNull;
        if (result != null) {
          AppFeedback.success(
            context,
            'Export complete: ${result.rowsExported} row(s).${result.isEncrypted ? ' Encrypted.' : ''}',
          );
          unawaited(_shareExportFile(result));
        }
      }
    });

    return SecondaryPageShell(
      title: 'Export Data',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PdfStatementCard(
            isLoading: exportState.isLoading,
            result: latestResult,
            onGenerate: () async {
              final confirmed = await _confirmExport(
                context,
                scope: ExportScope.all,
              );
              if (confirmed != true) return;
              await ref
                  .read(exportControllerProvider.notifier)
                  .exportPdfStatement(startDate: _startDate, endDate: _endDate);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            tone: AppCardTone.accent,
            accentColor: AppColors.accent,
            child: Row(
              children: [
                const Icon(
                  Icons.download_rounded,
                  color: AppColors.accentLight,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Export All',
                    style: AppTypography.bodyMd(
                      context,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                AppButton(
                  size: AppButtonSize.sm,
                  onPressed: exportState.isLoading
                      ? null
                      : () async {
                          final confirmed = await _confirmExport(
                            context,
                            scope: ExportScope.all,
                          );
                          if (confirmed != true) return;
                          await ref
                              .read(exportControllerProvider.notifier)
                              .export(
                                ExportScope.all,
                                password: _passwordCtrl.text.isNotEmpty
                                    ? _passwordCtrl.text
                                    : null,
                                startDate: _startDate,
                                endDate: _endDate,
                              );
                        },
                  label: 'Export',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            tone: AppCardTone.muted,
            child: SwitchListTile(
              title: Text(
                'Encrypt export',
                style: AppTypography.bodyMd(context),
              ),
              value: _encrypt,
              onChanged: (v) => setState(() => _encrypt = v),
              activeThumbColor: AppColors.accent,
              contentPadding: EdgeInsets.zero,
            ),
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
          AppCard(
            tone: AppCardTone.muted,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Date range', style: AppTypography.bodyMd(context)),
                    const Spacer(),
                    if (_startDate != null || _endDate != null)
                      TextButton(
                        onPressed: () => setState(() {
                          _startDate = null;
                          _endDate = null;
                        }),
                        child: const Text('Clear'),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'Start',
                        date: _startDate,
                        lastDate: _endDate,
                        onChanged: (d) => setState(() => _startDate = d),
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
                        date: _endDate,
                        firstDate: _startDate,
                        onChanged: (d) => setState(() => _endDate = d),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'By Category',
            style: AppTypography.bodySm(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final meta in exportScopeMetas) ...[
            ExportScopeCard(
              meta: meta,
              isLoading: exportState.isLoading,
              isActive: latestResult?.scope == meta.scope,
              rowsExported: latestResult?.scope == meta.scope
                  ? latestResult!.rowsExported
                  : null,
              onExport: () async {
                final confirmed = await _confirmExport(
                  context,
                  scope: meta.scope,
                );
                if (confirmed != true) return;
                await ref
                    .read(exportControllerProvider.notifier)
                    .export(
                      meta.scope,
                      password: _passwordCtrl.text.isNotEmpty
                          ? _passwordCtrl.text
                          : null,
                      startDate: _startDate,
                      endDate: _endDate,
                    );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (latestResult != null) ...[
            LatestExportCard(
              result: latestResult,
              isLoading: exportState.isLoading,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _shareExportFile(ExportResult result) async {
    try {
      await Share.shareXFiles([
        XFile(result.filePath),
      ], subject: 'BELTECH Export - ${exportScopeLabel(result.scope)}');
    } catch (_) {
      // Best-effort share trigger: export remains available via the card.
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
                surface: AppColors.surfaceElevated,
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
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: date != null
                ? AppColors.accent.withValues(alpha: 0.40)
                : AppColors.border,
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

Future<bool?> _confirmExport(
  BuildContext context, {
  required ExportScope scope,
}) {
  final label = exportScopeLabel(scope);
  return showAppDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        'Export $label?',
        style: AppTypography.sectionTitle(dialogContext),
      ),
      content: Text(
        'This creates a CSV file for $label in the app documents directory.',
        style: AppTypography.bodyMd(dialogContext),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: 'Export',
          size: AppButtonSize.sm,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
}
