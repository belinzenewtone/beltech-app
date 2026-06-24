import 'dart:io';

import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/ota/patch_ready_info.dart';
import 'package:beltech/core/platform/app_restart_service.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_capsule.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:flutter/material.dart';

class PatchReadyDialog extends StatelessWidget {
  const PatchReadyDialog({
    super.key,
    required this.info,
    required this.onDismiss,
  });

  final PatchReadyInfo info;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final secondaryText =
        AppColors.textSecondaryFor(Theme.of(context).brightness);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: GlassCard(
        tone: GlassCardTone.accent,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        borderRadius: 28,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                const Spacer(),
                AppCapsule(
                  label: info.patchLabel,
                  color: AppColors.accent,
                  icon: Icons.system_update_alt_rounded,
                  variant: AppCapsuleVariant.subtle,
                  size: AppCapsuleSize.md,
                ),
                const Spacer(),
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Dismiss',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.14),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.24),
                ),
              ),
              child: const Icon(
                Icons.system_update_alt_rounded,
                color: AppColors.accent,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              info.title,
              textAlign: TextAlign.center,
              style: AppTypography.sectionTitle(context),
            ),
            const SizedBox(height: 8),
            Text(
              info.message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: secondaryText),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'What\'s New',
                style: textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 10),
            ...info.notes.map(
              (note) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Icon(
                        Icons.circle,
                        size: 7,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        note,
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.cardGap),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Later',
                    onPressed: onDismiss,
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.lg,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Restart Now',
                    icon: Icons.refresh_rounded,
                    onPressed: () => _restart(context),
                    size: AppButtonSize.lg,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _restart(BuildContext context) async {
    AppHaptics.mediumImpact();
    if (Platform.isAndroid) {
      await AppRestartService.restart();
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restart Required'),
        content: const Text(
          'To apply the update, close BELTECH from the app switcher and reopen it.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDismiss();
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
