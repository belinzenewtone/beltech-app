import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/features/tasks/domain/entities/task_item.dart';
import 'package:flutter/material.dart';

Color taskPriorityColor(TaskPriority priority) {
  return switch (priority) {
    TaskPriority.urgent => AppColors.danger,
    TaskPriority.important => AppColors.warning,
    TaskPriority.neutral => AppColors.info,
  };
}

class TaskSwipeBackground extends StatelessWidget {
  const TaskSwipeBackground({
    super.key,
    required this.color,
    required this.icon,
    required this.alignment,
    this.semanticsLabel,
  });

  final Color color;
  final IconData icon;
  final Alignment alignment;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignment,
      child: ExcludeSemantics(child: Icon(icon, color: Colors.white, size: 30)),
    );
    if (semanticsLabel == null) {
      return content;
    }
    return Semantics(label: semanticsLabel, container: true, child: content);
  }
}
