import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Smooth, consistent dropdown picker used everywhere in the app.
///
/// Renders a tappable row that looks like a form field and opens a
/// `showModalBottomSheet` with a pull-handle, rounded top corners,
/// accent-checkmarked selected item, and tap-to-select — the same smooth
/// pattern as the Export screen's date-window dropdown.
///
/// Usage:
/// ```dart
/// AppDropdownPicker<String>(
///   hint: 'Select category',
///   value: currentValue,
///   items: categories,
///   labelFor: (c) => c,
///   iconFor: (c) => categoryVisual(c).icon,
///   colorFor: (c) => categoryVisual(c).foreground,
///   onChanged: (v) => setState(...),
/// )
/// ```
class AppDropdownPicker<T> extends StatelessWidget {
  const AppDropdownPicker({
    super.key,
    required this.items,
    required this.labelFor,
    required this.onChanged,
    this.value,
    this.hint,
    this.leadingIcon,
    this.iconFor,
    this.colorFor,
    this.selectedTest,
    this.enabled = true,
  });

  final List<T> items;

  /// Can be `null` when nothing is selected.
  final T? value;

  /// Placeholder when no item is selected.
  final String? hint;

  /// How to render an item as text.
  final String Function(T item) labelFor;

  final ValueChanged<T> onChanged;

  /// Optional leading icon shown on the trigger.
  final IconData? leadingIcon;

  /// Optional per-item leading icon in the menu.
  final IconData Function(T item)? iconFor;

  /// Optional per-item accent colour in the menu.
  final Color Function(T item)? colorFor;

  /// Optional custom equality. Defaults to `==`.
  final bool Function(T item)? selectedTest;

  /// When false the picker is disabled (greyed out, non-tappable).
  final bool enabled;

  bool _isSelected(T item) =>
      selectedTest?.call(item) ?? item == value;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final selectedItem = items.where(_isSelected).firstOrNull;
    final selectedLabel = selectedItem == null
        ? null
        : labelFor(selectedItem);
    final selectedIcon = selectedItem == null ? null : iconFor?.call(selectedItem);
    final selectedColor = selectedItem == null ? null : colorFor?.call(selectedItem);
    final accent = selectedColor ?? AppColors.accent;

    return GestureDetector(
      onTap: enabled ? () => _showPicker(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceMutedFor(brightness),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: enabled && selectedLabel != null
                ? accent.withValues(alpha: 0.35)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 18, color: AppColors.textMuted),
              const SizedBox(width: 8),
            ],
            if (selectedIcon != null && selectedLabel != null) ...[
              Icon(selectedIcon, size: 16, color: accent),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                selectedLabel ?? hint ?? 'Select…',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: selectedLabel != null
                          ? AppColors.textPrimaryFor(brightness)
                          : AppColors.textMuted,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
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
                    children: items.map((item) {
                      final selected = _isSelected(item);
                      final icon = iconFor?.call(item);
                      final color = colorFor?.call(item) ?? AppColors.textMuted;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(ctx).pop();
                            onChanged(item);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
                                    labelFor(item),
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

/// Convenience wrapper for the common "menu button" use cases — bills,
/// income row, category manager.
///
/// Opens a small popup (not a full bottom sheet) via `showMenu`.
/// For full bottom-sheet pickers, use [AppDropdownPicker] directly.
class AppPopupMenu<T> extends StatelessWidget {
  const AppPopupMenu({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.itemBuilder,
  });

  /// The trigger icon.
  final Widget icon;

  final String tooltip;

  /// Builds the menu items.
  final List<PopupMenuEntry<T>> Function(BuildContext context) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      icon: icon,
      tooltip: tooltip,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      color: AppColors.surfaceElevated,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      itemBuilder: itemBuilder,
    );
  }
}
