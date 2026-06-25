import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_empty_state.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/features/review/presentation/providers/review_ritual_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HomeWeekReviewRitualCard extends ConsumerWidget {
  const HomeWeekReviewRitualCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ritualState = ref.watch(weekReviewRitualProvider);
    return ritualState.when(
      data: (ritual) {
        if (ritual == null) {
          return const SizedBox.shrink();
        }
        // Compute the Monday of the current week (ISO week starts Monday)
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekLabel =
            'WEEK OF ${DateFormat('MMM d').format(weekStart).toUpperCase()}';

        return AppCard(
          tone: AppCardTone.standard,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: () => context.pushNamed('week-review'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          weekLabel,
                          style: AppTypography.eyebrow(
                            context,
                          ).copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ritual.headline,
                  style: AppTypography.bodySm(
                    context,
                  ).copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const AppEmptyState(
        icon: Icons.date_range_rounded,
        title: 'Weekly ritual unavailable',
        subtitle: 'Pull to refresh and try again.',
      ),
    );
  }
}
