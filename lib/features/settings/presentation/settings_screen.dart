import 'package:beltech/core/di/feature_flag_providers.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/settings/presentation/widgets/fuliza_settings_card.dart';
import 'package:beltech/features/settings/presentation/widgets/settings_about_card.dart';
import 'package:beltech/features/settings/presentation/widgets/settings_appearance_card.dart';
import 'package:beltech/features/settings/presentation/widgets/settings_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SecondaryPageShell(
      title: 'Settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Appearance
          const SettingsAppearanceCard(),
          const SizedBox(height: AppSpacing.sectionGap),

          // Security & Notifications categories
          AppCard(
            tone: AppCardTone.muted,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SettingsRow(
                  icon: Icons.lock_outline_rounded,
                  title: 'Screen Lock',
                  subtitle: 'Biometric and PIN protection',
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  onTap: () => context.push('/screen-lock'),
                  isFirst: true,
                ),
                SettingsRow(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Reminders, alerts and digest',
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  onTap: () => context.push('/notification-settings'),
                  dividerAbove: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),

          // Background sync
          AppCard(
            tone: AppCardTone.muted,
            padding: EdgeInsets.zero,
            child: ref.watch(backgroundSyncEnabledProvider).when(
              data: (enabled) => SettingsRow(
                icon: Icons.sync_rounded,
                title: 'Background Sync',
                subtitle: 'Capture M-Pesa SMS when the app is closed',
                isFirst: true,
                isLast: true,
                trailing: Switch(
                  value: enabled,
                  onChanged: (v) => ref
                      .read(backgroundSyncEnabledProvider.notifier)
                      .setEnabled(v),
                ),
              ),
              loading: () => const SettingsRow(
                icon: Icons.sync_rounded,
                title: 'Background Sync',
                subtitle: 'Capture M-Pesa SMS when the app is closed',
                isFirst: true,
                isLast: true,
                trailing: SizedBox(width: 51, height: 31),
              ),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),

          // Fuliza M-Pesa
          const FulizaSettingsCard(),
          const SizedBox(height: AppSpacing.sectionGap),

          // About
          const SettingsAboutCard(),
        ],
      ),
    );
  }
}
