import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Blue pill floating action button matching the Kotlin reference design.
///
/// Default size shows just the [icon]. When [label] is provided, the button
/// expands into a rounded pill with icon + text. Place it inside a [Stack]
/// and position it with [Positioned] using [AppSpacing.fabBottom].
class AppFab extends StatelessWidget {
  const AppFab({
    super.key,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.label,
    this.busy = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String? label;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = !busy && onPressed != null;
    final showLabel = label != null && label!.isNotEmpty;
    return GestureDetector(
      onTap: enabled
          ? () {
              AppHaptics.mediumImpact();
              onPressed!();
            }
          : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.55,
        duration: const Duration(milliseconds: 160),
        child: Container(
          height: 54,
          padding: EdgeInsets.symmetric(horizontal: showLabel ? 20 : 17),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.accentLight.withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.30),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 22),
                    if (showLabel) ...[
                      const SizedBox(width: 8),
                      Text(
                        label!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
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
