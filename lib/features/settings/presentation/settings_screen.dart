import 'package:beltech/core/di/notification_providers.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:go_router/go_router.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/loading_indicator.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/auth/domain/entities/auth_state.dart';
import 'package:beltech/features/settings/presentation/widgets/settings_row.dart';
import 'package:beltech/features/auth/presentation/providers/auth_providers.dart';
import 'package:beltech/features/settings/presentation/widgets/fuliza_settings_card.dart';
import 'package:beltech/features/settings/presentation/widgets/notification_preferences_section.dart';
import 'package:beltech/features/settings/presentation/widgets/settings_about_card.dart';
import 'package:beltech/features/settings/presentation/widgets/settings_appearance_card.dart';
import 'package:beltech/features/settings/presentation/widgets/settings_security_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    ref.listen<AsyncValue<AuthState>>(authProvider, (previous, next) {
      if (next.hasError) {
        AppFeedback.error(context, '${next.error}', ref: ref);
      }
    });
    ref.listen<AsyncValue<void>>(notificationPreferenceControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError) {
        AppFeedback.error(context, 'Unable to update notification settings.', ref: ref);
      }
    });

    return SecondaryPageShell(
      title: 'Settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile
          AppCard(
            tone: AppCardTone.muted,
            padding: EdgeInsets.zero,
            child: SettingsRow(
              icon: Icons.person_outline_rounded,
              title: 'Profile',
              subtitle: 'Edit name, username and photo',
              isFirst: true,
              isLast: true,
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
              onTap: () => context.pushNamed('profile'),
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),

          // Appearance
          const SettingsAppearanceCard(),
          const SizedBox(height: AppSpacing.sectionGap),

          // Security
          authState.when(
            data: (state) => SettingsSecurityCard(state: state),
            loading: () => const AppCard(
              tone: AppCardTone.muted,
              child: SizedBox(
                height: 200,
                child: Center(child: LoadingIndicator()),
              ),
            ),
            error: (_, __) => AppCard(
              tone: AppCardTone.muted,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.danger),
                  const SizedBox(height: 8),
                  Text(
                    'Unable to load security settings',
                    style: AppTypography.bodySm(context),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => ref.invalidate(authProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),

          // Fuliza M-Pesa
          const FulizaSettingsCard(),
          const SizedBox(height: AppSpacing.sectionGap),

          // Notifications
          const AppCard(
            tone: AppCardTone.muted,
            padding: EdgeInsets.zero,
            child: NotificationPreferencesSection(),
          ),
          const SizedBox(height: AppSpacing.sectionGap),

          // About
          const SettingsAboutCard(),
        ],
      ),
    );
  }
}
