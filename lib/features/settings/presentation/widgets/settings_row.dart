import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Reusable setting row matching the mature Kotlin reference design.
///
/// - Leading circular icon background.
/// - Title + optional subtitle.
/// - Trailing widget (toggle, chevron, value, etc.).
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.iconColor,
    this.iconBackgroundColor,
    this.titleColor,
    this.onTap,
    this.isFirst = false,
    this.isLast = false,
    this.dividerAbove = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final Color? titleColor;
  final VoidCallback? onTap;
  final bool isFirst;
  final bool isLast;
  final bool dividerAbove;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor:
              iconBackgroundColor ?? AppColors.accent.withValues(alpha: 0.16),
          child: Icon(icon, color: iconColor ?? AppColors.accent, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.cardTitle(
                  context,
                ).copyWith(color: titleColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppTypography.bodySm(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );

    Widget row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: content,
    );

    if (onTap != null) {
      row = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(AppRadius.lg) : Radius.zero,
          bottom: isLast ? const Radius.circular(AppRadius.lg) : Radius.zero,
        ),
        child: row,
      );
    }

    if (dividerAbove) {
      row = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(
            height: 1,
            indent: 56,
            color: AppColors.border.withValues(alpha: 0.35),
          ),
          row,
        ],
      );
    }

    return row;
  }
}

/// A compact segmented pill selector for settings (e.g. theme mode).
class SettingsSegmentedPill<T> extends StatelessWidget {
  const SettingsSegmentedPill({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<SettingsSegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtleFor(brightness),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: AppColors.borderFor(brightness).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: options.map((option) {
          final isSelected = option.value == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(option.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Center(
                  child: Text(
                    option.label,
                    style: AppTypography.body(context).copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class SettingsSegmentOption<T> {
  const SettingsSegmentOption({required this.value, required this.label});

  final T value;
  final String label;
}
