import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsAboutCard extends StatefulWidget {
  const SettingsAboutCard({super.key});

  @override
  State<SettingsAboutCard> createState() => _SettingsAboutCardState();
}

class _SettingsAboutCardState extends State<SettingsAboutCard> {
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
        _version = '${info.version} (build ${info.buildNumber})';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlassCard(
          tone: GlassCardTone.muted,
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.accent),
              const SizedBox(width: 12),
              Expanded(
                child:
                    Text('Version', style: AppTypography.cardTitle(context)),
              ),
              Text(
                _version.isEmpty ? '…' : _version,
                style: AppTypography.bodySm(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.listGap),
        GlassCard(
          tone: GlassCardTone.muted,
          onTap: () {
            showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Account'),
                content: const Text(
                  'To delete your account and all associated data, '
                  'please contact support at support@beltech.app. '
                  'This action is irreversible.',
                ),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
          child: Row(
            children: [
              const Icon(Icons.delete_forever_outlined, color: AppColors.danger),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delete Account',
                      style: AppTypography.cardTitle(context).copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Permanently remove your account and data',
                      style: AppTypography.bodySm(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
