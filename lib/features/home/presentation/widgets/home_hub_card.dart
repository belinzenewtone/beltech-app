import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/home/domain/entities/home_overview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeHubCard extends ConsumerWidget {
  const HomeHubCard({super.key, required this.overview});
  final HomeOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;

    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: AppRadius.lg,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Column(
          children: [
            _HubRow(
              icon: Icons.check_circle_outline_rounded,
              iconColor: AppColors.accent,
              title: 'Tasks',
              trailingText: overview.pendingCount == 0
                  ? 'All done'
                  : '${overview.pendingCount} pending',
              onTap: () {
                AppHaptics.lightImpact();
                context.pushNamed('tasks');
              },
            ),
            Divider(
              height: 1,
              thickness: 1,
              indent: 64,
              color: brightness == Brightness.light
                  ? AppColors.borderFor(brightness)
                  : AppColors.border,
            ),
            _HubRow(
              icon: Icons.calendar_month_outlined,
              iconColor: AppColors.accent,
              title: 'Next Event',
              trailingText: overview.upcomingEventsCount == 0
                  ? 'No events'
                  : '${overview.upcomingEventsCount} upcoming',
              onTap: () {
                AppHaptics.lightImpact();
                context.pushNamed('events');
              },
            ),
            Divider(
              height: 1,
              thickness: 1,
              indent: 64,
              color: brightness == Brightness.light
                  ? AppColors.borderFor(brightness)
                  : AppColors.border,
            ),
            _HubRow(
              icon: Icons.bar_chart_rounded,
              iconColor: AppColors.accent,
              title: 'Analytics',
              trailingText: '',
              onTap: () {
                AppHaptics.lightImpact();
                context.pushNamed('analytics');
              },
            ),
            Divider(
              height: 1,
              thickness: 1,
              indent: 64,
              color: brightness == Brightness.light
                  ? AppColors.borderFor(brightness)
                  : AppColors.border,
            ),
            _HubRow(
              icon: Icons.search_rounded,
              iconColor: AppColors.accent,
              title: 'Search',
              trailingText: '',
              onTap: () {
                AppHaptics.lightImpact();
                context.pushNamed('search');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HubRow extends StatelessWidget {
  const _HubRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.trailingText,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String trailingText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceMutedFor(
                  Theme.of(context).brightness,
                ),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: AppTypography.cardTitle(context)),
            ),
            if (trailingText.isNotEmpty) ...[
              Text(
                trailingText,
                style: AppTypography.bodySm(context).copyWith(
                  color: AppColors.textSecondaryFor(
                    Theme.of(context).brightness,
                  ),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
