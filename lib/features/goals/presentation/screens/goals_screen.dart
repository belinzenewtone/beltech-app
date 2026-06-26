import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/widgets/app_empty_state.dart';
import 'package:beltech/core/widgets/app_skeleton.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/goals/domain/entities/goal_item.dart';
import 'package:beltech/features/goals/presentation/widgets/goal_form_sheet.dart';
import 'package:beltech/features/goals/presentation/widgets/goal_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _goalsProvider = StreamProvider<List<GoalItem>>(
  (ref) => ref.watch(goalsRepositoryProvider).watchGoals(),
);

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(_goalsProvider);
    return SecondaryPageShell(
      title: 'Goals',
      scrollable: false,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Goal'),
      ),
      child: Column(
        children: [
          Expanded(child: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return const Center(
              child: AppEmptyState(
                icon: Icons.flag_outlined,
                title: 'No goals yet',
                subtitle: 'Add your first goal',
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (context, i) => GoalItemCard(
              goal: goals[i],
              onTap: () => _showForm(context, ref, goals[i]),
            ),
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
            textAlign: TextAlign.center,
          ),
        ),
      )),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref, [GoalItem? goal]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GoalFormSheet(goal: goal),
    );
  }
}
