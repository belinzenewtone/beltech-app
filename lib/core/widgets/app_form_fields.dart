import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Shared input decoration for single unified text boxes — a hairline border
/// with an accent focus ring, matching [AppSearchBar] (instead of a borderless
/// field nested inside a separate container). Use this for every plain text /
/// dropdown field so inputs read the same across the app.
InputDecoration appFieldDecoration(
  BuildContext context, {
  required String hint,
  String? errorText,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  final brightness = Theme.of(context).brightness;
  final fillColor = AppColors.surfaceMutedFor(brightness)
      .withValues(alpha: brightness == Brightness.light ? 0.95 : 0.72);
  final borderColor = AppColors.borderFor(brightness).withValues(alpha: 0.5);

  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: hint,
    errorText: errorText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    hintStyle: AppTypography.bodyMd(context).copyWith(
      color: AppColors.textSecondaryFor(brightness).withValues(alpha: 0.55),
    ),
    filled: true,
    fillColor: fillColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: border(borderColor),
    enabledBorder: border(borderColor),
    focusedBorder: border(AppColors.accent.withValues(alpha: 0.7), 1.4),
  );
}

/// Consistent title field used across task/event/countdown/birthday forms.
class AppTitleField extends StatelessWidget {
  const AppTitleField({
    super.key,
    required this.controller,
    this.hint = 'Title',
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // The title being composed should read as a heading, not body text.
    final titleStyle = AppTypography.sectionTitle(context).copyWith(
      fontSize: 18,
      height: 24 / 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryFor(brightness),
    );
    final decoration = appFieldDecoration(context, hint: hint, errorText: errorText);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: titleStyle,
      decoration: decoration.copyWith(
        hintStyle: titleStyle.copyWith(
          color: AppColors.textSecondaryFor(brightness).withValues(alpha: 0.55),
        ),
      ),
      maxLines: null,
      textCapitalization: TextCapitalization.sentences,
    );
  }
}

/// Consistent multi-line note/description field used across forms.
class AppNoteField extends StatelessWidget {
  const AppNoteField({
    super.key,
    required this.controller,
    this.hint = 'Description (optional)',
    this.minLines = 2,
    this.maxLines = 4,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final int minLines;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      minLines: minLines,
      maxLines: maxLines,
      style: AppTypography.bodyMd(context).copyWith(
        color: AppColors.textPrimaryFor(brightness),
        fontWeight: FontWeight.w400,
      ),
      decoration: appFieldDecoration(context, hint: hint),
      textCapitalization: TextCapitalization.sentences,
    );
  }
}
