part of 'calendar_screen.dart';

class _CalendarLayout extends StatelessWidget {
  const _CalendarLayout({
    required this.state,
    required this.textTheme,
    required this.visibleMonth,
    required this.selectedDay,
    required this.eventsState,
    required this.tasksState,
    required this.monthEventTypesState,
    required this.writeState,
    required this.title,
    required this.weekStart,
    required this.weekEventsState,
  });

  final _CalendarScreenState state;
  final TextTheme textTheme;
  final DateTime visibleMonth;
  final DateTime selectedDay;
  final AsyncValue<List<CalendarEvent>> eventsState;
  final AsyncValue<List<TaskItem>> tasksState;
  final AsyncValue<Map<int, CalendarEventType>> monthEventTypesState;
  final AsyncValue<void> writeState;
  final String title;
  final DateTime weekStart;
  final AsyncValue<List<CalendarEvent>> weekEventsState;

  @override
  Widget build(BuildContext context) {
    final viewMode = state.ref.watch(calendarViewModeProvider);

    final monthTaskDays = (tasksState.valueOrNull ?? const <TaskItem>[])
        .where((task) {
          final dueDate = task.dueDate;
          return dueDate != null &&
              dueDate.year == visibleMonth.year &&
              dueDate.month == visibleMonth.month;
        })
        .map((task) => task.dueDate!.day)
        .toSet();

    final dayEvents = eventsState.valueOrNull ?? const <CalendarEvent>[];
    final completedEvents = dayEvents.where((event) => event.completed).length;
    final pendingEvents = dayEvents.length - completedEvents;

    final dayTasks = (tasksState.valueOrNull ?? const <TaskItem>[])
        .where(
          (task) =>
              task.dueDate != null && _isSameDate(task.dueDate!, selectedDay),
        )
        .toList(growable: false);
    final completedTasks = dayTasks.where((task) => task.completed).length;
    final pendingTasks = dayTasks.length - completedTasks;

    return Stack(
      children: [
        PageShell(
          scrollable: viewMode != CalendarViewMode.day,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Calendar',
                action: AppIconPillButton(
                  icon: Icons.today_rounded,
                  label: 'Today',
                  tone: AppIconPillTone.subtle,
                  onPressed: () {
                    final today = DateTime.now();
                    final todayNorm = DateTime(
                      today.year,
                      today.month,
                      today.day,
                    );
                    state.ref.read(selectedDayProvider.notifier).state =
                        todayNorm;
                    if (viewMode == CalendarViewMode.week) {
                      final monday = todayNorm.subtract(
                        Duration(days: todayNorm.weekday - 1),
                      );
                      state.ref.read(visibleWeekStartProvider.notifier).state =
                          monday;
                    }
                    state.ref.read(visibleMonthProvider.notifier).state =
                        DateTime(today.year, today.month, 1);
                  },
                ),
              ),
              if (viewMode == CalendarViewMode.month) ...[
                const SizedBox(height: 8),
                Center(
                  child: SegmentedButton<_CalendarView>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  segments: const [
                    ButtonSegment(
                      value: _CalendarView.month,
                      icon: Icon(Icons.calendar_month_outlined, size: 18),
                      label: Text('Month'),
                    ),
                    ButtonSegment(
                      value: _CalendarView.events,
                      icon: Icon(Icons.event_outlined, size: 18),
                      label: Text('Events'),
                    ),
                    ButtonSegment(
                      value: _CalendarView.tasks,
                      icon: Icon(Icons.task_alt_outlined, size: 18),
                      label: Text('Tasks'),
                    ),
                  ],
                    selected: {state._view},
                    onSelectionChanged: (v) => state._setView(v.first),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (viewMode == CalendarViewMode.month)
                _MonthBody(
                  state: state,
                  textTheme: textTheme,
                  title: title,
                  visibleMonth: visibleMonth,
                  selectedDay: selectedDay,
                  monthEventTypesState: monthEventTypesState,
                  monthTaskDays: monthTaskDays,
                  eventsState: eventsState,
                  tasksState: tasksState,
                  writeState: writeState,
                  pendingEvents: pendingEvents,
                  completedEvents: completedEvents,
                  pendingTasks: pendingTasks,
                  completedTasks: completedTasks,
                )
              else if (viewMode == CalendarViewMode.week)
                _WeekBody(
                  state: state,
                  textTheme: textTheme,
                  title: title,
                  weekStart: weekStart,
                  selectedDay: selectedDay,
                  weekEventsState: weekEventsState,
                )
              else
                _DayBody(
                  state: state,
                  textTheme: textTheme,
                  title: title,
                  selectedDay: selectedDay,
                  eventsState: eventsState,
                ),
            ],
          ),
        ),
        Positioned(
          right: 20,
          bottom: AppSpacing.fabBottom(context),
          child: FloatingActionButton.extended(
            onPressed: writeState.isLoading
                ? null
                : () => _handleSuperAddFromCalendarImpl(
                      state,
                      context,
                      selectedDay,
                    ),
            icon: const Icon(Icons.add),
            label: const Text('Add'),
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _MonthBody extends StatelessWidget {
  const _MonthBody({
    required this.state,
    required this.textTheme,
    required this.title,
    required this.visibleMonth,
    required this.selectedDay,
    required this.monthEventTypesState,
    required this.monthTaskDays,
    required this.eventsState,
    required this.tasksState,
    required this.writeState,
    required this.pendingEvents,
    required this.completedEvents,
    required this.pendingTasks,
    required this.completedTasks,
  });

  final _CalendarScreenState state;
  final TextTheme textTheme;
  final String title;
  final DateTime visibleMonth;
  final DateTime selectedDay;
  final AsyncValue<Map<int, CalendarEventType>> monthEventTypesState;
  final Set<int> monthTaskDays;
  final AsyncValue<List<CalendarEvent>> eventsState;
  final AsyncValue<List<TaskItem>> tasksState;
  final AsyncValue<void> writeState;
  final int pendingEvents;
  final int completedEvents;
  final int pendingTasks;
  final int completedTasks;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) => state._beginSwipe(),
          onHorizontalDragEnd: state._handleSwipeEnd,
          onHorizontalDragCancel: state._cancelSwipe,
          child: GlassCard(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => state._changeMonth(state.ref, -1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => state._changeMonth(state.ref, 1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth:
                          _CalendarScreenState._calendarContentMaxWidth,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _CalendarScreenState._weekDays
                          .map(
                            (day) => SizedBox(
                              width: 30,
                              child: Text(
                                day,
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                CalendarMonthGrid(
                  visibleMonth: visibleMonth,
                  selectedDay: selectedDay,
                  eventTypes:
                      monthEventTypesState.valueOrNull ?? const {},
                  taskDays: monthTaskDays,
                  maxWidth: _CalendarScreenState._calendarContentMaxWidth,
                  onSelect: (day) {
                    state.ref.read(selectedDayProvider.notifier).state = day;
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (state._view == _CalendarView.events)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CalendarSectionHeader(
                  title: 'Events',
                  dateLabel:
                      '${_calendarWeekdayName(selectedDay.weekday)}, ${_CalendarScreenState._months[selectedDay.month - 1]} ${selectedDay.day.toString().padLeft(2, '0')}',
                  pendingCount: pendingEvents,
                  completedCount: completedEvents,
                  showCompleted: state._showCompletedEvents,
                  onToggleCompleted:
                      state._toggleCompletedEventsVisibility,
                ),
                const SizedBox(height: 8),
                _CalendarEventsPane(
                  state: state,
                  eventsState: eventsState,
                  selectedDay: selectedDay,
                  writeState: writeState,
                ),
              ],
            ),
          )
        else if (state._view == _CalendarView.tasks)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CalendarSectionHeader(
                  title: 'Tasks',
                  dateLabel:
                      '${_calendarWeekdayName(selectedDay.weekday)}, ${_CalendarScreenState._months[selectedDay.month - 1]} ${selectedDay.day.toString().padLeft(2, '0')}',
                  pendingCount: pendingTasks,
                  completedCount: completedTasks,
                  showCompleted: state._showCompletedTasks,
                  onToggleCompleted:
                      state._toggleCompletedTasksVisibility,
                ),
                const SizedBox(height: 8),
                _CalendarTasksPane(
                  state: state,
                  selectedDay: selectedDay,
                  tasksState: tasksState,
                ),
              ],
            ),
          )
        else
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CalendarSectionHeader(
                  title: 'Events',
                  dateLabel:
                      '${_calendarWeekdayName(selectedDay.weekday)}, ${_CalendarScreenState._months[selectedDay.month - 1]} ${selectedDay.day.toString().padLeft(2, '0')}',
                  pendingCount: pendingEvents,
                  completedCount: completedEvents,
                  showCompleted: state._showCompletedEvents,
                  onToggleCompleted:
                      state._toggleCompletedEventsVisibility,
                ),
                const SizedBox(height: 8),
                _CalendarEventsPane(
                  state: state,
                  eventsState: eventsState,
                  selectedDay: selectedDay,
                  writeState: writeState,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WeekBody extends StatelessWidget {
  const _WeekBody({
    required this.state,
    required this.textTheme,
    required this.title,
    required this.weekStart,
    required this.selectedDay,
    required this.weekEventsState,
  });

  final _CalendarScreenState state;
  final TextTheme textTheme;
  final String title;
  final DateTime weekStart;
  final DateTime selectedDay;
  final AsyncValue<List<CalendarEvent>> weekEventsState;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -120) state._changeWeek(state.ref, 1);
        if (velocity > 120) state._changeWeek(state.ref, -1);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => state._changeWeek(state.ref, -1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => state._changeWeek(state.ref, 1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                weekEventsState.when(
                  data: (events) => CalendarWeekView(
                    weekStart: weekStart,
                    selectedDay: selectedDay,
                    events: events,
                    onDayTap: (day) {
                      state.ref.read(selectedDayProvider.notifier).state = day;
                    },
                    onEventTap: (event) {
                      _editEventWithSuperSheetImpl(
                        state,
                        context,
                        event,
                        selectedDay,
                      );
                    },
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => ErrorMessage(
                    label: 'Unable to load events',
                    onRetry: () =>
                        state.ref.invalidate(weekEventsProvider),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayBody extends StatelessWidget {
  const _DayBody({
    required this.state,
    required this.textTheme,
    required this.title,
    required this.selectedDay,
    required this.eventsState,
  });

  final _CalendarScreenState state;
  final TextTheme textTheme;
  final String title;
  final DateTime selectedDay;
  final AsyncValue<List<CalendarEvent>> eventsState;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -120) state._changeDay(state.ref, 1);
        if (velocity > 120) state._changeDay(state.ref, -1);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => state._changeDay(state.ref, -1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => state._changeDay(state.ref, 1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: eventsState.when(
              data: (events) => CalendarDayView(
                selectedDate: selectedDay,
                events: events,
                onEventTap: (event) {
                  _editEventWithSuperSheetImpl(
                    state,
                    context,
                    event,
                    selectedDay,
                  );
                },
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (_, __) => ErrorMessage(
                label: 'Unable to load events',
                onRetry: () => state.ref.invalidate(dayEventsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
