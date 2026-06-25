import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_empty_state.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/app_icon_pill_button.dart';
import 'package:beltech/core/widgets/error_message.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/loading_indicator.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/budget/domain/entities/budget_snapshot.dart';
import 'package:beltech/features/budget/domain/entities/budget_target_progress.dart';
import 'package:beltech/features/budget/presentation/providers/budget_providers.dart';
import 'package:beltech/features/budget/presentation/widgets/budget_dialogs.dart';
import 'package:beltech/features/budget/presentation/widgets/budget_target_progress_card.dart';
import 'package:beltech/features/search/domain/entities/global_search_result.dart';
import 'package:beltech/features/search/presentation/providers/global_search_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'budget_screen_summary.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(budgetMonthProvider);
    final snapshotState = ref.watch(budgetSnapshotProvider);
    final targetProgressState = ref.watch(budgetTargetProgressProvider);
    final writeState = ref.watch(budgetWriteControllerProvider);

    ref.listen<AsyncValue<void>>(budgetWriteControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError) {
        AppFeedback.error(context, 'Unable to save budget changes.');
      }
    });

    return SecondaryPageShell(
      title: 'Budgets',

      scrollable: false,
      actions: [
        AppIconPillButton(
          icon: Icons.chevron_left_rounded,
          tone: AppIconPillTone.subtle,
          onPressed: () {
            final previous = DateTime(month.year, month.month - 1, 1);
            ref.read(budgetMonthProvider.notifier).state = previous;
          },
        ),
        AppIconPillButton(
          icon: Icons.chevron_right_rounded,
          tone: AppIconPillTone.subtle,
          onPressed: () {
            final nextMonth = DateTime(month.year, month.month + 1, 1);
            ref.read(budgetMonthProvider.notifier).state = nextMonth;
          },
        ),
      ],
      child: ListView(
        padding: EdgeInsets.only(
          top: AppSpacing.sm,
          bottom:
              AppSpacing.sectionBottom + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          AppCard(
            tone: AppCardTone.muted,
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.accent,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    '${_monthName(month.month)} ${month.year}',
                    style: AppTypography.sectionTitle(context),
                  ),
                ),
                Text('Monthly view', style: AppTypography.bodySm(context)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          snapshotState.when(
            data: (snapshot) => _BudgetSummaryCard(snapshot: snapshot),
            loading: () => const Center(child: LoadingIndicator()),
            error: (_, __) => ErrorMessage(
              label: 'Unable to load budget snapshot',
              onRetry: () => ref.invalidate(budgetSnapshotProvider),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category Targets',
                style: AppTypography.sectionTitle(context),
              ),
              AppIconPillButton(
                icon: Icons.add_rounded,
                label: 'Add',
                tone: AppIconPillTone.accent,
                onPressed: writeState.isLoading
                    ? null
                    : () async {
                        final input = await showBudgetTargetDialog(context);
                        if (input == null) {
                          return;
                        }
                        await ref
                            .read(budgetWriteControllerProvider.notifier)
                            .saveTarget(
                              category: input.category,
                              monthlyLimitKes: input.monthlyLimitKes,
                            );
                      },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          targetProgressState.when(
            data: (targets) {
              _consumeSearchTarget(context, ref, targets);
              if (targets.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.donut_large_outlined,
                  title: 'No targets yet',
                  subtitle:
                      'Tap "Add" to set a monthly limit for any spending category.',
                );
              }
              return Column(
                children: targets
                    .map(
                      (target) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: BudgetTargetProgressCard(
                          item: target,
                          busy: writeState.isLoading,
                          onEdit: () async {
                            final input = await showBudgetTargetDialog(
                              context,
                              initialCategory: target.category,
                              initialLimit: target.monthlyLimitKes,
                            );
                            if (input == null) {
                              return;
                            }
                            await ref
                                .read(budgetWriteControllerProvider.notifier)
                                .saveTarget(
                                  category: input.category,
                                  monthlyLimitKes: input.monthlyLimitKes,
                                );
                          },
                          onDelete: () async {
                            await ref
                                .read(budgetWriteControllerProvider.notifier)
                                .deleteTarget(target.id);
                          },
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Center(child: LoadingIndicator()),
            error: (_, __) => ErrorMessage(
              label: 'Unable to load budget targets',
              onRetry: () => ref.invalidate(budgetTargetsProvider),
            ),
          ),
        ],
      ),
    );
  }

  void _consumeSearchTarget(
    BuildContext context,
    WidgetRef ref,
    List<BudgetTargetProgress> targets,
  ) {
    final pendingTarget = ref.read(globalSearchDeepLinkTargetProvider);
    if (pendingTarget?.kind != GlobalSearchKind.budget) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>(() async {
        if (!context.mounted) {
          return;
        }
        final target = ref.read(globalSearchDeepLinkTargetProvider);
        if (target?.kind != GlobalSearchKind.budget) {
          return;
        }
        ref.read(globalSearchDeepLinkTargetProvider.notifier).state = null;

        final recordId = target?.recordId;
        if (recordId == null) {
          return;
        }
        final item = targets
            .where((budget) => budget.id == recordId)
            .firstOrNull;
        if (item == null) {
          AppFeedback.info(context, 'This budget target no longer exists.');
          return;
        }

        final input = await showBudgetTargetDialog(
          context,
          initialCategory: item.category,
          initialLimit: item.monthlyLimitKes,
        );
        if (input == null) {
          return;
        }
        await ref
            .read(budgetWriteControllerProvider.notifier)
            .saveTarget(
              category: input.category,
              monthlyLimitKes: input.monthlyLimitKes,
            );
      });
    });
  }

  String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
  }
}
