import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/widgets/tool_shortcut_grid.dart';
import 'package:flutter/material.dart';

class SettingsToolsCard extends StatelessWidget {
  const SettingsToolsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const ToolShortcutGrid(
      shortcuts: [
        ToolShortcut(
          label: 'Budget',
          icon: Icons.savings_outlined,
          color: AppColors.warning,
          routeName: 'budget',
        ),
        ToolShortcut(
          label: 'Income',
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.success,
          routeName: 'income',
        ),
        ToolShortcut(
          label: 'Recurring',
          icon: Icons.autorenew,
          color: AppColors.accent,
          routeName: 'recurring',
        ),
        ToolShortcut(
          label: 'Search',
          icon: Icons.search_rounded,
          color: AppColors.sky,
          routeName: 'search',
        ),
        ToolShortcut(
          label: 'Export',
          icon: Icons.file_download_outlined,
          color: AppColors.teal,
          routeName: 'export',
        ),
        ToolShortcut(
          label: 'Analytics',
          icon: Icons.query_stats_rounded,
          color: AppColors.violet,
          routeName: 'analytics',
        ),
      ],
    );
  }
}
