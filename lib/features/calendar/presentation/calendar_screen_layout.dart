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
    required this.agendaState,
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
  final AsyncValue<List<CalendarEvent>> agendaState;

  @override
  Widget build(BuildContext context) {
    final viewMode = state.ref.watch(calendarViewModeProvider);

    final monthTaskDays = (tasksState.value ?? const <TaskItem>[])
        .where((task) {
          final deadline = task.deadline;
          return deadline != null &&
              deadline.year == visibleMonth.year &&
              deadline.month == visibleMonth.month;
        })
        .map((task) => task.deadline!.day)
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
                    if (viewMode == CalendarViewMode.month) {
                      state._goToToday();
                    } else {
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
                        state.ref
                            .read(visibleWeekStartProvider.notifier)
                            .state = monday;
                      }
                      state.ref.read(visibleMonthProvider.notifier).state =
                          DateTime(today.year, today.month, 1);
                    }
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
                  agendaState: agendaState,
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
    required this.agendaState,
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
  final AsyncValue<List<CalendarEvent>> agendaState;

  // Max height of the month grid: 6 rows × 42px cell height.
  static const double _gridHeight = 252;

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${_calendarWeekdayName(selectedDay.weekday)}, ${_CalendarScreenState._months[selectedDay.month - 1]} ${selectedDay.day.toString().padLeft(2, '0')}';

    return Column(
      children: [
        // ── Month grid card (calendar view only) ────────────────────────────
        if (state._view == _CalendarView.calendar) ...[
          AppCard(
            child: Column(
              children: [
                // Navigation row
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
                // Month | Agenda toggle chips
                const SizedBox(height: AppSpacing.xs),
                _MonthAgendaToggle(
                  showAgenda: state._showAgenda,
                  onToggle: state._toggleAgenda,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (!state._showAgenda) ...[
                  // Weekday header row
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
                                  style: AppTypography.bodyMd(context),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // PageView for animated month swipe
                  SizedBox(
                    height: _gridHeight,
                    child: PageView.builder(
                      controller: state._monthPageController,
                      onPageChanged: (page) {
                        final month =
                            _CalendarScreenState._pageToMonth(page);
                        final current =
                            state.ref.read(visibleMonthProvider);
                        if (month.year != current.year ||
                            month.month != current.month) {
                          state.ref
                              .read(visibleMonthProvider.notifier)
                              .state = month;
                          final sel =
                              state.ref.read(selectedDayProvider);
                          if (sel.year != month.year ||
                              sel.month != month.month) {
                            state.ref
                                .read(selectedDayProvider.notifier)
                                .state = DateTime(
                              month.year,
                              month.month,
                              1,
                            );
                          }
                        }
                      },
                      itemBuilder: (context, page) {
                        final month =
                            _CalendarScreenState._pageToMonth(page);
                        final isCurrent = month.year == visibleMonth.year &&
                            month.month == visibleMonth.month;
                        return CalendarMonthGrid(
                          visibleMonth: month,
                          selectedDay: selectedDay,
                          eventTypes: isCurrent
                              ? (monthEventTypesState.value ?? const {})
                              : const {},
                          taskDays:
                              isCurrent ? monthTaskDays : const {},
                          maxWidth: _CalendarScreenState
                              ._calendarContentMaxWidth,
                          onSelect: (day) {
                            state.ref
                                .read(selectedDayProvider.notifier)
                                .state = day;
                          },
                        );
                      },
                    ),
                  ),
                ] else ...[
                  // Agenda view — 30-day chronological list
                  agendaState.when(
                    data: (events) => CalendarAgendaView(
                      events: events
                          .where((e) => !e.completed)
                          .toList(growable: false),
                      onEventTap: (event) =>
                          _editEventWithSuperSheetImpl(
                        state,
                        context,
                        event,
                        selectedDay,
                      ),
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, _) => ErrorMessage(
                      label: 'Unable to load agenda',
                      onRetry: () =>
                          state.ref.invalidate(agendaEventsProvider),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        // ── Day detail card (events / tasks tabs) ──────────────────────────
        if (state._view != _CalendarView.calendar)
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

class _MonthAgendaToggle extends StatelessWidget {
  const _MonthAgendaToggle({
    required this.showAgenda,
    required this.onToggle,
  });

  final bool showAgenda;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ToggleChip(
          label: 'Month',
          icon: Icons.calendar_month_outlined,
          selected: !showAgenda,
          onTap: showAgenda ? onToggle : null,
        ),
        const SizedBox(width: AppSpacing.sm),
        _ToggleChip(
          label: 'Agenda',
          icon: Icons.view_agenda_outlined,
          selected: showAgenda,
          onTap: showAgenda ? null : onToggle,
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final selectedColor = AppColors.accent;
    final unselectedColor = AppColors.textMutedFor(brightness);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected
              ? selectedColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? selectedColor : unselectedColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? selectedColor : unselectedColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.label(context).copyWith(
                color: selected ? selectedColor : unselectedColor,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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
                  error: (_, _) => ErrorMessage(
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
              error: (_, _) => ErrorMessage(
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
