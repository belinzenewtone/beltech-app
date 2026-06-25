import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:flutter/material.dart';

class AssistantPillButton extends StatelessWidget {
  const AssistantPillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final foreground = onTap != null ? AppColors.accent : AppColors.textMuted;
    final borderColor = onTap != null
        ? AppColors.accent.withValues(alpha: 0.45)
        : AppColors.borderFor(brightness).withValues(alpha: 0.6);

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.full),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceMutedFor(brightness),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: foreground),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AssistantSendButton extends StatelessWidget {
  const AssistantSendButton({
    super.key,
    required this.loading,
    required this.onTap,
  });

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semanticsLabel = loading ? 'Sending message' : 'Send message';
    return Semantics(
      button: true,
      enabled: !loading,
      label: semanticsLabel,
      child: Tooltip(
        message: semanticsLabel,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: loading ? null : onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: loading
                    ? AppColors.accent.withValues(alpha: 0.4)
                    : AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
