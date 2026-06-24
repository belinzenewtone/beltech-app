import 'package:beltech/core/forms/form_schemas.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_motion.dart';
import 'package:beltech/core/widgets/app_button.dart';
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
  final descriptionController =
      TextEditingController(text: initialTask?.description ?? '');
  var selectedPriority = initialTask?.priority ?? TaskPriority.medium;
  DateTime? selectedDate = initialTask?.dueDate;

  return showModalBottomSheet<NewTaskInput>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final brightness = Theme.of(context).brightness;
        final textPrimary = AppColors.textPrimaryFor(brightness);
        final textSecondary = AppColors.textSecondaryFor(brightness);
        final choiceDuration = AppMotion.content(context);

        return AppFormSheet(
          title: initialTask == null ? 'New Task' : 'Edit Task',
          subtitle: 'Plan work with clearer priority and deadline controls.',
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
              const SizedBox(height: 14),
              Text('Priority', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 10),
              Row(
                children: TaskPriority.values.map((priority) {
                  final option = _priorityOption(priority);
                  final selected = selectedPriority == priority;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: priority == TaskPriority.low ? 8 : 0,
                        left: priority == TaskPriority.high ? 8 : 0,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () =>
                            setState(() => selectedPriority = priority),
                        child: AnimatedContainer(
                          duration: choiceDuration,
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selected
                                ? option.color.withValues(alpha: 0.9)
                                : option.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? option.color.withValues(alpha: 0.95)
                                  : option.color.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            option.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected
                                  ? textPrimary
                                  : option.color.withValues(alpha: 0.95),
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final picked = await _pickDateTime(context, selectedDate);
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMutedFor(brightness)
                        .withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.borderFor(brightness)
                          .withValues(alpha: 0.65),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, color: AppColors.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          selectedDate == null
                              ? 'Set deadline (date & time)'
                              : _formatDueLabel(context, selectedDate!),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      if (selectedDate != null)
                        IconButton(
                          onPressed: () => setState(() => selectedDate = null),
                          icon: Icon(
                            Icons.close_rounded,
                            color: textSecondary,
                          ),
                        ),
                    ],
                  ),
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

({String label, Color color}) _priorityOption(TaskPriority priority) {
  return switch (priority) {
    TaskPriority.high => (label: 'Urgent', color: AppColors.danger),
    TaskPriority.medium => (label: 'Important', color: AppColors.warning),
    TaskPriority.low => (label: 'Neutral', color: AppColors.accent),
  };
}
