import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:flutter/material.dart';

class ProfileSecuritySection extends StatelessWidget {
  const ProfileSecuritySection({
    super.key,
    required this.onChangePassword,
    required this.onSignOut,
    this.showSignOut = true,
    this.signingOut = false,
  });

  final VoidCallback onChangePassword;
  final VoidCallback onSignOut;
  final bool showSignOut;
  final bool signingOut;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: AppCardTone.muted,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _SecurityRow(
            icon: Icons.lock_outline_rounded,
            title: 'Password',
            iconColor: AppColors.accent,
            onTap: onChangePassword,
            position:
                showSignOut ? _SecurityRowPosition.top : _SecurityRowPosition.single,
          ),
          if (showSignOut) ...[
            Divider(
              height: 1,
              color: AppColors.border.withValues(alpha: 0.3),
            ),
            _SecurityRow(
              icon: Icons.logout_rounded,
              title: 'Sign Out',
              iconColor: AppColors.danger,
              textColor: AppColors.danger,
              onTap: signingOut ? null : onSignOut,
              position: _SecurityRowPosition.bottom,
              trailing: signingOut
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.danger,
                      size: 20,
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _SecurityRowPosition { top, bottom, middle, single }

class _SecurityRow extends StatelessWidget {
  const _SecurityRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.textColor,
    this.trailing,
    this.position = _SecurityRowPosition.middle,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? textColor;
  final Widget? trailing;
  final _SecurityRowPosition position;

  @override
  Widget build(BuildContext context) {
    final borderRadius = switch (position) {
      _SecurityRowPosition.top => const BorderRadius.vertical(
        top: Radius.circular(AppRadius.lg),
      ),
      _SecurityRowPosition.bottom => const BorderRadius.vertical(
        bottom: Radius.circular(AppRadius.lg),
      ),
      _SecurityRowPosition.single => BorderRadius.circular(AppRadius.lg),
      _SecurityRowPosition.middle => null,
    };

    return InkWell(
      borderRadius: borderRadius,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTypography.cardTitle(
                  context,
                ).copyWith(color: textColor),
              ),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }
}
