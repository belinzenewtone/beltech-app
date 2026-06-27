import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/widgets/app_toast.dart';
import 'package:beltech/core/widgets/app_empty_state.dart';
import 'package:beltech/core/widgets/app_fab.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/app_search_bar.dart';
import 'package:beltech/core/widgets/category_chip.dart';
import 'package:beltech/core/widgets/error_message.dart';
import 'package:beltech/core/widgets/loading_indicator.dart';
import 'package:beltech/core/widgets/page_header.dart';
import 'package:beltech/core/widgets/page_shell.dart';
import 'package:beltech/core/widgets/super_add_sheet.dart';
import 'package:beltech/features/calendar/domain/entities/calendar_event.dart';
import 'package:beltech/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:beltech/features/calendar/presentation/widgets/calendar_events_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(filteredEventsProvider);
    final filter = ref.watch(eventFilterProvider);
    final writeState = ref.watch(calendarWriteControllerProvider);

    ref.listen<AsyncValue<void>>(calendarWriteControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError) {
        AppFeedback.error(context, 'Event action failed. Please try again.', ref: ref);
      }
    });

    return PageShell(
      scrollable: false,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                eyebrow: 'Schedule',
                title: 'Events',
                subtitle: 'Upcoming',
              ),
              const SizedBox(height: AppSpacing.md),
              AppSearchBar(
                controller: _searchController,
                hint: 'Search events',
                onChanged: (value) {
                  ref.read(eventSearchQueryProvider.notifier).state = value;
                },
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: EventFilter.values.map((eventFilter) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CategoryChip(
                        label: _filterLabel(eventFilter),
                        selected: filter == eventFilter,
                        onTap: () {
                          ref.read(eventFilterProvider.notifier).state =
                              eventFilter;
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Expanded(
                child: eventsState.when(
                  data: (events) {
                    if (events.isEmpty) {
                      return const SizedBox(
                        width: double.infinity,
                        child: AppEmptyState(
                          icon: Icons.event_outlined,
                          title: 'No events',
                          subtitle: 'Tap the Add button to create one.',
                        ),
                      );
                    }
                    return CalendarEventsCard(
                      events: events,
                      busy: writeState.isLoading,
                      onComplete: (event) async {
                        if (event.completed) return;
                        await ref
                            .read(calendarWriteControllerProvider.notifier)
                            .setEventCompleted(
                              eventId: event.id,
                              completed: true,
                            );
                        if (context.mounted &&
                            !ref
                                .read(calendarWriteControllerProvider)
                                .hasError) {
                          AppFeedback.success(
                            context,
                            'Event completed ✓',
                            ref: ref,
                          );
                        }
                      },
                      onEdit: (event) async {
                        final input = await showSuperAddSheet(
                          context,
                          defaultKind: SuperEntryKind.event,
                          initialInput: _eventToInput(event),
                          actionLabel: 'Save',
                        );
                        if (input == null || !context.mounted) return;
                        await ref
                            .read(calendarWriteControllerProvider.notifier)
                            .updateEvent(
                              eventId: event.id,
                              title: input.title,
                              startAt: input.startAt ?? event.startAt,
                              priority: _inputPriority(input.priority),
                              type: input.eventType != null
                                  ? _eventTypeFromSuper(input.eventType!)
                                  : event.type,
                              kind: event.kind,
                              endAt: input.endAt,
                              note: input.description,
                              reminderOffsets: input.reminderOffsets ?? const [],
                              alarmEnabled: input.alarmEnabled,
                              allDay: event.allDay,
                              repeatRule: event.repeatRule,
                              guests: event.guests,
                              timeZoneId: event.timeZoneId,
                              reminderTimeOfDayMinutes: event.reminderTimeOfDayMinutes,
                            );
                      },
                      onDelete: (event) async {
                        await ref
                            .read(calendarWriteControllerProvider.notifier)
                            .deleteEvent(event.id);
                        if (context.mounted &&
                            !ref
                                .read(calendarWriteControllerProvider)
                                .hasError) {
                          ref.read(toastProvider.notifier).showWithUndo(
                            'Event deleted',
                            onUndo: () async {
                              await ref
                                  .read(calendarWriteControllerProvider.notifier)
                                  .addEvent(
                                    title: event.title,
                                    startAt: event.startAt,
                                    priority: event.priority,
                                    type: event.type,
                                    kind: event.kind,
                                    endAt: event.endAt,
                                    note: event.note,
                                    reminderOffsets: event.reminderOffsets,
                                    alarmEnabled: event.alarmEnabled,
                                    allDay: event.allDay,
                                    repeatRule: event.repeatRule,
                                    guests: event.guests,
                                    timeZoneId: event.timeZoneId,
                                    reminderTimeOfDayMinutes: event.reminderTimeOfDayMinutes,
                                  );
                            },
                          );
                        }
                      },
                    );
                  },
                  loading: () => const Center(child: LoadingIndicator()),
                  error: (_, _) => ErrorMessage(
                    label: 'Unable to load events',
                    onRetry: () => ref.invalidate(allEventsProvider),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 20,
            bottom: AppSpacing.fabBottom(context),
            child: AppFab(
              label: 'Add event',
              busy: writeState.isLoading,
              onPressed: () async {
                AppHaptics.lightImpact();
                await showSuperAddSheet(
                  context,
                  defaultKind: SuperEntryKind.event,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _filterLabel(EventFilter filter) {
    return switch (filter) {
      EventFilter.all => 'All',
      EventFilter.upcoming => 'Upcoming',
      EventFilter.completed => 'Completed',
    };
  }

  SuperEntryInput _eventToInput(CalendarEvent event) {
    return SuperEntryInput(
      kind: SuperEntryKind.event,
      title: event.title,
      description: event.note,
      startAt: event.startAt,
      endAt: event.endAt,
      priority: _eventPriority(event.priority),
      eventType: _superTypeFromEvent(event.type),
      reminderOffsets: event.reminderOffsets,
      alarmEnabled: event.alarmEnabled,
    );
  }

  SuperEntryPriority _eventPriority(CalendarEventPriority priority) {
    return switch (priority) {
      CalendarEventPriority.urgent => SuperEntryPriority.high,
      CalendarEventPriority.neutral => SuperEntryPriority.low,
      CalendarEventPriority.important => SuperEntryPriority.medium,
    };
  }

  CalendarEventPriority _inputPriority(SuperEntryPriority? priority) {
    return switch (priority) {
      SuperEntryPriority.high => CalendarEventPriority.urgent,
      SuperEntryPriority.low => CalendarEventPriority.neutral,
      _ => CalendarEventPriority.important,
    };
  }

  CalendarEventType _eventTypeFromSuper(SuperEntryEventType type) {
    return switch (type) {
      SuperEntryEventType.work => CalendarEventType.work,
      SuperEntryEventType.personal => CalendarEventType.personal,
      SuperEntryEventType.finance => CalendarEventType.finance,
      SuperEntryEventType.health => CalendarEventType.health,
      SuperEntryEventType.general => CalendarEventType.other,
    };
  }

  SuperEntryEventType _superTypeFromEvent(CalendarEventType type) {
    return switch (type) {
      CalendarEventType.work => SuperEntryEventType.work,
      CalendarEventType.personal => SuperEntryEventType.personal,
      CalendarEventType.finance => SuperEntryEventType.finance,
      CalendarEventType.health => SuperEntryEventType.health,
      CalendarEventType.other => SuperEntryEventType.general,
    };
  }
}
