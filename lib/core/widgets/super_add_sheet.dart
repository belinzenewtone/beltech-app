import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_motion.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_form_sheet.dart';
import 'package:beltech/core/widgets/super_add_sheet_models.dart';
import 'package:beltech/core/widgets/super_add_sheet_sections.dart';
import 'package:flutter/material.dart';

export 'package:beltech/core/widgets/super_add_sheet_models.dart';

Future<SuperEntryInput?> showSuperAddSheet(
  BuildContext context, {
  SuperEntryKind defaultKind = SuperEntryKind.task,
  DateTime? contextDate,
  SuperEntryInput? initialInput,
  String actionLabel = 'Create',
  bool lockKind = false,
}) {
  final titleController = TextEditingController(
    text: initialInput?.title ?? '',
  );
  final descriptionController = TextEditingController(
    text: initialInput?.description ?? '',
  );
  var kind = initialInput?.kind ?? defaultKind;
  SuperEntryPriority? priority = initialInput?.priority;
  SuperEntryEventType? eventType = initialInput?.eventType;
  var reminderEnabled = initialInput?.reminderEnabled ?? false;
  int? reminderMinutesBefore = initialInput?.reminderMinutesBefore;
  DateTime? dueAt = initialInput?.dueAt;
  DateTime? startAt = initialInput?.startAt;
  DateTime? endAt = initialInput?.endAt;
  int? birthYear = initialInput?.year;
  var repeatYearly = initialInput?.repeatYearly ?? false;
  var remind3DaysBefore = initialInput?.remind3DaysBefore ?? false;
  var titleError = false;
  String? timeError;
  String? selectionError;
  final pickerContextDate = contextDate;
  var showDetails = true;
  final scrollController = ScrollController();

  String _kindLabel(SuperEntryKind k) {
    return switch (k) {
      SuperEntryKind.task => 'Task',
      SuperEntryKind.event => 'Event',
      SuperEntryKind.birthday => 'Birthday',
      SuperEntryKind.anniversary => 'Anniversary',
      SuperEntryKind.countdown => 'Countdown',
    };
  }

  bool _canSave() {
    final hasTitle = titleController.text.trim().isNotEmpty;
    if (!hasTitle) return false;
    if (kind == SuperEntryKind.task) {
      return priority != null &&
          (!reminderEnabled || reminderMinutesBefore != null);
    }
    if (kind == SuperEntryKind.event) {
      return priority != null &&
          eventType != null &&
          startAt != null &&
          (endAt == null || !endAt!.isBefore(startAt!)) &&
          (!reminderEnabled || reminderMinutesBefore != null);
    }
    if (kind == SuperEntryKind.birthday) {
      return startAt != null;
    }
    if (kind == SuperEntryKind.anniversary) {
      return startAt != null;
    }
    if (kind == SuperEntryKind.countdown) {
      return startAt != null;
    }
    return false;
  }

  return showModalBottomSheet<SuperEntryInput>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final brightness = Theme.of(context).brightness;
        final textPrimary = AppColors.textPrimaryFor(brightness);
        final textSecondary = AppColors.textSecondaryFor(brightness);
        final choiceDuration = AppMotion.content(context);
        final isEventLike = kind == SuperEntryKind.event;
        final isTask = kind == SuperEntryKind.task;
        final isBirthday = kind == SuperEntryKind.birthday;
        final isAnniversary = kind == SuperEntryKind.anniversary;
        final isCountdown = kind == SuperEntryKind.countdown;
        final canSave = _canSave();

        return AppFormSheet(
          controller: scrollController,
          title: actionLabel == 'Create'
              ? 'New ${_kindLabel(kind)}'
              : 'Edit ${_kindLabel(kind)}',
          subtitle: 'Add something to your planner.',
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
                  label: actionLabel,
                  onPressed: !canSave
                      ? null
                      : () {
                          final title = titleController.text.trim();
                          if (title.isEmpty) {
                            setState(() => titleError = true);
                            return;
                          }
                          if (isTask && priority == null) {
                            setState(() {
                              selectionError = 'Choose a priority.';
                            });
                            return;
                          }
                          if (isEventLike &&
                              (priority == null || eventType == null)) {
                            setState(() {
                              selectionError =
                                  'Choose event type and priority.';
                            });
                            return;
                          }
                          if (isEventLike && startAt == null) {
                            setState(() {
                              timeError = 'Select the event start date.';
                            });
                            return;
                          }
                          if (isEventLike &&
                              endAt != null &&
                              startAt != null &&
                              endAt!.isBefore(startAt!)) {
                            setState(() {
                              timeError =
                                  'End time must be after the event start.';
                            });
                            return;
                          }
                          if ((isBirthday || isAnniversary || isCountdown) &&
                              startAt == null) {
                            setState(() {
                              timeError = 'Select the date.';
                            });
                            return;
                          }
                          Navigator.of(context).pop(
                            SuperEntryInput(
                              kind: kind,
                              title: title,
                              description: descriptionController.text
                                          .trim()
                                          .isEmpty
                                      ? null
                                      : descriptionController.text.trim(),
                              priority: priority,
                              dueAt: isTask ? dueAt : null,
                              startAt: isTask ? null : startAt,
                              endAt: isEventLike ? endAt : null,
                              eventType: isEventLike ? eventType : null,
                              year: isBirthday ? birthYear : null,
                              repeatYearly:
                                  isAnniversary || isCountdown
                                      ? repeatYearly
                                      : false,
                              remind3DaysBefore:
                                  isCountdown ? remind3DaysBefore : false,
                              reminderEnabled: reminderEnabled,
                              reminderMinutesBefore:
                                  reminderMinutesBefore ??
                                      (isEventLike ? 15 : 30),
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
              // ── Kind selector ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: SuperEntryKind.values.map((item) {
                    final selected = item == kind;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: lockKind
                            ? null
                            : () => setState(() {
                                  kind = item;
                                  timeError = null;
                                  selectionError = null;
                                }),
                        child: AnimatedContainer(
                          duration: choiceDuration,
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.accent
                                : AppColors.surfaceMutedFor(brightness),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? AppColors.accent
                                  : AppColors.borderFor(brightness),
                            ),
                          ),
                          child: Text(
                            _kindLabel(item),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected ? Colors.white : textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // ── Title ──
              TextField(
                controller: titleController,
                onChanged: (_) => setState(() => titleError = false),
                decoration: InputDecoration(
                  hintText: isBirthday
                      ? 'Name'
                      : isAnniversary
                          ? 'Occasion'
                          : 'Title',
                  errorText: titleError ? 'Title is required' : null,
                ),
              ),
              const SizedBox(height: 12),

              // ── Dynamic content: wrapped in AnimatedSize to prevent jump ──
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                clipBehavior: Clip.none,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
              // ── Date pickers ──
              if (isTask) ...[
                SuperAddWhenPickerRow(
                  label: 'Deadline',
                  value: dueAt,
                  allowClear: true,
                  onPick: (picked) => setState(() {
                    dueAt = picked;
                    timeError = null;
                  }),
                  onClear: () => setState(() => dueAt = null),
                  fallbackDate: pickerContextDate,
                ),
              ] else if (isEventLike) ...[
                SuperAddWhenPickerRow(
                  label: 'Starts',
                  value: startAt,
                  allowClear: false,
                  onPick: (picked) => setState(() {
                    startAt = picked;
                    if (endAt != null &&
                        startAt != null &&
                        endAt!.isBefore(startAt!)) {
                      endAt = startAt!.add(const Duration(hours: 1));
                    }
                    timeError = null;
                  }),
                  onClear: () {},
                  fallbackDate: pickerContextDate,
                ),
                const SizedBox(height: 10),
                SuperAddWhenPickerRow(
                  label: 'Ends (optional)',
                  value: endAt,
                  allowClear: true,
                  onPick: (picked) => setState(() {
                    endAt = picked;
                    timeError = null;
                  }),
                  onClear: () => setState(() => endAt = null),
                  fallbackDate: startAt ?? pickerContextDate,
                ),
              ] else ...[
                SuperAddDateOnlyPickerRow(
                  label: isCountdown ? 'Target date' : 'Date',
                  value: startAt,
                  onPick: (picked) => setState(() {
                    startAt = picked;
                    timeError = null;
                  }),
                  fallbackDate: pickerContextDate,
                ),
              ],

              if (timeError != null) ...[
                const SizedBox(height: 8),
                Text(
                  timeError!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ],
              if (selectionError != null) ...[
                const SizedBox(height: 8),
                Text(
                  selectionError!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),

              // ── Expandable details ──
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => showDetails = !showDetails),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMutedFor(brightness),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          showDetails ? 'Hide details' : 'More details',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Icon(
                        showDetails
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              if (showDetails) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Description (optional)',
                  ),
                ),
                const SizedBox(height: 12),

                // ── Priority (task + event only) ──
                if (isTask || isEventLike) ...[
                  SuperAddPrioritySelector(
                    selected: priority,
                    textPrimary: textPrimary,
                    duration: choiceDuration,
                    onChanged: (value) => setState(() {
                      priority = value;
                      selectionError = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Event type (event only) ──
                if (isEventLike) ...[
                  SuperAddEventTypeSelector(
                    selected: eventType,
                    duration: choiceDuration,
                    onChanged: (value) => setState(() {
                      eventType = value;
                      selectionError = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Birthday year ──
                if (isBirthday) ...[
                  SuperAddYearSelector(
                    selectedYear: birthYear,
                    onChanged: (value) => setState(() => birthYear = value),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Repeat yearly (anniversary + countdown) ──
                if (isAnniversary || isCountdown) ...[
                  SuperAddRepeatToggle(
                    value: repeatYearly,
                    onChanged: (value) => setState(() => repeatYearly = value),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Remind 3 days before (countdown only) ──
                if (isCountdown) ...[
                  SuperAddRemind3DaysToggle(
                    value: remind3DaysBefore,
                    onChanged: (value) =>
                        setState(() => remind3DaysBefore = value),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Reminder ──
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Reminder',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    Switch.adaptive(
                      value: reminderEnabled,
                      onChanged: (value) => setState(() {
                        reminderEnabled = value;
                        if (!value) {
                          selectionError = null;
                        }
                      }),
                    ),
                  ],
                ),
                if (reminderEnabled) ...[
                  const SizedBox(height: 8),
                  SuperAddReminderMinutesSelector(
                    selectedMinutes: reminderMinutesBefore,
                    duration: choiceDuration,
                    onChanged: (value) => setState(() {
                      reminderMinutesBefore = value;
                      selectionError = null;
                    }),
                  ),
                ],
              ],
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
