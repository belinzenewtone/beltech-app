import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FinanceHubScreen extends StatelessWidget {
  const FinanceHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SecondaryPageShell(
      title: 'Finance Hub',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Finance Tools',
                style: AppTypography.eyebrow(
                  context,
                ).copyWith(color: AppColors.accent),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('Finance Hub', style: AppTypography.pageTitle(context)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Manage budgets, income, recurring items, loans, and exports',
                style: AppTypography.bodyMd(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Hub items
          _HubCard(
            icon: Icons.account_balance_outlined,
            title: 'Budgets',
            subtitle: 'Set spending limits by category and track progress',
            onTap: () {
              AppHaptics.lightImpact();
              context.pushNamed('budget');
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _HubCard(
            icon: Icons.attach_money_rounded,
            title: 'Income',
            subtitle: 'Log and review income sources',
            onTap: () {
              AppHaptics.lightImpact();
              context.pushNamed('income');
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _HubCard(
            icon: Icons.repeat_rounded,
            title: 'Recurring',
            subtitle: 'Subscriptions, salaries, and scheduled payments',
            onTap: () {
              AppHaptics.lightImpact();
              context.pushNamed('recurring');
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _HubCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Loans & Fuliza',
            subtitle: 'Track outstanding Fuliza draws and repayment history',
            onTap: () {
              AppHaptics.lightImpact();
              context.pushNamed('loans');
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _HubCard(
            icon: Icons.receipt_long_outlined,
            title: 'Bills',
            subtitle: 'Track recurring bills and subscriptions with due dates',
            onTap: () {
              AppHaptics.lightImpact();
              context.pushNamed('bills');
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _HubCard(
            icon: Icons.search_rounded,
            title: 'Search Finance',
            subtitle: 'Search transactions, budgets, and recurring entries',
            onTap: () {
              AppHaptics.lightImpact();
              context.pushNamed('search');
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _HubCard(
            icon: Icons.download_rounded,
            title: 'Export',
            subtitle: 'Export your data as CSV or share a report',
            onTap: () {
              AppHaptics.lightImpact();
              context.pushNamed('export');
            },
          ),
          const SizedBox(height: AppSpacing.sectionGap),
        ],
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMd(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySm(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
    );
  }
}
