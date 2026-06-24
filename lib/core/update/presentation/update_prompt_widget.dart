import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/update/domain/app_update_info.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:flutter/material.dart';

class UpdatePromptWidget extends StatelessWidget {
  const UpdatePromptWidget({
    super.key,
    required this.update,
    required this.currentVersion,
    this.onUpdateNow,
    this.onLater,
  });

  final AppUpdateInfo update;
  final String currentVersion;
  final VoidCallback? onUpdateNow;
  final VoidCallback? onLater;

  bool get _isForceUpdate => update.forceUpdate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final secondaryText = AppColors.textSecondaryFor(Theme.of(context).brightness);

    return GlassCard(
      tone: _isForceUpdate ? GlassCardTone.accent : GlassCardTone.standard,
      padding: const EdgeInsets.all(20),
      borderRadius: AppRadius.xxl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isForceUpdate ? 'Update Required' : 'Update Available',
                      style: AppTypography.sectionTitle(context),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _versionLabel,
                      style: textTheme.bodySmall?.copyWith(color: secondaryText),
                    ),
                  ],
                ),
              ),
              if (!_isForceUpdate)
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onLater?.call();
                  },
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          if (update.notes.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ChangelogSection(notes: update.notes),
          ],
          const SizedBox(height: AppSpacing.cardGap),
          Row(
            children: [
              if (!_isForceUpdate)
                Expanded(
                  child: AppButton(
                    label: 'Later',
                    onPressed: () {
                      Navigator.of(context).pop();
                      onLater?.call();
                    },
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.lg,
                  ),
                ),
              if (!_isForceUpdate) const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Update Now',
                  icon: Icons.download_rounded,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onUpdateNow?.call();
                  },
                  size: AppButtonSize.lg,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _versionLabel => 'v$currentVersion → v${update.latestVersion}';
}

class _ChangelogSection extends StatelessWidget {
  const _ChangelogSection({required this.notes});
  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final displayNotes = notes.length > 8 ? notes.sublist(0, 8) : notes;

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "What's New",
              style: textTheme.titleSmall?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...displayNotes.map(
              (note) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.circle, size: 6, color: AppColors.accent),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(note, style: textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            ),
            if (notes.length > 8)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '... and ${notes.length - 8} more',
                  style: textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> showUpdatePromptSheet({
  required BuildContext context,
  required AppUpdateInfo update,
  required String currentVersion,
  VoidCallback? onUpdateNow,
  VoidCallback? onLater,
}) {
  final isForce = update.forceUpdate;
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: !isForce,
    isDismissible: !isForce,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: UpdatePromptWidget(
          update: update,
          currentVersion: currentVersion,
          onUpdateNow: onUpdateNow,
          onLater: onLater,
        ),
      ),
    ),
  );
}
