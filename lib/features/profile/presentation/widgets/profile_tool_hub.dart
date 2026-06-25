import 'package:beltech/core/navigation/shell_providers.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/tool_shortcut_grid.dart';
import 'package:flutter/material.dart';

/// Profile-specific tool shortcuts rendered in a single accent tone to keep
/// the hub calm and consistent with the rest of the Profile screen.
const _profileShortcuts = [
  ToolShortcut(
    label: 'Analytics',
    icon: Icons.query_stats_rounded,
    color: AppColors.accent,
    routeName: 'analytics',
  ),
  ToolShortcut(
    label: 'Review',
    icon: Icons.history_edu_rounded,
    color: AppColors.accent,
    routeName: 'week-review',
  ),
  ToolShortcut(
    label: 'Bills',
    icon: Icons.receipt_long_rounded,
    color: AppColors.accent,
    routeName: 'bills',
  ),
  ToolShortcut(
    label: 'Loans',
    icon: Icons.account_balance_outlined,
    color: AppColors.accent,
    routeName: 'loans',
  ),
  ToolShortcut(
    label: 'Goals',
    icon: Icons.flag_outlined,
    color: AppColors.accent,
    routeName: 'goals',
  ),
  ToolShortcut(
    label: 'Learning',
    icon: Icons.school_outlined,
    color: AppColors.accent,
    routeName: 'learning',
  ),
  ToolShortcut(
    label: 'Search',
    icon: Icons.search_rounded,
    color: AppColors.accent,
    routeName: 'search',
  ),
  ToolShortcut(
    label: 'Insights',
    icon: Icons.insights_rounded,
    color: AppColors.accent,
    routeName: 'insights',
  ),
  ToolShortcut(
    label: 'Import CSV',
    icon: Icons.upload_file_rounded,
    color: AppColors.accent,
    routeName: 'csv-import',
  ),
  ToolShortcut(
    label: 'Import Health',
    icon: Icons.monitor_heart_outlined,
    color: AppColors.accent,
    routeName: 'import-health',
  ),
  ToolShortcut(
    label: 'Fee Analytics',
    icon: Icons.money_off_csred_rounded,
    color: AppColors.accent,
    routeName: 'fee-analytics',
  ),
  ToolShortcut(
    label: 'Export',
    icon: Icons.download_rounded,
    color: AppColors.accent,
    routeName: 'export',
  ),
  ToolShortcut(
    label: 'Assistant',
    icon: Icons.forum_outlined,
    color: AppColors.accent,
    shellTab: ShellTab.assistant,
  ),
];

class ProfileToolHub extends StatelessWidget {
  const ProfileToolHub({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: AppCardTone.muted,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TOOL HUB', style: AppTypography.eyebrow(context)),
          const SizedBox(height: 12),
          const ToolShortcutGrid(shortcuts: _profileShortcuts),
        ],
      ),
    );
  }
}
