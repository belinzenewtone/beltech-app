part of 'calendar_screen.dart';

class _CalendarLayout extends StatelessWidget {
  const _CalendarLayout({
    required this.state,
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
                const SizedBox(height: AppSpacing.sm),
                _CalendarViewTabs(
                  selected: state._view,
                  onSelected: state._setView,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              if (viewMode == CalendarViewMode.month)
                _MonthBody(
                  state: state,
                  title: title,
                  visibleMonth: visibleMonth,
                  selectedDay: selectedDay,
                  monthEventTypesState: monthEventTypesState,
                  monthTaskDays: monthTaskDays,
                  eventsState: eventsState,
                  tasksState: tasksState,
                  writeState: writeState,
                )
              else if (viewMode == CalendarViewMode.week)
                _WeekBody(
                  state: state,
                  title: title,
                  weekStart: weekStart,
                  selectedDay: selectedDay,
                  weekEventsState: weekEventsState,
                )
              else
                _DayBody(
                  state: state,
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
          child: AppFab(
            label: 'Add',
            busy: writeState.isLoading,
            onPressed: () => _handleSuperAddFromCalendarImpl(
              state,
              context,
              selectedDay,
              defaultKind: state._view == _CalendarView.tasks
                  ? SuperEntryKind.task
                  : SuperEntryKind.event,
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthBody extends StatelessWidget {
  const _MonthBody({
    required this.state,
    required this.title,
    required this.visibleMonth,
    required this.selectedDay,
    required this.monthEventTypesState,
    required this.monthTaskDays,
    required this.eventsState,
    required this.tasksState,
    required this.writeState,
  });

  final _CalendarScreenState state;
  final String title;
  final DateTime visibleMonth;
  final DateTime selectedDay;
  final AsyncValue<Map<int, CalendarEventType>> monthEventTypesState;
  final Set<int> monthTaskDays;
  final AsyncValue<List<CalendarEvent>> eventsState;
  final AsyncValue<List<TaskItem>> tasksState;
  final AsyncValue<void> writeState;

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${_calendarWeekdayName(selectedDay.weekday)}, ${_CalendarScreenState._months[selectedDay.month - 1]} ${selectedDay.day.toString().padLeft(2, '0')}';

    return Column(
      children: [
        if (state._view == _CalendarView.calendar)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) => state._beginSwipe(),
            onHorizontalDragEnd: state._handleSwipeEnd,
            onHorizontalDragCancel: state._cancelSwipe,
            child: AppCard(
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          ),
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppTypography.sectionTitle(context),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => state._changeMonth(state.ref, 1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _CalendarScreenState._calendarContentMaxWidth,
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
                                  style: AppTypography.bodyMd(context),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CalendarMonthGrid(
                    visibleMonth: visibleMonth,
                    selectedDay: selectedDay,
                    eventTypes: monthEventTypesState.valueOrNull ?? const {},
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
        if (state._view == _CalendarView.calendar)
          const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CalendarDetailHeader(
                dateLabel: dateLabel,
                showCompleted: state._view == _CalendarView.tasks
                    ? state._showCompletedTasks
                    : state._showCompletedEvents,
                onToggleCompleted: state._view == _CalendarView.tasks
                    ? state._toggleCompletedTasksVisibility
                    : state._toggleCompletedEventsVisibility,
                onSearchChanged: state._onSearchChanged,
                searchController: state._searchController,
              ),
              const SizedBox(height: AppSpacing.md),
              if (state._view == _CalendarView.tasks)
                _CalendarTasksPane(
                  state: state,
                  selectedDay: selectedDay,
                  tasksState: tasksState,
                )
              else
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
    required this.title,
    required this.weekStart,
    required this.selectedDay,
    required this.weekEventsState,
  });

  final _CalendarScreenState state;
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
          AppCard(
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTypography.sectionTitle(context),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => state._changeWeek(state.ref, 1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
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
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => ErrorMessage(
                    label: 'Unable to load events',
                    onRetry: () => state.ref.invalidate(weekEventsProvider),
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
    required this.title,
    required this.selectedDay,
    required this.eventsState,
  });

  final _CalendarScreenState state;
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.sectionTitle(context),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => state._changeDay(state.ref, 1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
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
              loading: () => const Center(child: CircularProgressIndicator()),
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

class _CalendarViewTabs extends StatelessWidget {
  const _CalendarViewTabs({required this.selected, required this.onSelected});

  final _CalendarView selected;
  final ValueChanged<_CalendarView> onSelected;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (_CalendarView.calendar, Icons.calendar_month_outlined, 'Calendar'),
      (_CalendarView.events, Icons.event_outlined, 'Events'),
      (_CalendarView.tasks, Icons.task_alt_outlined, 'Tasks'),
    ];

    return Row(
      children: tabs.map((tab) {
        final isSelected = selected == tab.$1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: tab.$1 == _CalendarView.calendar ? 6 : 0,
              left: tab.$1 == _CalendarView.tasks ? 6 : 0,
            ),
            child: AppButton(
              label: tab.$3,
              icon: tab.$2,
              size: AppButtonSize.sm,
              variant: isSelected
                  ? AppButtonVariant.primary
                  : AppButtonVariant.secondary,
              onPressed: () => onSelected(tab.$1),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CalendarDetailHeader extends StatelessWidget {
  const _CalendarDetailHeader({
    required this.dateLabel,
    required this.showCompleted,
    required this.onToggleCompleted,
    required this.onSearchChanged,
    required this.searchController,
  });

  final String dateLabel;
  final bool showCompleted;
  final VoidCallback onToggleCompleted;
  final ValueChanged<String> onSearchChanged;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                dateLabel,
                style: AppTypography.sectionTitle(context),
              ),
            ),
            AppIconPillButton(
              icon: showCompleted
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              tone: AppIconPillTone.subtle,
              onPressed: onToggleCompleted,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppSearchBar(
          controller: searchController,
          hint: 'Search...',
          onChanged: onSearchChanged,
        ),
      ],
    );
  }
}
