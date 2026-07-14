import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/profile/domain/entities/user_profile.dart';
import 'package:beltech/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';

class ProfileContentSection extends StatelessWidget {
  const ProfileContentSection({
    super.key,
    required this.profile,
    required this.onEdit,
    required this.onOpenSettings,
    required this.onAvatarCameraTap,
    this.workspaceLabel = 'Local Workspace',
  });

  final UserProfile profile;
  final VoidCallback onEdit, onOpenSettings, onAvatarCameraTap;

  /// Shown below the name in the identity card (e.g. "Local Workspace" or "Cloud Workspace")
  final String workspaceLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Identity card ─────────────────────────────────────────────────────
        AppCard(
          tone: AppCardTone.accent,
          accentColor: AppColors.accent,
          child: Column(
            children: [
              Row(
                children: [
                  ProfileAvatar(
                    name: profile.name,
                    avatarUrl: profile.avatarUrl,
                    onCameraTap: onAvatarCameraTap,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: AppTypography.headlineSm(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          workspaceLabel,
                          style: AppTypography.bodySm(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _MemberSincePill(label: profile.memberSinceLabel),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Edit Profile',
                      onPressed: onEdit,
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.sm,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      label: 'Settings',
                      onPressed: onOpenSettings,
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.sm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MemberSincePill extends StatelessWidget {
  const _MemberSincePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        'Member since $label',
        style: AppTypography.metaText(
          context,
        ).copyWith(color: AppColors.accent, fontWeight: FontWeight.w600),
      ),
    );
  }
}
