part of 'calendar_screen.dart';

class _CalendarEventsPane extends StatelessWidget {
  const _CalendarEventsPane({
    required this.state,
    required this.eventsState,
    required this.selectedDay,
    required this.writeState,
  });

  final _CalendarScreenState state;
  final AsyncValue<List<CalendarEvent>> eventsState;
  final DateTime selectedDay;
  final AsyncValue<void> writeState;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: state._swiping,
      child: eventsState.when(
        skipLoadingOnReload: true,
        data: (events) {
          final sortedEvents = [...events]
            ..sort((left, right) => left.startAt.compareTo(right.startAt));
          state._consumeSearchTarget(
            context,
            state.ref,
            selectedDay,
            sortedEvents,
          );

          final query = state._searchQuery;
          final visibleEvents = sortedEvents
              .where((event) {
                if (!state._showCompletedEvents && event.completed) {
                  return false;
                }
                if (query.isEmpty) return true;
                final haystack = '${event.title} ${event.note ?? ''}'
                    .toLowerCase();
                return haystack.contains(query);
              })
              .toList(growable: false);

          if (visibleEvents.isEmpty) {
            return Center(
              child: AppEmptyState(
                icon: Icons.event_outlined,
                title: sortedEvents.isEmpty ? 'No events' : 'Nothing found',
                subtitle: sortedEvents.isEmpty
                    ? 'Tap the Add button to create one.'
                    : 'Try a different search or tap Show done.',
                cardWrapped: false,
              ),
            );
          }
          return CalendarEventsCard(
            events: visibleEvents,
            busy: writeState.isLoading,
            onComplete: (event) async {
              if (event.completed) {
                return;
              }
              await state.ref
                  .read(calendarWriteControllerProvider.notifier)
                  .setEventCompleted(eventId: event.id, completed: true);
              if (context.mounted &&
                  !state.ref.read(calendarWriteControllerProvider).hasError) {
                AppFeedback.success(
                  context,
                  'Event completed ✓',
                  ref: state.ref,
                );
              }
            },
            onEdit: (event) async {
              await _editEventWithSuperSheetImpl(
                state,
                context,
                event,
                selectedDay,
              );
            },
            onDelete: (event) async {
              await state.ref
                  .read(calendarWriteControllerProvider.notifier)
                  .deleteEvent(event.id);
              if (context.mounted &&
                  !state.ref.read(calendarWriteControllerProvider).hasError) {
                AppFeedback.success(context, 'Event deleted', ref: state.ref);
              }
            },
          );
        },
        loading: () => Column(
          children: List.generate(3, (_) => AppSkeleton.card(context))
              .expand(
                (element) => [
                  element,
                  const SizedBox(height: AppSpacing.listGap),
                ],
              )
              .toList(),
        ),
        error: (_, __) => ErrorMessage(
          label: 'Unable to load events',
          onRetry: () => state.ref.invalidate(dayEventsProvider),
        ),
      ),
    );
  }
}
