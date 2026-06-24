import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/core/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SecondaryPageShell(
      title: 'Planner',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('Finances', topPadding: 0),
          GlassCard(
            padding: EdgeInsets.zero,
            borderRadius: AppRadius.xl,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Column(
                children: [
                  _PlannerRow(
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: AppColors.accent,
                    title: 'Budget',
                    subtitle: 'Monthly spending limits',
                    onTap: () {
                      AppHaptics.lightImpact();
                      context.pushNamed('budget');
                    },
                  ),
                  _Divider(),
                  _PlannerRow(
                    icon: Icons.trending_up_rounded,
                    iconColor: AppColors.success,
                    title: 'Income',
                    subtitle: 'Track income sources',
                    onTap: () {
                      AppHaptics.lightImpact();
                      context.pushNamed('income');
                    },
                  ),
                  _Divider(),
                  _PlannerRow(
                    icon: Icons.repeat_rounded,
                    iconColor: AppColors.teal,
                    title: 'Recurring',
                    subtitle: 'Subscriptions & regular payments',
                    onTap: () {
                      AppHaptics.lightImpact();
                      context.pushNamed('recurring');
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          const SectionHeader('Goals & Obligations'),
          GlassCard(
            padding: EdgeInsets.zero,
            borderRadius: AppRadius.xl,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Column(
                children: [
                  _PlannerRow(
                    icon: Icons.flag_outlined,
                    iconColor: AppColors.warning,
                    title: 'Goals',
                    subtitle: 'Savings targets & milestones',
                    onTap: () {
                      AppHaptics.lightImpact();
                      context.pushNamed('goals');
                    },
                  ),
                  _Divider(),
                  _PlannerRow(
                    icon: Icons.receipt_long_outlined,
                    iconColor: AppColors.danger,
                    title: 'Bills',
                    subtitle: 'Upcoming & overdue payments',
                    onTap: () {
                      AppHaptics.lightImpact();
                      context.pushNamed('bills');
                    },
                  ),
                  _Divider(),
                  _PlannerRow(
                    icon: Icons.account_balance_outlined,
                    iconColor: AppColors.textSecondary,
                    title: 'Loans',
                    subtitle: 'Debt & Fuliza tracking',
                    onTap: () {
                      AppHaptics.lightImpact();
                      context.pushNamed('loans');
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          const SectionHeader('Productivity'),
          GlassCard(
            padding: EdgeInsets.zero,
            borderRadius: AppRadius.xl,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Column(
                children: [
                  _PlannerRow(
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: AppColors.success,
                    title: 'Tasks',
                    subtitle: 'To-do & action items',
                    onTap: () {
                      AppHaptics.lightImpact();
                      context.pushNamed('tasks');
                    },
                  ),
                  _Divider(),
                  _PlannerRow(
                    icon: Icons.search_rounded,
                    iconColor: AppColors.teal,
                    title: 'Search',
                    subtitle: 'Find any transaction',
                    onTap: () {
                      AppHaptics.lightImpact();
                      context.pushNamed('search');
                    },
                  ),
                  _Divider(),
                  _PlannerRow(
                    icon: Icons.download_outlined,
                    iconColor: AppColors.accent,
                    title: 'Export',
                    subtitle: 'Download your data as CSV or PDF',
                    onTap: () {
                      AppHaptics.lightImpact();
                      context.pushNamed('export');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Divider(
      height: 1,
      thickness: 1,
      indent: 44,
      color: brightness == Brightness.light
          ? AppColors.borderFor(brightness)
          : AppColors.border,
    );
  }
}

class _PlannerRow extends StatelessWidget {
  const _PlannerRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.cardTitle(context)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySm(context).copyWith(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
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
