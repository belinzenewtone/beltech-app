import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/tool_shortcut_grid.dart';
import 'package:beltech/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _analyticsShortcut = ToolShortcut(
  label: 'Analytics',
  icon: Icons.query_stats_rounded,
  color: AppColors.warning,
  routeName: 'analytics',
);
const _hubShortcut = ToolShortcut(
  label: 'Hub',
  icon: Icons.hub_outlined,
  color: AppColors.violet,
  routeName: 'finance-hub',
);
const _goalsShortcut = ToolShortcut(
  label: 'Goals',
  icon: Icons.flag_outlined,
  color: AppColors.success,
  routeName: 'goals',
);
const _learningShortcut = ToolShortcut(
  label: 'Learning',
  icon: Icons.school_outlined,
  color: AppColors.sky,
  routeName: 'learning',
);
const _exportShortcut = ToolShortcut(
  label: 'Export',
  icon: Icons.download_rounded,
  color: AppColors.categoryBill,
  routeName: 'export',
);

class ProfileToolHub extends ConsumerWidget {
  const ProfileToolHub({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dismissed = ref.watch(importHealthBannerDismissedProvider);
    final metrics = ref.watch(expenseImportMetricsProvider).value;
    // Show red dot on Health if the banner was dismissed but issues remain.
    final healthBadge = dismissed && (metrics?.hasIssues ?? false);

    final shortcuts = [
      _analyticsShortcut,
      _hubShortcut,
      _goalsShortcut,
      _learningShortcut,
      _exportShortcut,
      ToolShortcut(
        label: 'Health',
        icon: Icons.monitor_heart_outlined,
        color: AppColors.teal,
        routeName: 'import-health',
        showBadge: healthBadge,
      ),
    ];

    return AppCard(
      tone: AppCardTone.muted,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text('TOOL HUB', style: AppTypography.eyebrow(context)),
          ),
          const SizedBox(height: 10),
          ToolShortcutGrid(
            shortcuts: shortcuts,
            childAspectRatio: 1.5,
          ),
        ],
      ),
    );
  }
}
