import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_review.dart';
import 'package:flutter/material.dart';

/// A thin persistent strip shown above the Finance screen content, matching
/// the React Native `ImportHealthBanner` pattern.
///
/// States
/// ──────
/// • Green  — all zeros, healthy                 "All imports up to date"
/// • Amber  — retry / failed queue pending       "N pending"
/// • Red    — parse errors present               "N duplicates · N parse failed"
///
/// The strip is always rendered when there is something to report.
/// Tap navigates to the analytics / health panel (via [onTap]).
class ImportHealthBanner extends StatelessWidget {
  const ImportHealthBanner({
    super.key,
    required this.metrics,
    this.onTap,
  });

  final ExpenseImportMetrics metrics;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final duplicates = metrics.reviewQueueCount;
    final parseErrors = metrics.failedQueueCount + metrics.quarantineCount;
    final pending = metrics.retryQueueCount;

    // Nothing unusual — hide the strip entirely.
    if (duplicates == 0 && parseErrors == 0 && pending == 0) {
      return const SizedBox.shrink();
    }

    // Severity → colour
    final Color accent = parseErrors > 0
        ? AppColors.danger
        : pending > 0
            ? AppColors.warning
            : AppColors.success;

    // Build the label parts
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

    final strip = Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        border: Border(
          bottom: BorderSide(
            color: accent.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 13, color: accent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: accent.withValues(alpha: 0.6),
            ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: strip);
    }
    return strip;
  }
}
