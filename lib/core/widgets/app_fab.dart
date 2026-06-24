import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Teal circular floating action button matching the RN reference design.
///
/// 58×58 circle with [AppColors.accentStrong] fill, a teal glow shadow,
/// and a 1px accent border. Place it inside a [Stack] and position it with
/// [Positioned] using [AppSpacing.fabBottom] for the bottom offset.
class AppFab extends StatelessWidget {
  const AppFab({
    super.key,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.busy = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = !busy && onPressed != null;
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
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentStrong,
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.32),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: busy
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                )
              : Icon(icon, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}
