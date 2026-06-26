import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_empty_state.dart';
import 'package:beltech/core/widgets/app_skeleton.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/learning/domain/entities/learning_session.dart';
import 'package:beltech/features/learning/presentation/widgets/learning_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _learningProvider = StreamProvider<List<LearningSession>>(
  (ref) => ref.watch(learningRepositoryProvider).watchSessions(),
);

final _learningStreakProvider = FutureProvider<int>(
  (ref) => ref.watch(learningRepositoryProvider).currentStreak(),
);

final _learningMonthlyProvider = FutureProvider<int>(
  (ref) => ref.watch(learningRepositoryProvider).monthlyMinutes(DateTime.now()),
);

class LearningScreen extends ConsumerWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(_learningProvider);
    final streakAsync = ref.watch(_learningStreakProvider);
    final monthlyAsync = ref.watch(_learningMonthlyProvider);
    return SecondaryPageShell(
      title: 'Learning',
      scrollable: false,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Session'),
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AppCard(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          streakAsync.when(
                            data: (v) => '$v-day streak',
                            loading: () => '— streak',
                            error: (_, __) => '0-day streak',
                          ),
                          style: AppTypography.bodyMd(
                            context,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: AppColors.accent),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          monthlyAsync.when(
                            data: (v) => '$v min this month',
                            loading: () => '— min this month',
                            error: (_, __) => '0 min this month',
                          ),
                          style: AppTypography.bodyMd(
                            context,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: sessionsAsync.when(
              data: (sessions) {
                if (sessions.isEmpty) {
                  return const SizedBox(
                    width: double.infinity,
                    child: AppEmptyState(
                      icon: Icons.school_outlined,
                      title: 'No sessions yet',
                      subtitle: 'Add your first learning session',
                    ),
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: sessions.length,
                  itemBuilder: (context, i) {
                    final s = sessions[i];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: i < sessions.length - 1 ? AppSpacing.sm : 0,
                      ),
                      child: AppCard(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.school_outlined,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    s.topic,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodyMd(
                                      context,
                                    ).copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${s.durationMinutes} min · ${_fmtDate(s.date)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodySm(context),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () => ref
                                  .read(learningRepositoryProvider)
                                  .deleteSession(s.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => Column(
                children: List.generate(4, (_) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppSkeleton.card(context),
                )),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  void _showForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LearningFormSheet(),
    );
  }
}
