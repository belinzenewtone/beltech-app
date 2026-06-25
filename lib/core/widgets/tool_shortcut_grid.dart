import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/navigation/shell_providers.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ToolShortcut {
  const ToolShortcut({
    required this.label,
    required this.icon,
    required this.color,
    this.routeName,
    this.shellTab,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String? routeName;
  final ShellTab? shellTab;
}

const defaultToolShortcuts = [
  ToolShortcut(
    label: 'Analytics',
    icon: Icons.query_stats_rounded,
    color: AppColors.accent,
    routeName: 'analytics',
  ),
  ToolShortcut(
    label: 'Review',
    icon: Icons.history_edu_rounded,
    color: AppColors.violet,
    routeName: 'week-review',
  ),
  ToolShortcut(
    label: 'Bills',
    icon: Icons.receipt_long_rounded,
    color: AppColors.warning,
    routeName: 'bills',
  ),
  ToolShortcut(
    label: 'Loans',
    icon: Icons.account_balance_outlined,
    color: AppColors.danger,
    routeName: 'loans',
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
    label: 'Search',
    icon: Icons.search_rounded,
    color: AppColors.teal,
    routeName: 'search',
  ),
  ToolShortcut(
    label: 'Insights',
    icon: Icons.insights_rounded,
    color: AppColors.violet,
    routeName: 'insights',
  ),
  ToolShortcut(
    label: 'Import CSV',
    icon: Icons.upload_file_rounded,
    color: AppColors.info,
    routeName: 'csv-import',
  ),
  ToolShortcut(
    label: 'Import Health',
    icon: Icons.monitor_heart_outlined,
    color: AppColors.success,
    routeName: 'import-health',
  ),
  ToolShortcut(
    label: 'Fee Analytics',
    icon: Icons.money_off_csred_rounded,
    color: AppColors.danger,
    routeName: 'fee-analytics',
  ),
  ToolShortcut(
    label: 'Export',
    icon: Icons.download_rounded,
    color: AppColors.warning,
    routeName: 'export',
  ),
  ToolShortcut(
    label: 'Assistant',
    icon: Icons.forum_outlined,
    color: AppColors.accent,
    shellTab: ShellTab.assistant,
  ),
];

class ToolShortcutGrid extends ConsumerWidget {
  const ToolShortcutGrid({super.key, this.shortcuts = defaultToolShortcuts});

  final List<ToolShortcut> shortcuts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 260 ? 2 : 3;
        final aspectRatio = crossAxisCount == 3 ? 1.02 : 1.08;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: aspectRatio,
          ),
          itemCount: shortcuts.length,
          itemBuilder: (context, index) {
            final shortcut = shortcuts[index];
            return _ToolShortcutTile(
              shortcut: shortcut,
              onTap: () {
                AppHaptics.lightImpact();
                if (shortcut.shellTab != null) {
                  ref.read(shellTabIndexProvider.notifier).state =
                      shortcut.shellTab!.index;
                  return;
                }
                context.pushNamed(shortcut.routeName!);
              },
            );
          },
        );
      },
    );
  }
}

class _ToolShortcutTile extends StatelessWidget {
  const _ToolShortcutTile({required this.shortcut, required this.onTap});

  final ToolShortcut shortcut;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderFor(brightness)),
            color: AppColors.surfaceMutedFor(
              brightness,
            ).withValues(alpha: 0.58),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: shortcut.color.withValues(alpha: 0.18),
                ),
                child: Icon(shortcut.icon, color: shortcut.color, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                shortcut.label,
                textAlign: TextAlign.center,
                style: AppTypography.bodySm(context).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimaryFor(brightness),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
