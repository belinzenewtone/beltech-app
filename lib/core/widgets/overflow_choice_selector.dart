import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// A generic single-line option selector.
///
/// Renders the options as a horizontal row of chips/buttons when they all fit
/// on one line. When the combined width exceeds the available width, it falls
/// back to a compact dropdown menu so the UI never wraps into multiple
/// cluttered rows.
///
/// Usage:
/// ```dart
/// OverflowChoiceSelector<String>(
///   options: ['A', 'B', 'C', ...],
///   selected: current,
///   labelFor: (o) => o,
///   onChanged: (o) => setState(...),
/// )
/// ```
class OverflowChoiceSelector<T> extends StatelessWidget {
  const OverflowChoiceSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.labelFor,
    required this.onChanged,
    this.selectedTest,
    this.iconFor,
    this.colorFor,
    this.hint = 'Select…',
    this.leadingIcon,
  });

  final List<T> options;

  /// The currently selected option (or null when nothing is selected).
  final T? selected;

  /// How to render an option as text.
  final String Function(T option) labelFor;

  final ValueChanged<T> onChanged;

  /// Optional custom equality test (defaults to `==`).
  final bool Function(T option)? selectedTest;

  /// Optional per-option leading icon.
  final IconData Function(T option)? iconFor;

  /// Optional per-option accent color.
  final Color Function(T option)? colorFor;

  /// Placeholder shown when nothing is selected.
  final String hint;

  /// Optional leading icon shown on the dropdown trigger.
  final IconData? leadingIcon;

  bool _isSelected(T option) =>
      selectedTest?.call(option) ?? option == selected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = _measureRowWidth(context, constraints.maxWidth);

        // When everything fits on one line → horizontal chips row.
        if (totalWidth <= constraints.maxWidth) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, option) in options.indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  _Chip(
                    label: labelFor(option),
                    icon: iconFor?.call(option),
                    color: colorFor?.call(option),
                    selected: _isSelected(option),
                    onTap: () => onChanged(option),
                  ),
                ],
              ],
            ),
          );
        }

        // Overflow → dropdown menu.
        final selectedOption = options.where(_isSelected).firstOrNull;
        return _DropdownTrigger<T>(
          hint: hint,
          leadingIcon: leadingIcon,
          selectedLabel: selectedOption == null
              ? null
              : labelFor(selectedOption),
          selectedIcon: selectedOption == null
              ? null
              : iconFor?.call(selectedOption),
          selectedColor: selectedOption == null
              ? null
              : colorFor?.call(selectedOption),
          options: options,
          labelFor: labelFor,
          iconFor: iconFor,
          colorFor: colorFor,
          isSelected: _isSelected,
          onChanged: onChanged,
        );
      },
    );
  }

  /// Estimates the total width of the chip row (label text + icon + padding).
  double _measureRowWidth(BuildContext context, double maxWidth) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        );
    var total = 0.0;
    for (final (i, option) in options.indexed) {
      final label = labelFor(option);
      final painter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      var width = painter.width + 32.0; // horizontal padding
      if (iconFor?.call(option) != null) width += 22.0; // icon + gap
      if (i > 0) width += 8.0; // spacing
      total += width;
    }
    return total;
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.accent;
    final brightness = Theme.of(context).brightness;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            color: selected
                ? accent.withValues(alpha: 0.18)
                : AppColors.surfaceMutedFor(brightness),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.5)
                  : AppColors.borderFor(brightness),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: selected ? accent : AppColors.textMuted),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? accent
                      : AppColors.textPrimaryFor(brightness),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropdownTrigger<T> extends StatelessWidget {
  const _DropdownTrigger({
    required this.hint,
    required this.options,
    required this.labelFor,
    required this.onChanged,
    required this.isSelected,
    this.leadingIcon,
    this.selectedLabel,
    this.selectedIcon,
    this.selectedColor,
    this.iconFor,
    this.colorFor,
  });

  final String hint;
  final String? selectedLabel;
  final IconData? leadingIcon;
  final IconData? selectedIcon;
  final Color? selectedColor;
  final List<T> options;
  final String Function(T) labelFor;
  final IconData Function(T)? iconFor;
  final Color Function(T)? colorFor;
  final ValueChanged<T> onChanged;
  final bool Function(T) isSelected;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final accent = selectedColor ?? AppColors.accent;
    final trigger = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: AppColors.surfaceMutedFor(brightness),
        border: Border.all(color: AppColors.borderFor(brightness)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 8),
          ],
          if (selectedIcon != null) ...[
            Icon(selectedIcon, size: 16, color: accent),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              selectedLabel ?? hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    selectedLabel == null ? AppColors.textMuted : accent,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.arrow_drop_down_rounded,
            size: 18,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );

    // Use the smooth bottom-sheet pattern for overflow dropdowns too.
    return GestureDetector(
      onTap: () => _showSheet(context),
      child: trigger,
    );
  }

  void _showSheet(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.xxl),
                topRight: Radius.circular(AppRadius.xxl),
              ),
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.6,
            ),
            padding: const EdgeInsets.only(
              top: AppSpacing.md,
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: options.map((option) {
                      final selected = isSelected(option);
                      final icon = iconFor?.call(option);
                      final color = colorFor?.call(option) ?? AppColors.textMuted;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(ctx).pop();
                            onChanged(option);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                if (icon != null) ...[
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child:
                                        Icon(icon, size: 16, color: color),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                  child: Text(
                                    labelFor(option),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: selected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: selected
                                              ? AppColors.accent
                                              : AppColors
                                                  .textPrimaryFor(
                                                    brightness,
                                                  ),
                                        ),
                                  ),
                                ),
                                if (selected)
                                  const Icon(
                                    Icons.check_rounded,
                                    color: AppColors.accent,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
