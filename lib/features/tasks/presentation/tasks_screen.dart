import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_fab.dart';
import 'package:beltech/core/widgets/app_empty_state.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/app_toast.dart';
import 'package:beltech/core/widgets/app_search_bar.dart';
import 'package:beltech/core/widgets/app_skeleton.dart';
import 'package:beltech/core/widgets/super_add_sheet.dart';
import 'package:beltech/core/widgets/error_message.dart';
import 'package:beltech/core/widgets/page_header.dart';
import 'package:beltech/core/widgets/page_shell.dart';
import 'package:beltech/features/calendar/domain/entities/calendar_event.dart';
import 'package:beltech/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:beltech/features/search/domain/entities/global_search_result.dart';
import 'package:beltech/features/search/presentation/providers/global_search_providers.dart';
import 'package:beltech/features/tasks/domain/entities/task_item.dart';
import 'package:beltech/features/tasks/presentation/providers/tasks_providers.dart';
import 'package:beltech/features/tasks/presentation/widgets/task_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'tasks_screen_layout.dart';
part 'tasks_screen_actions.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(tasksProvider);
    final allTasks = tasksState.valueOrNull ?? const <TaskItem>[];
    if (tasksState.hasValue) {
      _consumeSearchTarget(context, allTasks);
    }
    final writeState = ref.watch(taskWriteControllerProvider);

    ref.listen<AsyncValue<void>>(taskWriteControllerProvider, (previous, next) {
      if (next.hasError) {
        AppFeedback.error(
          context,
          'Task action failed. Please try again.',
          ref: ref,
        );
      }
    });

    final countSubtitle = _buildCountSubtitle(tasksState);

    return _TasksLayout(
      state: this,
      tasksState: tasksState,
      allTasks: allTasks,
      writeState: writeState,
      countSubtitle: countSubtitle,
    );
  }

  void _refreshSearchResults() {
    setState(() {});
  }

  String _buildCountSubtitle(AsyncValue<List<TaskItem>> tasksState) {
    final tasks = tasksState.valueOrNull;
    if (tasks == null) {
      return 'Loading tasks...';
    }
    final pending = tasks.where((task) => !task.completed).length;
    final completed = tasks.where((task) => task.completed).length;
    return '$pending open • $completed completed';
  }

  void _consumeSearchTarget(BuildContext context, List<TaskItem> allTasks) {
    final pendingTarget = ref.read(globalSearchDeepLinkTargetProvider);
    if (pendingTarget?.kind != GlobalSearchKind.task) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>(() async {
        if (!context.mounted) {
          return;
        }
        final target = ref.read(globalSearchDeepLinkTargetProvider);
        if (target?.kind != GlobalSearchKind.task) {
          return;
        }
        ref.read(globalSearchDeepLinkTargetProvider.notifier).state = null;

        final recordId = target?.recordId;
        if (recordId == null) {
          return;
        }
        final task = allTasks.where((item) => item.id == recordId).firstOrNull;
        if (task == null) {
          AppFeedback.info(context, 'This task no longer exists.', ref: ref);
          return;
        }

        if (!mounted) {
          return;
        }
        await _editTask(context, task);
      });
    });
  }

  Future<void> _editTask(BuildContext context, TaskItem task) async {
    return _editTaskWithSuperSheetImpl(this, context, task);
  }
}
