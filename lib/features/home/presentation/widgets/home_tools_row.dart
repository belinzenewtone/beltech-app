import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeToolsRow extends StatelessWidget {
  const HomeToolsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Tools',
            style: AppTypography.eyebrow(context)
                .copyWith(color: AppColors.textMuted),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              _ToolPill(
                icon: Icons.space_dashboard_outlined,
                label: 'Planner',
                iconColor: AppColors.accent,
                onTap: () {
                  AppHaptics.lightImpact();
                  context.pushNamed('planner');
                },
              ),
              const SizedBox(width: 8),
              _ToolPill(
                icon: Icons.search_rounded,
                label: 'Search',
                iconColor: AppColors.teal,
                onTap: () {
                  AppHaptics.lightImpact();
                  context.pushNamed('search');
                },
              ),
              const SizedBox(width: 8),
              _ToolPill(
                icon: Icons.access_time_rounded,
                label: 'Review',
                iconColor: AppColors.warning,
                onTap: () {
                  AppHaptics.lightImpact();
                  context.pushNamed('week-review');
                },
              ),
              const SizedBox(width: 8),
              _ToolPill(
                icon: Icons.bar_chart_rounded,
                label: 'Analytics',
                iconColor: AppColors.accent,
                onTap: () {
                  AppHaptics.lightImpact();
                  context.pushNamed('analytics');
                },
              ),
              const SizedBox(width: 8),
              _ToolPill(
                icon: Icons.repeat_rounded,
                label: 'Recurring',
                iconColor: AppColors.success,
                onTap: () {
                  AppHaptics.lightImpact();
                  context.pushNamed('recurring');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToolPill extends StatelessWidget {
  const _ToolPill({
    required this.icon,
    required this.label,
    this.iconColor = AppColors.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: brightness == Brightness.light
              ? AppColors.background
              : AppColors.surfaceElevated,
          border: Border.all(
            color: brightness == Brightness.light
                ? AppColors.borderFor(brightness)
                : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.bodySm(context).copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: AppColors.textPrimaryFor(brightness),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
