import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_review.dart';
import 'package:flutter/material.dart';

/// Floating overlay banner shown on the Finance screen when import issues exist.
///
/// • Appears on top of the scroll content (no layout shift).
/// • Shows once per session — dismissed via the [onDismiss] callback.
/// • Tap navigates to the health screen via [onTap].
class ImportHealthBanner extends StatelessWidget {
  const ImportHealthBanner({
    super.key,
    required this.metrics,
    this.onTap,
    this.onDismiss,
  });

  final ExpenseImportMetrics metrics;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    // "Pending" = items awaiting retry; "duplicates" = messages skipped because
    // they were already imported (duplicateSkipCount); "parse failed" =
    // quarantined + failed (unrecognised or errored messages).
    final pending = metrics.retryQueueCount;
    final duplicates = metrics.duplicateSkipCount;
    final parseErrors = metrics.failedQueueCount + metrics.quarantineCount;

    if (!metrics.hasIssues) return const SizedBox.shrink();

    final Color accent = parseErrors > 0
        ? AppColors.danger
        : pending > 0
        ? AppColors.warning
        : AppColors.success;

    final parts = <String>[];
    if (pending > 0) parts.add('$pending pending');
    if (duplicates > 0) parts.add('$duplicates duplicates');
    if (parseErrors > 0) parts.add('$parseErrors parse failed');
    final label = parts.join(' · ');

    final icon = parseErrors > 0
        ? Icons.error_outline_rounded
        : pending > 0
        ? Icons.access_time_rounded
        : Icons.check_circle_outline_rounded;

    final brightness = Theme.of(context).brightness;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: brightness == Brightness.dark
                  ? AppColors.surfaceElevated.withValues(alpha: 0.96)
                  : Colors.white.withValues(alpha: 0.97),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: accent.withValues(alpha: 0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, size: 15, color: accent),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryFor(brightness),
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: accent.withValues(alpha: 0.7),
                  ),
                ],
                const SizedBox(width: AppSpacing.xs),
                // Dismiss button
                GestureDetector(
                  onTap: onDismiss,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: AppColors.textMuted.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
