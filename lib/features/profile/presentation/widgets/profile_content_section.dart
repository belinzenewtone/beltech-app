import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/features/profile/domain/entities/user_profile.dart';
import 'package:beltech/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';

class ProfileContentSection extends StatelessWidget {
  const ProfileContentSection({
    super.key,
    required this.profile,
    required this.onEdit,
    required this.onOpenSettings,
    required this.onChangePassword,
    required this.onAvatarCameraTap,
    required this.showSignOut,
    required this.signingOut,
    required this.onSignOut,
    this.workspaceLabel = 'Local Workspace',
  });

  final UserProfile profile;
  final VoidCallback onEdit,
      onOpenSettings,
      onChangePassword,
      onAvatarCameraTap,
      onSignOut;
  final bool showSignOut, signingOut;

  /// Shown below the name in the identity card (e.g. "Local Workspace" or "Cloud Workspace")
  final String workspaceLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Identity card — teal accent, matches RN reference ──────────────────
        GlassCard(
          tone: GlassCardTone.accent,
          accentColor: AppColors.accent,
          child: Column(
            children: [
              // Avatar row
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          workspaceLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Member since ${profile.memberSinceLabel}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Action buttons row
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Edit Profile',
                      onPressed: onEdit,
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.sm,
                    ),
                  ),
                  const SizedBox(width: 12),
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
