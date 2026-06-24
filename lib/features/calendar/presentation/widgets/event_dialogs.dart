import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_motion.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_form_sheet.dart';
import 'package:beltech/features/calendar/domain/entities/calendar_event.dart';
import 'package:beltech/features/calendar/presentation/widgets/event_dialog_helpers.dart';
import 'package:beltech/features/calendar/presentation/widgets/event_dialog_selectors.dart';
import 'package:flutter/material.dart';

class NewEventInput {
  const NewEventInput({
    required this.title,
    required this.startAt,
    required this.priority,
    required this.type,
    this.endAt,
    this.note,
  });

  final String title;
  final DateTime startAt;
  final CalendarEventPriority priority;
  final CalendarEventType type;
  final DateTime? endAt;
  final String? note;
}

Future<NewEventInput?> showAddEventDialog(
  BuildContext context, {
  required DateTime selectedDay,
}) {
  return _showEventDialog(context, selectedDay: selectedDay);
}

Future<NewEventInput?> showEditEventDialog(
  BuildContext context, {
  required DateTime selectedDay,
  required CalendarEvent event,
}) {
  return _showEventDialog(
    context,
    selectedDay: selectedDay,
    initialEvent: event,
  );
}

Future<NewEventInput?> _showEventDialog(
  BuildContext context, {
  required DateTime selectedDay,
  CalendarEvent? initialEvent,
}) {
  final titleController =
      TextEditingController(text: initialEvent?.title ?? '');
  final noteController = TextEditingController(text: initialEvent?.note ?? '');
  final defaultStart =
      DateTime(selectedDay.year, selectedDay.month, selectedDay.day, 14, 0);
  var selectedStart = initialEvent?.startAt ?? defaultStart;
  var selectedPriority = initialEvent?.priority ?? CalendarEventPriority.medium;
  var selectedType = initialEvent?.type ?? CalendarEventType.general;
  final eventDuration = initialEvent?.endAt == null
      ? const Duration(hours: 1)
      : initialEvent!.endAt!.difference(initialEvent.startAt).inMinutes <= 0
          ? const Duration(hours: 1)
          : initialEvent.endAt!.difference(initialEvent.startAt);

  return showModalBottomSheet<NewEventInput>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final brightness = Theme.of(context).brightness;
        final textPrimary = AppColors.textPrimaryFor(brightness);
        final choiceDuration = AppMotion.content(context);

        return AppFormSheet(
          title: initialEvent == null ? 'New Event' : 'Edit Event',
          subtitle: initialEvent == null ? 'Add an event to your calendar.' : 'Update this event.',
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
                  label: initialEvent == null ? 'Create' : 'Update',
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) {
                      return;
                    }
                    final note = noteController.text.trim();
                    Navigator.of(context).pop(
                      NewEventInput(
                        title: title,
                        startAt: selectedStart,
                        endAt: selectedStart.add(eventDuration),
                        priority: selectedPriority,
                        type: selectedType,
                        note: note.isEmpty ? null : note,
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
                controller: noteController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Note (optional)'),
              ),
              const SizedBox(height: 14),
              Text('Priority', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 10),
              EventPrioritySelector(
                selected: selectedPriority,
                textPrimary: textPrimary,
                duration: choiceDuration,
                onChanged: (priority) =>
                    setState(() => selectedPriority = priority),
              ),
              const SizedBox(height: 14),
              Text('Event Type', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 10),
              EventTypeSelector(
                selected: selectedType,
                textPrimary: textPrimary,
                duration: choiceDuration,
                onChanged: (type) => setState(() => selectedType = type),
              ),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final picked =
                      await pickEventDateTime(context, selectedStart);
                  if (picked != null) {
                    setState(() => selectedStart = picked);
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
                          formatEventDateTimeLabel(context, selectedStart),
                          style: Theme.of(context).textTheme.bodyLarge,
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
