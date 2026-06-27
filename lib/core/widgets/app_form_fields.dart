import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:flutter/material.dart';

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
    return _FieldCard(
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTypography.bodyMd(context).copyWith(
          color: AppColors.textPrimaryFor(brightness),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          errorText: errorText,
          hintStyle: AppTypography.bodyMd(context).copyWith(
            color: AppColors.textSecondaryFor(brightness).withValues(alpha: 0.55),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        maxLines: null,
        textCapitalization: TextCapitalization.sentences,
      ),
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
    return _FieldCard(
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        minLines: minLines,
        maxLines: maxLines,
        style: AppTypography.bodyMd(context).copyWith(
          color: AppColors.textPrimaryFor(brightness),
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.bodyMd(context).copyWith(
            color: AppColors.textSecondaryFor(brightness).withValues(alpha: 0.55),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: AppCardTone.muted,
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppSpacing.md,
      child: child,
    );
  }
}
