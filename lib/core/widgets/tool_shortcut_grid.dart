import 'dart:math' as math;

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
    this.showBadge = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String? routeName;
  final ShellTab? shellTab;
  /// When true, a small red dot is shown on the top-right of the icon to
  /// indicate pending actions (e.g. import-health issues after banner dismissal).
  final bool showBadge;
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
  const ToolShortcutGrid({
    super.key,
    this.shortcuts = defaultToolShortcuts,
    this.childAspectRatio,
  });

  final List<ToolShortcut> shortcuts;

  /// Optional override for the tile width-to-height ratio. Higher values make
  /// tiles shorter (more horizontal). Defaults to near-square tiles.
  final double? childAspectRatio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossSpacing = 10.0;
        final crossAxisCount = constraints.maxWidth < 260 ? 2 : 3;
        final aspectRatio = childAspectRatio ??
            (crossAxisCount == 3 ? 1.02 : 1.08);
        // Tile height is content-driven so tiles can never overflow at any
        // width: icon (36) + gap (8) + label line (~19) + vertical padding
        // (16) + border (2), plus a little headroom for text scale.
        const tileContentHeight = 36.0 + 8.0 + 19.0 + 12.0 + 2.0;
        final tileWidth =
            (constraints.maxWidth - (crossAxisCount - 1) * crossSpacing) /
            crossAxisCount;
        final aspectHeight = tileWidth / aspectRatio;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossSpacing,
            mainAxisSpacing: crossSpacing,
            // mainAxisExtent wins over childAspectRatio; keep the ratio for
            // the fallback so default grids stay near-square when roomy.
            mainAxisExtent: math.max(tileContentHeight, aspectHeight),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      color: shortcut.color.withValues(alpha: 0.18),
                    ),
                    child: Icon(shortcut.icon, color: shortcut.color, size: 18),
                  ),
                  if (shortcut.showBadge)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surfaceFor(brightness),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Flexible + FittedBox guarantee the label never overflows the
              // tile at any text scale or tile size — it scales down instead.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    shortcut.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: AppTypography.bodySm(context).copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimaryFor(brightness),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
