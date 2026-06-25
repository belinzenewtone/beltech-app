import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_empty_state.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/loading_indicator.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/core/widgets/section_header.dart';
import 'package:beltech/features/review/domain/entities/week_review_ritual.dart';
import 'package:beltech/features/review/presentation/providers/review_providers.dart';
import 'package:beltech/features/review/presentation/providers/review_ritual_providers.dart';
import 'package:beltech/features/tasks/presentation/providers/tasks_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'week_review_screen_stats.dart';

class WeekReviewScreen extends ConsumerStatefulWidget {
  const WeekReviewScreen({super.key});

  @override
  ConsumerState<WeekReviewScreen> createState() => _WeekReviewScreenState();
}

class _WeekReviewScreenState extends ConsumerState<WeekReviewScreen> {
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _updateStreak();
  }

  Future<void> _updateStreak() async {
    const kKey = 'week_review_streak_isoweek';
    const kStreak = 'week_review_streak_count';
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    // ISO week number
    final currentWeek = _isoWeekNumber(now);
    final lastWeek = prefs.getInt(kKey) ?? 0;
    int streak = prefs.getInt(kStreak) ?? 0;

    if (currentWeek == lastWeek) {
      // Already counted this week
    } else if (currentWeek == lastWeek + 1) {
      streak += 1;
    } else {
      streak = 1;
    }
    await prefs.setInt(kKey, currentWeek);
    await prefs.setInt(kStreak, streak);
    if (mounted) setState(() => _streak = streak);
  }

  int _isoWeekNumber(DateTime date) {
    final dayOfYear = int.parse(
      '${date.difference(DateTime(date.year, 1, 1)).inDays + 1}',
    );
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  @override
  Widget build(BuildContext context) {
    final reviewState = ref.watch(weekReviewDataProvider);
    final ritualState = ref.watch(weekReviewRitualProvider);

    return SecondaryPageShell(
      title: 'Week Review',

      child: reviewState.when(
        data: (data) => _ReviewContent(
          review: data,
          ritualState: ritualState,
          streak: _streak,
        ),
        loading: () => const _LoadingReview(),
        error: (_, __) => AppEmptyState(
          icon: Icons.error_outline,
          title: 'Unable to load week review',
          subtitle: 'Please try again',
          action: TextButton(
            onPressed: () => ref.invalidate(weekReviewDataProvider),
            child: const Text('Retry'),
          ),
        ),
      ),
    );
  }
}

class _ReviewContent extends ConsumerWidget {
  const _ReviewContent({
    required this.review,
    required this.ritualState,
    required this.streak,
  });

  final WeekReviewData review;
  final AsyncValue<WeekReviewRitual?> ritualState;
  final int streak;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (streak > 0) ...[
          _StreakBadge(streak: streak),
          const SizedBox(height: AppSpacing.sectionGap),
        ],
        ritualState.when(
          data: (ritual) => ritual == null
              ? const SizedBox.shrink()
              : AppCard(
                  tone: AppCardTone.muted,
                  child: Text(
                    ritual.headline,
                    style: AppTypography.bodyMd(
                      context,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        if (ritualState.valueOrNull != null)
          const SizedBox(height: AppSpacing.sectionGap),
        _StatGrid(
          topLeft: (
            label: 'Tasks Done',
            value: '${review.completedThisWeek}',
            color: AppColors.success,
          ),
          topRight: (
            label: 'Open Tasks',
            value: '${review.pendingCount}',
            color: AppColors.warning,
          ),
          bottomLeft: (
            label: 'Weekly Spend',
            value: CurrencyFormatter.money(review.weeklySpendKes),
            color: AppColors.danger,
          ),
          bottomRight: (
            label: 'Income',
            value: CurrencyFormatter.money(review.weeklyIncomeKes),
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        _WinsRisksSection(review: review),
        const SizedBox(height: AppSpacing.sectionGap),
        const SectionHeader('Next Step'),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            AppButton(
              onPressed: () => context.pushNamed('analytics'),
              icon: Icons.analytics_outlined,
              label: 'Analytics',
              variant: AppButtonVariant.secondary,
            ),
            AppButton(
              onPressed: () => context.pushNamed('budget'),
              icon: Icons.account_balance_wallet_outlined,
              label: 'Budget',
              variant: AppButtonVariant.secondary,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        const SectionHeader('Insights'),
        const SizedBox(height: AppSpacing.sm),
        ...review.insights.map(
          (insight) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.listGap),
            child: _InsightCard(insight: insight),
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        _WeekReviewActions(review: review),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

// ── Wins & Risks ──────────────────────────────────────────────────────────────

class _WinsRisksSection extends StatelessWidget {
  const _WinsRisksSection({required this.review});
  final WeekReviewData review;

  @override
  Widget build(BuildContext context) {
    final wins = _computeWins(review);
    final risks = _computeRisks(review);

    if (wins.isEmpty && risks.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (wins.isNotEmpty)
          Expanded(
            child: AppCard(
              accentColor: AppColors.success,
              tone: AppCardTone.muted,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wins',
                    style: AppTypography.bodySm(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final win in wins)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Text(
                        win,
                        style: AppTypography.bodySm(context),
                        maxLines: 2,
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (wins.isNotEmpty && risks.isNotEmpty)
          const SizedBox(width: AppSpacing.sm),
        if (risks.isNotEmpty)
          Expanded(
            child: AppCard(
              accentColor: AppColors.warning,
              tone: AppCardTone.muted,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Watch Out',
                    style: AppTypography.bodySm(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final risk in risks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Text(
                        risk,
                        style: AppTypography.bodySm(context),
                        maxLines: 2,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  List<String> _computeWins(WeekReviewData r) {
    final wins = <String>[];
    if (r.completedThisWeek > 0) {
      wins.add(
        '${r.completedThisWeek} task${r.completedThisWeek > 1 ? 's' : ''} completed',
      );
    }
    if (r.spendDeltaKes < 0 && r.previousWeeklySpendKes > 0) {
      final pct = ((-r.spendDeltaKes / r.previousWeeklySpendKes) * 100).round();
      wins.add('Spend down $pct% vs last week');
    }
    if (r.incomeDeltaKes > 0 && r.previousWeeklyIncomeKes > 0) {
      final pct = ((r.incomeDeltaKes / r.previousWeeklyIncomeKes) * 100)
          .round();
      wins.add('Income up $pct% vs last week');
    }
    if (r.completionRateThisWeek >= 0.8 && r.tasksDueThisWeek >= 3) {
      wins.add('${(r.completionRateThisWeek * 100).round()}% completion rate');
    }
    return wins.take(3).toList();
  }

  List<String> _computeRisks(WeekReviewData r) {
    final risks = <String>[];
    if (r.spendDeltaKes > 0 && r.previousWeeklySpendKes > 0) {
      final pct = ((r.spendDeltaKes / r.previousWeeklySpendKes) * 100).round();
      if (pct >= 10) risks.add('Spend up $pct% vs last week');
    }
    if (r.pendingCount >= 5) {
      risks.add('${r.pendingCount} tasks still open');
    }
    if (r.weeklyIncomeKes > 0 && r.weeklySpendKes > r.weeklyIncomeKes * 1.1) {
      risks.add('Spending exceeds income this week');
    }
    if (r.completionRateThisWeek < 0.4 && r.tasksDueThisWeek >= 3) {
      risks.add(
        'Low completion rate — ${r.completedThisWeek}/${r.tasksDueThisWeek} due tasks',
      );
    }
    return risks.take(3).toList();
  }
}

// ── Streak badge ─────────────────────────────────────────────────────────────

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.violet.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.violet.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: AppColors.violet,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$streak-week review streak',
            style: AppTypography.bodySm(
              context,
            ).copyWith(fontWeight: FontWeight.w600, color: AppColors.violet),
          ),
        ],
      ),
    );
  }
}

// ── Week Review bottom actions ────────────────────────────────────────────────

class _WeekReviewActions extends ConsumerWidget {
  const _WeekReviewActions({required this.review});
  final WeekReviewData review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final writeState = ref.watch(taskWriteControllerProvider);

    return AppCard(
      tone: AppCardTone.muted,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          AppButton(
            onPressed: writeState.isLoading
                ? null
                : () async {
                    AppHaptics.mediumImpact();
                    final tasksState = ref.read(tasksProvider);
                    final completedIds = (tasksState.valueOrNull ?? [])
                        .where((t) => t.completed)
                        .map((t) => t.id)
                        .toList();
                    if (completedIds.isEmpty) {
                      AppFeedback.info(
                        context,
                        'No completed tasks to archive.',
                      );
                      return;
                    }
                    final count = await ref
                        .read(taskWriteControllerProvider.notifier)
                        .archiveTasks(completedIds);
                    if (context.mounted) {
                      AppFeedback.success(
                        context,
                        'Archived $count completed task(s).',
                      );
                    }
                  },
            icon: Icons.archive_outlined,
            label: 'Archive done',
            variant: AppButtonVariant.secondary,
          ),
          AppButton(
            onPressed: () async {
              AppHaptics.selection();
              final summary = _buildSummaryText(review);
              await Clipboard.setData(ClipboardData(text: summary));
              if (context.mounted) {
                AppFeedback.success(context, 'Summary copied');
              }
            },
            icon: Icons.copy_outlined,
            label: 'Copy summary',
            variant: AppButtonVariant.secondary,
          ),
        ],
      ),
    );
  }

  String _buildSummaryText(WeekReviewData review) {
    final buffer = StringBuffer();
    buffer.writeln('📊 Week Review Summary');
    buffer.writeln(
      'Tasks done: ${review.completedThisWeek} | Open: ${review.pendingCount}',
    );
    buffer.writeln(
      'Weekly spend: KES ${review.weeklySpendKes.toStringAsFixed(0)}',
    );
    buffer.writeln(
      'Weekly income: KES ${review.weeklyIncomeKes.toStringAsFixed(0)}',
    );
    buffer.writeln('Net: KES ${review.netKes.toStringAsFixed(0)}');
    return buffer.toString().trim();
  }
}

// ── Insight card ─────────────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final WeekReviewInsight insight;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (insight.tone) {
      WeekReviewInsightTone.positive => (
        Icons.trending_up_rounded,
        AppColors.success,
      ),
      WeekReviewInsightTone.caution => (
        Icons.warning_amber_rounded,
        AppColors.warning,
      ),
      WeekReviewInsightTone.neutral => (
        Icons.info_outline_rounded,
        AppColors.textSecondary,
      ),
    };

    return AppCard(
      tone: AppCardTone.muted,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: AppTypography.bodySm(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(insight.detail, style: AppTypography.bodySm(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
