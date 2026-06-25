import 'package:beltech/core/forms/form_schemas.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_form_sheet.dart';
import 'package:beltech/features/tasks/domain/entities/task_item.dart';
import 'package:flutter/material.dart';

class NewTaskInput {
  const NewTaskInput({
    required this.title,
    required this.description,
    required this.priority,
    this.dueDate,
  });

  final String title;
  final String? description;
  final TaskPriority priority;
  final DateTime? dueDate;
}

Future<NewTaskInput?> showAddTaskDialog(BuildContext context) {
  return _showTaskDialog(context);
}

Future<NewTaskInput?> showEditTaskDialog(
  BuildContext context, {
  required TaskItem task,
}) {
  return _showTaskDialog(context, initialTask: task);
}

Future<NewTaskInput?> _showTaskDialog(
  BuildContext context, {
  TaskItem? initialTask,
}) {
  final titleController = TextEditingController(text: initialTask?.title ?? '');
  final descriptionController = TextEditingController(
    text: initialTask?.description ?? '',
  );
  var selectedPriority = initialTask?.priority ?? TaskPriority.medium;
  DateTime? selectedDate = initialTask?.dueDate;

  return showModalBottomSheet<NewTaskInput>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AppFormSheet(
          title: initialTask == null ? 'New Task' : 'Edit Task',
          onClose: () => Navigator.of(context).pop(),
          footer: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Cancel',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: initialTask == null ? 'Create' : 'Update',
                  fullWidth: true,
                  onPressed: () {
                    final result = FormSchemas.taskSchema.validate({
                      'title': titleController.text,
                      'description': descriptionController.text,
                    });
                    if (!result.isValid) {
                      final firstError = result.errors.values.first;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(firstError),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).pop(
                      NewTaskInput(
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                        priority: selectedPriority,
                        dueDate: selectedDate,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: 'Title'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descriptionController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Description (optional)',
                ),
              ),
              const SizedBox(height: 18),
              Text('Priority', style: AppTypography.sectionTitle(context)),
              const SizedBox(height: 10),
              Row(
                children: TaskPriority.values.map((priority) {
                  final selected = selectedPriority == priority;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: priority == TaskPriority.low ? 0 : 8,
                      ),
                      child: AppButton(
                        label: _priorityLabel(priority),
                        size: AppButtonSize.sm,
                        variant: selected
                            ? AppButtonVariant.primary
                            : AppButtonVariant.secondary,
                        fullWidth: true,
                        onPressed: () =>
                            setState(() => selectedPriority = priority),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              AppCard(
                tone: AppCardTone.muted,
                onTap: () async {
                  final picked = await _pickDateTime(context, selectedDate);
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: AppColors.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Deadline',
                            style: AppTypography.bodySm(context),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selectedDate == null
                                ? 'Set deadline'
                                : _formatDueLabel(context, selectedDate!),
                            style: AppTypography.bodyMd(context),
                          ),
                        ],
                      ),
                    ),
                    if (selectedDate != null)
                      IconButton(
                        onPressed: () => setState(() => selectedDate = null),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                        ),
                      )
                    else
                      const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

Future<DateTime?> _pickDateTime(BuildContext context, DateTime? initial) async {
  final now = DateTime.now();
  final pickedDate = await showDatePicker(
    context: context,
    firstDate: DateTime(now.year - 1),
    lastDate: DateTime(now.year + 5),
    initialDate: initial ?? now,
  );
  if (pickedDate == null || !context.mounted) {
    return null;
  }
  final initialTime = initial == null
      ? TimeOfDay.fromDateTime(now.add(const Duration(minutes: 30)))
      : TimeOfDay.fromDateTime(initial);
  final pickedTime = await showTimePicker(
    context: context,
    initialTime: initialTime,
  );
  if (pickedTime == null) {
    return null;
  }
  return DateTime(
    pickedDate.year,
    pickedDate.month,
    pickedDate.day,
    pickedTime.hour,
    pickedTime.minute,
  );
}

String _formatDueLabel(BuildContext context, DateTime dueAt) {
  final localizations = MaterialLocalizations.of(context);
  final date = localizations.formatMediumDate(dueAt);
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(dueAt),
    alwaysUse24HourFormat: true,
  );
  return '$date at $time';
}

String _priorityLabel(TaskPriority priority) {
  return switch (priority) {
    TaskPriority.high => 'Urgent',
    TaskPriority.medium => 'Important',
    TaskPriority.low => 'Neutral',
  };
}
