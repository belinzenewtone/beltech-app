import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/theme/theme_mode_controller.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/settings/presentation/widgets/settings_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsAppearanceCard extends ConsumerWidget {
  const SettingsAppearanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(currentThemeModeProvider);

    return AppCard(
      tone: AppCardTone.muted,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.16),
                  child: const Icon(
                    Icons.palette_outlined,
                    color: AppColors.accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appearance',
                        style: AppTypography.cardTitle(context),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose your preferred mode',
                        style: AppTypography.bodySm(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SettingsSegmentedPill<ThemeMode>(
              selected: mode,
              onSelected: (value) async => ref
                  .read(themeModeControllerProvider.notifier)
                  .setThemeMode(value),
              options: const [
                SettingsSegmentOption(value: ThemeMode.light, label: 'Light'),
                SettingsSegmentOption(value: ThemeMode.system, label: 'Auto'),
                SettingsSegmentOption(value: ThemeMode.dark, label: 'Dark'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
