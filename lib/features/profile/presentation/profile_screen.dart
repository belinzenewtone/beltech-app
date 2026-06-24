import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/theme/glass_styles.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/error_message.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/core/widgets/loading_indicator.dart';
import 'package:beltech/core/widgets/page_header.dart';
import 'package:beltech/core/widgets/page_shell.dart';
import 'package:beltech/features/auth/presentation/providers/account_providers.dart';
import 'package:beltech/features/profile/presentation/providers/profile_providers.dart';
import 'package:beltech/features/profile/presentation/widgets/profile_content_section.dart';
import 'package:beltech/features/profile/presentation/widgets/profile_dialogs.dart';
import 'package:beltech/features/profile/presentation/widgets/profile_tool_hub.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final authWriteState = ref.watch(accountAuthControllerProvider);

    ref.listen<AsyncValue<void>>(profileWriteControllerProvider,
        (previous, next) {
      if (previous is AsyncLoading && next is AsyncData<void>) {
        AppFeedback.success(context, 'Profile updated successfully.', ref: ref);
      } else if (next.hasError) {
        AppFeedback.error(
            context, '${next.error}'.replaceFirst('Exception: ', ''),
            ref: ref);
      }
    });
    ref.listen<AsyncValue<void>>(accountAuthControllerProvider,
        (previous, next) {
      if (next.hasError) {
        final message = '${next.error}'.replaceFirst('Exception: ', '');
        AppFeedback.error(context, message, ref: ref);
      }
    });

    return PageShell(
      scrollable: true,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Profile',
          ),
          profileState.when(
            data: (profile) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileContentSection(
                  profile: profile,
                  workspaceLabel: 'Local Workspace',
                  onEdit: () => showEditProfileDialog(context, ref, profile),
                  onOpenSettings: () => context.pushNamed('settings'),
                  onChangePassword: () => showPasswordDialog(context, ref),
                  onAvatarCameraTap: () async {
                    try {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1024,
                        maxHeight: 1024,
                        imageQuality: 88,
                      );
                      if (picked == null) {
                        return;
                      }
                      final bytes = await picked.readAsBytes();
                      final extension =
                          p.extension(picked.path).replaceFirst('.', '');
                      await ref
                          .read(profileWriteControllerProvider.notifier)
                          .updateAvatar(
                            bytes: bytes,
                            fileExtension:
                                extension.isEmpty ? 'jpeg' : extension,
                          );
                      if (!context.mounted) {
                        return;
                      }
                      final writeState =
                          ref.read(profileWriteControllerProvider);
                      if (!writeState.hasError) {
                        AppFeedback.success(
                            context, 'Profile photo updated successfully.',
                            ref: ref);
                      }
                    } catch (error) {
                      if (!context.mounted) {
                        return;
                      }
                      final message = '$error'.replaceFirst('Exception: ', '');
                      AppFeedback.error(context, message, ref: ref);
                    }
                  },
                  showSignOut: true,
                  signingOut: authWriteState.isLoading,
                  onSignOut: () async {
                    await ref
                        .read(accountAuthControllerProvider.notifier)
                        .signOut();
                  },
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                const ProfileToolHub(),
                const SizedBox(height: AppSpacing.sectionGap),
                // ── Security — password + sign-out (below tool hub) ────────────
                GlassCard(
                  tone: GlassCardTone.muted,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      InkWell(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(GlassStyles.borderRadius),
                        ),
                        onTap: () => showPasswordDialog(context, ref),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.warning.withValues(alpha: 0.18),
                                child: const Icon(Icons.lock_outline_rounded,
                                    color: AppColors.warning, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text('Password',
                                    style: AppTypography.cardTitle(context)),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  color: AppColors.textMuted, size: 20),
                            ],
                          ),
                        ),
                      ),
                      Divider(height: 1, color: AppColors.border.withValues(alpha: 0.3)),
                      InkWell(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(GlassStyles.borderRadius),
                        ),
                        onTap: authWriteState.isLoading
                            ? null
                            : () async {
                                await ref
                                    .read(accountAuthControllerProvider.notifier)
                                    .signOut();
                              },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.danger.withValues(alpha: 0.18),
                                child: const Icon(Icons.logout_rounded,
                                    color: AppColors.danger, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text('Sign Out',
                                    style: AppTypography.cardTitle(context)
                                        .copyWith(color: AppColors.danger)),
                              ),
                              if (authWriteState.isLoading)
                                const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2))
                              else
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppColors.danger, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                Center(
                  child: Text(
                    'PersonalOs · v1.1.0',
                    style: AppTypography.metaText(context),
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
              ],
            ),
            loading: () => const Center(child: LoadingIndicator()),
            error: (_, __) => ErrorMessage(
              label: 'Unable to load profile',
              onRetry: () => ref.invalidate(profileProvider),
            ),
          ),
        ],
      ),
    );
  }
}
