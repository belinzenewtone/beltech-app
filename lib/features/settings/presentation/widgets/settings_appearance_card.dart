import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/theme/theme_mode_controller.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsAppearanceCard extends ConsumerWidget {
  const SettingsAppearanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(currentThemeModeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          tone: GlassCardTone.muted,
          child: Row(
            children: [
              const Icon(Icons.palette_outlined, color: AppColors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme',
                      style: AppTypography.cardTitle(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose your preferred mode',
                      style: AppTypography.bodySm(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _ThemeModeOption(
              label: 'Dark',
              value: ThemeMode.dark,
              currentMode: mode,
              onTap: () async => ref
                  .read(themeModeControllerProvider.notifier)
                  .setThemeMode(ThemeMode.dark),
            ),
            const SizedBox(width: AppSpacing.listGap),
            _ThemeModeOption(
              label: 'Light',
              value: ThemeMode.light,
              currentMode: mode,
              onTap: () async => ref
                  .read(themeModeControllerProvider.notifier)
                  .setThemeMode(ThemeMode.light),
            ),
            const SizedBox(width: AppSpacing.listGap),
            _ThemeModeOption(
              label: 'System',
              value: ThemeMode.system,
              currentMode: mode,
              onTap: () async => ref
                  .read(themeModeControllerProvider.notifier)
                  .setThemeMode(ThemeMode.system),
            ),
          ],
        ),
      ],
    );
  }
}

class _ThemeModeOption extends StatelessWidget {
  const _ThemeModeOption({
    required this.label,
    required this.value,
    required this.currentMode,
    required this.onTap,
  });

  final String label;
  final ThemeMode value;
  final ThemeMode currentMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == currentMode;
    return Expanded(
      child: GlassCard(
        tone: isSelected ? GlassCardTone.accent : GlassCardTone.muted,
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              style: AppTypography.cardTitle(context).copyWith(
                color: isSelected ? AppColors.accent : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
