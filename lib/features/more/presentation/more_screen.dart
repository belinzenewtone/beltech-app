import 'package:beltech/core/navigation/shell_providers.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/theme/theme_mode_controller.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/page_shell.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_window.dart';
import 'package:beltech/features/expenses/presentation/providers/expenses_providers.dart';
import 'package:beltech/features/profile/presentation/providers/profile_providers.dart';
import 'package:beltech/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:beltech/features/settings/presentation/widgets/settings_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          const _ProfileHeader(),
          const SizedBox(height: AppSpacing.sectionGap),
          const _ThemeSection(),
          const SizedBox(height: AppSpacing.sectionGap),
          _GroupCard(
            title: 'Track',
            children: [
              _MoreRow(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: AppColors.accent,
                title: 'Finance',
                subtitle: 'View and search transactions',
                onTap: () =>
                    ref.read(shellTabIndexProvider.notifier).state = 1,
              ),
              _MoreRow(
                icon: Icons.pie_chart_rounded,
                iconColor: AppColors.accent,
                title: 'Budget',
                subtitle: 'Set limits and track progress',
                onTap: () => context.pushNamed('budget'),
                dividerAbove: true,
              ),
              _MoreRow(
                icon: Icons.attach_money_rounded,
                iconColor: AppColors.success,
                title: 'Income',
                subtitle: 'Log and review income sources',
                onTap: () => context.pushNamed('income'),
                dividerAbove: true,
              ),
              _MoreRow(
                icon: Icons.search_rounded,
                iconColor: AppColors.teal,
                title: 'Search',
                subtitle: 'Find any transaction or entry',
                onTap: () => context.pushNamed('search'),
                dividerAbove: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          _GroupCard(
            title: 'Plan',
            children: [
              _MoreRow(
                icon: Icons.check_circle_outline_rounded,
                iconColor: AppColors.accent,
                title: 'Tasks',
                subtitle: 'Manage your to-do list',
                onTap: () => context.pushNamed('tasks'),
              ),
              _MoreRow(
                icon: Icons.event_rounded,
                iconColor: AppColors.violet,
                title: 'Events',
                subtitle: 'Upcoming events and deadlines',
                onTap: () => context.pushNamed('events'),
                dividerAbove: true,
              ),
              _MoreRow(
                icon: Icons.calendar_month_outlined,
                iconColor: AppColors.info,
                title: 'Calendar',
                subtitle: 'Full month and day views',
                onTap: () => context.pushNamed('calendar-add'),
                dividerAbove: true,
              ),
              _MoreRow(
                icon: Icons.space_dashboard_outlined,
                iconColor: AppColors.violet,
                title: 'Planner',
                subtitle: 'Finance tools and shortcuts',
                onTap: () => context.pushNamed('planner'),
                dividerAbove: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          _GroupCard(
            title: 'Tools',
            children: [
              _MoreRow(
                icon: Icons.query_stats_rounded,
                iconColor: AppColors.warning,
                title: 'Analytics',
                subtitle: 'Spending trends and insights',
                onTap: () => context.pushNamed('analytics'),
              ),
              _MoreRow(
                icon: Icons.repeat_rounded,
                iconColor: AppColors.success,
                title: 'Recurring',
                subtitle: 'Scheduled payments and subscriptions',
                onTap: () => context.pushNamed('recurring'),
                dividerAbove: true,
              ),
              _MoreRow(
                icon: Icons.receipt_long_rounded,
                iconColor: AppColors.warning,
                title: 'Bills',
                subtitle: 'Track bills and due dates',
                onTap: () => context.pushNamed('bills'),
                dividerAbove: true,
              ),
              _MoreRow(
                icon: Icons.account_balance_outlined,
                iconColor: AppColors.danger,
                title: 'Loans',
                subtitle: 'Outstanding loans and Fuliza',
                onTap: () => context.pushNamed('loans'),
                dividerAbove: true,
              ),
              _MoreRow(
                icon: Icons.flag_outlined,
                iconColor: AppColors.success,
                title: 'Goals',
                subtitle: 'Savings targets and milestones',
                onTap: () => context.pushNamed('goals'),
                dividerAbove: true,
              ),
              _MoreRow(
                icon: Icons.school_outlined,
                iconColor: AppColors.sky,
                title: 'Learning',
                subtitle: 'Track study sessions and streaks',
                onTap: () => context.pushNamed('learning'),
                dividerAbove: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          _GroupCard(
            title: 'Data',
            children: [
              _MoreRow(
                icon: Icons.sms_outlined,
                iconColor: AppColors.info,
                title: 'Import SMS',
                subtitle: 'Scan messages for M-Pesa transactions',
                onTap: () => _startSmsImport(ref),
              ),
              _MoreRow(
                icon: Icons.upload_file_rounded,
                iconColor: AppColors.info,
                title: 'Import CSV',
                subtitle: 'Upload expense data from a file',
                onTap: () => context.pushNamed('csv-import'),
                dividerAbove: true,
              ),
              _MoreRow(
                icon: Icons.monitor_heart_outlined,
                iconColor: AppColors.teal,
                title: 'Import Health',
                subtitle: 'Pipeline stats and error logs',
                onTap: () => context.pushNamed('import-health'),
                dividerAbove: true,
              ),
              _MoreRow(
                icon: Icons.download_rounded,
                iconColor: AppColors.categoryBill,
                title: 'Export',
                subtitle: 'Download data or share a report',
                onTap: () => context.pushNamed('export'),
                dividerAbove: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          _GroupCard(
            title: 'Account',
            children: [
              _MoreRow(
                icon: Icons.auto_awesome_outlined,
                iconColor: AppColors.violet,
                title: 'AI Assistant',
                subtitle: 'Ask questions about your finances',
                onTap: () =>
                    ref.read(shellTabIndexProvider.notifier).state = 3,
              ),
              _MoreRow(
                icon: Icons.history_edu_rounded,
                iconColor: AppColors.violet,
                title: 'Weekly Review',
                subtitle: 'Your weekly spending and tasks summary',
                onTap: () => context.pushNamed('week-review'),
                dividerAbove: true,
              ),
              _MoreRow(
                icon: Icons.settings_outlined,
                iconColor: AppColors.textMuted,
                title: 'Settings',
                subtitle: 'Security, notifications, Fuliza',
                onTap: () => context.pushNamed('settings'),
                dividerAbove: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Text(
                'PersonalOs · v1.1.0',
                style: AppTypography.metaText(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startSmsImport(WidgetRef ref) {
    ref.read(expenseWriteControllerProvider.notifier).importFromDevice(
          window: ExpenseImportWindow.lastMonth,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile header card
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final profile = profileAsync.value;
    if (profile == null) return const SizedBox.shrink();

    return AppCard(
      tone: AppCardTone.accent,
      accentColor: AppColors.accent,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: [
          ProfileAvatar(
            name: profile.name,
            avatarUrl: profile.avatarUrl,
            onCameraTap: () {}, // photo change via Settings
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: AppTypography.headlineSm(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Local Workspace',
                  style: AppTypography.bodySm(context),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Text(
                    profile.memberSinceLabel,
                    style: AppTypography.bodySm(context).copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme toggle section
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeSection extends ConsumerWidget {
  const _ThemeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(currentThemeModeProvider);

    return AppCard(
      tone: AppCardTone.muted,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      AppColors.accent.withValues(alpha: 0.16),
                  child: const Icon(
                    Icons.palette_outlined,
                    color: AppColors.accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appearance',
                        style: AppTypography.cardTitle(context),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose your preferred mode',
                        style: AppTypography.bodySm(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SettingsSegmentedPill<ThemeMode>(
              selected: mode,
              onSelected: (value) async => ref
                  .read(themeModeControllerProvider.notifier)
                  .setThemeMode(value),
              options: const [
                SettingsSegmentOption(
                  value: ThemeMode.light,
                  label: 'Light',
                ),
                SettingsSegmentOption(
                  value: ThemeMode.system,
                  label: 'Auto',
                ),
                SettingsSegmentOption(
                  value: ThemeMode.dark,
                  label: 'Dark',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable grouped card wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      tone: AppCardTone.muted,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              title,
              style: AppTypography.eyebrow(context),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single row within a group
// ─────────────────────────────────────────────────────────────────────────────

class _MoreRow extends StatelessWidget {
  const _MoreRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.dividerAbove = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool dividerAbove;

  @override
  Widget build(BuildContext context) {
    Widget row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: iconColor.withValues(alpha: 0.16),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.cardTitle(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTypography.bodySm(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );

    if (dividerAbove) {
      row = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(
            height: 1,
            indent: 56,
            color: AppColors.border.withValues(alpha: 0.35),
          ),
          row,
        ],
      );
    }

    return row;
  }
}
