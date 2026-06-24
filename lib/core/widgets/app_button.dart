import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

enum AppButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.loading = false,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !loading;

    final (height, hPad, fontSize) = switch (size) {
      AppButtonSize.sm => (38.0, 16.0, 13.0),
      AppButtonSize.md => (46.0, 24.0, 15.0),
      AppButtonSize.lg => (54.0, 32.0, 17.0),
    };

    final (bgColor, fgColor, borderColor) = switch (variant) {
      AppButtonVariant.primary => (
          isEnabled ? AppColors.surfaceAccentStrong : AppColors.surfaceAccentStrong.withValues(alpha: 0.5),
          AppColors.textPrimary, // RN uses textOnAccent, which is mapped to textPrimary for now
          AppColors.accentLight.withValues(alpha: 0.25), // 40 hex is ~25%
        ),
      AppButtonVariant.secondary => (
          AppColors.surfaceSoft,
          AppColors.textPrimary,
          AppColors.borderStrong,
        ),
      AppButtonVariant.ghost => (
          AppColors.surfaceSoft,
          AppColors.accent,
          AppColors.accent.withValues(alpha: 0.2), // 35 hex is ~21%
        ),
      AppButtonVariant.danger => (
          isEnabled
              ? AppColors.danger
              : AppColors.danger.withValues(alpha: 0.5),
          AppColors.textPrimary,
          AppColors.danger.withValues(alpha: 0.33), // 55 hex is ~33%
        ),
    };

    final content = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fgColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: fontSize + 2, color: fgColor),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                  height: 1.2,
                ),
              ),
            ],
          );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.full),
      side: borderColor == Colors.transparent
          ? BorderSide.none
          : BorderSide(color: borderColor),
    );

    Widget button = SizedBox(
      height: height,
      width: fullWidth ? double.infinity : null,
      child: variant == AppButtonVariant.secondary ||
              variant == AppButtonVariant.ghost
          ? OutlinedButton(
              onPressed: isEnabled ? onPressed : null,
              style: OutlinedButton.styleFrom(
                backgroundColor: bgColor,
                foregroundColor: fgColor,
                side: BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full)),
                padding: EdgeInsets.symmetric(horizontal: hPad),
              ),
              child: content,
            )
          : FilledButton(
              onPressed: isEnabled ? onPressed : null,
              style: FilledButton.styleFrom(
                backgroundColor: bgColor,
                foregroundColor: fgColor,
                shape: shape,
                padding: EdgeInsets.symmetric(horizontal: hPad),
                disabledBackgroundColor: bgColor.withValues(alpha: 0.5),
                elevation: isEnabled ? 0 : 0,
              ),
              child: content,
            ),
    );

    return button;
  }
}
