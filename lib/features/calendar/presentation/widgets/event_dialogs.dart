import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_card.dart';
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
  final titleController = TextEditingController(
    text: initialEvent?.title ?? '',
  );
  final noteController = TextEditingController(text: initialEvent?.note ?? '');
  final defaultStart = DateTime(
    selectedDay.year,
    selectedDay.month,
    selectedDay.day,
    14,
    0,
  );
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
        return AppFormSheet(
          title: initialEvent == null ? 'New Event' : 'Edit Event',
          onClose: () => Navigator.of(context).pop(),
          footer: Row(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: initialEvent == null ? 'Create' : 'Update',
                  fullWidth: true,
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
              const SizedBox(height: 18),
              Text('Priority', style: AppTypography.sectionTitle(context)),
              const SizedBox(height: 10),
              EventPrioritySelector(
                selected: selectedPriority,
                onChanged: (priority) =>
                    setState(() => selectedPriority = priority),
              ),
              const SizedBox(height: 18),
              Text('Event Type', style: AppTypography.sectionTitle(context)),
              const SizedBox(height: 10),
              EventTypeSelector(
                selected: selectedType,
                onChanged: (type) => setState(() => selectedType = type),
              ),
              const SizedBox(height: 18),
              AppCard(
                tone: AppCardTone.muted,
                onTap: () async {
                  final picked = await pickEventDateTime(
                    context,
                    selectedStart,
                  );
                  if (picked != null) {
                    setState(() => selectedStart = picked);
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
                          Text('Starts', style: AppTypography.bodySm(context)),
                          const SizedBox(height: 2),
                          Text(
                            formatEventDateTimeLabel(context, selectedStart),
                            style: AppTypography.bodyMd(context),
                          ),
                        ],
                      ),
                    ),
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
