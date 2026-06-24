import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:flutter/material.dart';

enum AppIconPillTone { standard, accent, subtle }

class AppIconPillButton extends StatelessWidget {
  const AppIconPillButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.tone = AppIconPillTone.standard,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? label;
  final AppIconPillTone tone;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final enabled = onPressed != null;
    final isIconOnly = label == null || label!.trim().isEmpty;

    final (backgroundColor, borderColor, foregroundColor) = switch (tone) {
      AppIconPillTone.accent => (
          AppColors.accent.withValues(alpha: enabled ? 0.18 : 0.1),
          AppColors.accent.withValues(alpha: enabled ? 0.42 : 0.22),
          AppColors.accent,
        ),
      AppIconPillTone.subtle => (
          AppColors.surfaceMutedFor(brightness).withValues(alpha: 0.88),
          AppColors.borderFor(brightness).withValues(alpha: 0.38),
          AppColors.textSecondaryFor(brightness),
        ),
      AppIconPillTone.standard => (
          AppColors.surfaceFor(brightness).withValues(alpha: 0.18),
          AppColors.borderFor(brightness).withValues(alpha: 0.32),
          AppColors.textPrimaryFor(brightness),
        ),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.fullAll,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          constraints: BoxConstraints(
            minHeight: 40,
            minWidth: isIconOnly ? 40 : 0,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isIconOnly ? 10 : 14,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: AppRadius.fullAll,
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: foregroundColor),
              if (!isIconOnly) ...[
                const SizedBox(width: 7),
                Text(
                  label!,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
