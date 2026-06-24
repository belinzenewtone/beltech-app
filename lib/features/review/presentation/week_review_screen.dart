import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_empty_state.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/glass_card.dart';
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
part 'week_review_screen_trends.dart';

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
        // ── Streak badge ────────────────────────────────────────────────────
        if (streak > 0) ...[
          _StreakBadge(streak: streak),
          const SizedBox(height: AppSpacing.sectionGap),
        ],
        ritualState.when(
          data: (ritual) => ritual == null
              ? const SizedBox.shrink()
              : GlassCard(
                  tone: GlassCardTone.muted,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ritual.headline,
                        style: AppTypography.sectionTitle(context),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ritual.summary,
                        style: AppTypography.bodySm(context),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${ritual.focusLabel}: ${ritual.focusDetail}',
                        style: AppTypography.bodySm(context),
                      ),
                    ],
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
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            AppButton(
              onPressed: () => context.pushNamed('analytics'),
              icon: Icons.analytics_outlined,
              label: 'Open Analytics',
              variant: AppButtonVariant.secondary,
            ),
            AppButton(
              onPressed: () => context.pushNamed('budget'),
              icon: Icons.account_balance_wallet_outlined,
              label: 'Review Budget',
              variant: AppButtonVariant.secondary,
            ),
            AppButton(
              onPressed: () => context.pushNamed('income'),
              icon: Icons.trending_up_rounded,
              label: 'Review Income',
              variant: AppButtonVariant.secondary,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        const SectionHeader('Actionable Insights'),
        const SizedBox(height: 8),
        ...review.insights.map(
          (insight) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.listGap),
            child: _InsightCard(insight: insight),
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        // ── Bottom actions row ───────────────────────────────────────────────
        _WeekReviewActions(review: review),
        const SizedBox(height: 16),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (wins.isNotEmpty)
              Expanded(
                child: GlassCard(
                  accentColor: AppColors.success,
                  tone: GlassCardTone.muted,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            size: 14,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Wins',
                            style: AppTypography.label(context).copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (final win in wins)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
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
            if (wins.isNotEmpty && risks.isNotEmpty) const SizedBox(width: 8),
            if (risks.isNotEmpty)
              Expanded(
                child: GlassCard(
                  accentColor: AppColors.warning,
                  tone: GlassCardTone.muted,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Watch Out',
                            style: AppTypography.label(context).copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (final risk in risks)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          const SizedBox(width: 8),
          Text(
            '$streak-week review streak',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.violet,
            ),
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

    return GlassCard(
      tone: GlassCardTone.muted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Wrap Up', style: AppTypography.cardTitle(context)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Archive done tasks
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
                label: 'Archive done tasks',
                variant: AppButtonVariant.secondary,
              ),
              // Copy summary to clipboard
              AppButton(
                onPressed: () async {
                  AppHaptics.selection();
                  final summary = _buildSummaryText(review);
                  await Clipboard.setData(ClipboardData(text: summary));
                  if (context.mounted) {
                    AppFeedback.success(context, 'Summary copied to clipboard');
                  }
                },
                icon: Icons.copy_outlined,
                label: 'Copy summary',
                variant: AppButtonVariant.secondary,
              ),
            ],
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
