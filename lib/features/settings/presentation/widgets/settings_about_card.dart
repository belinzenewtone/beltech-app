import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_dialog.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/features/settings/presentation/providers/clear_local_data_controller.dart';
import 'package:beltech/features/settings/presentation/widgets/settings_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsAboutCard extends ConsumerStatefulWidget {
  const SettingsAboutCard({super.key});

  @override
  ConsumerState<SettingsAboutCard> createState() => _SettingsAboutCardState();
}

class _SettingsAboutCardState extends ConsumerState<SettingsAboutCard> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = '${info.version} (${info.buildNumber})';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(clearLocalDataControllerProvider, (
      previous,
      next,
    ) {
      if (previous is AsyncLoading && next is AsyncData<void>) {
        AppFeedback.success(context, 'All local data cleared.');
      } else if (next.hasError) {
        AppFeedback.error(context, 'Unable to clear local data.');
      }
    });

    final clearState = ref.watch(clearLocalDataControllerProvider);

    return AppCard(
      tone: AppCardTone.muted,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SettingsRow(
            icon: Icons.new_releases_outlined,
            title: "What's New",
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
            isFirst: true,
            onTap: () => context.pushNamed('changelog'),
          ),
          SettingsRow(
            icon: Icons.info_outline,
            title: 'Version',
            trailing: Text(
              _version.isEmpty ? '…' : _version,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            dividerAbove: true,
          ),
          SettingsRow(
            icon: Icons.cleaning_services_outlined,
            iconColor: AppColors.danger,
            iconBackgroundColor: AppColors.danger.withValues(alpha: 0.16),
            title: 'Clear All Local Data',
            titleColor: AppColors.danger,
            trailing: clearState.isLoading
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
            dividerAbove: true,
            onTap: clearState.isLoading
                ? null
                : () => _confirmClearData(context),
          ),
          SettingsRow(
            icon: Icons.delete_forever_outlined,
            iconColor: AppColors.danger,
            iconBackgroundColor: AppColors.danger.withValues(alpha: 0.16),
            title: 'Delete Account',
            titleColor: AppColors.danger,
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.danger,
              size: 20,
            ),
            dividerAbove: true,
            isLast: true,
            onTap: () => _showDeleteAccountDialog(context),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearData(BuildContext context) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Clear All Local Data?',
      body:
          'This will permanently erase all data stored on this device. '
          'This action cannot be undone.',
      confirmLabel: 'Clear',
    );
    if (confirmed == true && context.mounted) {
      await ref.read(clearLocalDataControllerProvider.notifier).clearAll();
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Account', style: AppTypography.sectionTitle(ctx)),
        content: Text(
          'To delete your account and all associated data, '
          'contact support at support@beltech.app.',
          style: AppTypography.bodyMd(ctx),
        ),
        actions: [
          AppButton(
            label: 'OK',
            size: AppButtonSize.sm,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }
}
