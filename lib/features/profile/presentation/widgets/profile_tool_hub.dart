import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/tool_shortcut_grid.dart';
import 'package:flutter/material.dart';

/// Profile-specific tool shortcuts with distinct category colors.
const _profileShortcuts = [
  ToolShortcut(
    label: 'Analytics',
    icon: Icons.query_stats_rounded,
    color: AppColors.warning,
    routeName: 'analytics',
  ),
  ToolShortcut(
    label: 'Hub',
    icon: Icons.hub_outlined,
    color: AppColors.violet,
    routeName: 'finance-hub',
  ),
  ToolShortcut(
    label: 'Goals',
    icon: Icons.flag_outlined,
    color: AppColors.success,
    routeName: 'goals',
  ),
  ToolShortcut(
    label: 'Learning',
    icon: Icons.school_outlined,
    color: AppColors.sky,
    routeName: 'learning',
  ),
  ToolShortcut(
    label: 'Export',
    icon: Icons.download_rounded,
    color: AppColors.categoryBill,
    routeName: 'export',
  ),
  ToolShortcut(
    label: 'Health',
    icon: Icons.monitor_heart_outlined,
    color: AppColors.teal,
    routeName: 'import-health',
  ),
];

class ProfileToolHub extends StatelessWidget {
  const ProfileToolHub({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: AppCardTone.muted,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('TOOL HUB', style: AppTypography.eyebrow(context)),
          const SizedBox(height: 10),
          const ToolShortcutGrid(
            shortcuts: _profileShortcuts,
            childAspectRatio: 1.35,
          ),
        ],
      ),
    );
  }
}
