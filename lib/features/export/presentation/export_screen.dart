import 'dart:async';

import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_dialog.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/glass_card.dart';
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
          // ── PDF Statement — prominent full-width card ─────────────────────
          PdfStatementCard(
            isLoading: exportState.isLoading,
            result: latestResult,
            onGenerate: () async {
              final confirmed = await _confirmExport(
                context,
                scope: ExportScope.all,
              );
              if (confirmed != true) {
                return;
              }
              await ref
                  .read(exportControllerProvider.notifier)
                  .exportPdfStatement(
                    startDate: _startDate,
                    endDate: _endDate,
                  );
            },
          ),

          const SizedBox(height: 12),
          // ── Export all — prominent full-width card ───────────────────────
          GlassCard(
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
                    Icons.download_rounded,
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
                        'Export All',
                        style: AppTypography.cardTitle(context),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'One CSV with every data type',
                        style: AppTypography.bodySm(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: exportState.isLoading
                      ? null
                      : () async {
                          final confirmed = await _confirmExport(
                            context,
                            scope: ExportScope.all,
                          );
                          if (confirmed != true) {
                            return;
                          }
                          await ref
                              .read(exportControllerProvider.notifier)
                              .export(ExportScope.all,
                                  password: _passwordCtrl.text.isNotEmpty
                                      ? _passwordCtrl.text
                                      : null,
                                  startDate: _startDate,
                                  endDate: _endDate);
                        },
                  child: exportState.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Export'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          // ── Encryption toggle ─────────────────────────────────────────────
          GlassCard(
            tone: GlassCardTone.muted,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: Text('Encrypt export', style: AppTypography.bodyMd(context)),
                  subtitle: Text('Password-protect with AES-256', style: AppTypography.bodySm(context)),
                  value: _encrypt,
                  onChanged: (v) => setState(() => _encrypt = v),
                  activeColor: AppColors.accent,
                ),
                if (_encrypt) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        hintText: 'Min 6 characters',
                        prefixIcon: Icon(Icons.lock_outline, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),
          // ── Date range ───────────────────────────────────────────────────────
          GlassCard(
            tone: GlassCardTone.muted,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Date range', style: AppTypography.bodyMd(context)),
                    const Spacer(),
                    if (_startDate != null || _endDate != null)
                      GestureDetector(
                        onTap: () =>
                            setState(() {
                              _startDate = null;
                              _endDate = null;
                            }),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.close, size: 16,
                                color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text('Clear',
                                style: AppTypography.bodySm(context).copyWith(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('to',
                          style: AppTypography.bodySm(context)
                              .copyWith(color: AppColors.textSecondary)),
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

          const SizedBox(height: 16),
          Text(
            'By Category',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),

          // ── Per-scope cards ──────────────────────────────────────────────
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
                if (confirmed != true) {
                  return;
                }
                await ref
                    .read(exportControllerProvider.notifier)
                    .export(meta.scope,
                        password: _passwordCtrl.text.isNotEmpty
                            ? _passwordCtrl.text
                            : null,
                        startDate: _startDate,
                        endDate: _endDate);
              },
            ),
            const SizedBox(height: 8),
          ],

          // ── Latest export result ─────────────────────────────────────────
          if (latestResult != null) ...[
            const SizedBox(height: 8),
            LatestExportCard(
              result: latestResult,
              isLoading: exportState.isLoading,
            ),
          ],

          const SizedBox(height: 8),
          GlassCard(
            tone: GlassCardTone.muted,
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Files are saved as CSV to the app documents directory.',
                    style: AppTypography.bodySm(context),
                  ),
                ),
              ],
            ),
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(10),
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
              color:
                  date != null ? AppColors.accentLight : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                date != null ? _fmt(date!) : label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: date != null ? FontWeight.w600 : FontWeight.w400,
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
      title: Text('Export $label?'),
      content: Text(
        'This creates a CSV file for $label in the app documents directory. '
        'Continue only if this is the export you want right now.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Export'),
        ),
      ],
    ),
  );
}
