import 'dart:async';

import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_empty_state.dart';
import 'package:beltech/core/widgets/app_fab.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/app_icon_pill_button.dart';
import 'package:beltech/core/widgets/app_search_bar.dart';
import 'package:beltech/core/widgets/app_skeleton.dart';
import 'package:beltech/core/widgets/error_message.dart';
import 'package:beltech/core/widgets/page_header.dart';
import 'package:beltech/core/widgets/page_shell.dart';
import 'package:beltech/core/widgets/super_add_sheet.dart';
import 'package:beltech/features/calendar/domain/entities/calendar_event.dart';
import 'package:beltech/features/calendar/presentation/calendar_add_screen_models.dart';
import 'package:beltech/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:beltech/features/calendar/presentation/widgets/calendar_agenda_view.dart';
import 'package:beltech/features/calendar/presentation/widgets/calendar_day_view.dart';
import 'package:beltech/features/calendar/presentation/widgets/calendar_events_card.dart';
import 'package:beltech/features/calendar/presentation/widgets/calendar_month_grid.dart';
import 'package:beltech/features/calendar/presentation/widgets/calendar_week_view.dart';
import 'package:beltech/features/search/domain/entities/global_search_result.dart';
import 'package:beltech/features/search/presentation/providers/global_search_providers.dart';
import 'package:beltech/features/tasks/domain/entities/task_item.dart';
import 'package:beltech/features/tasks/presentation/providers/tasks_providers.dart';
import 'package:beltech/features/tasks/presentation/widgets/task_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

part 'calendar_screen_events.dart';
part 'calendar_screen_tasks.dart';
part 'calendar_screen_layout.dart';
part 'calendar_screen_actions.dart';
part 'calendar_screen_labels.dart';
part 'calendar_screen_section_header.dart';

enum _CalendarView { calendar, events, tasks }

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  _CalendarView _view = _CalendarView.calendar;
  bool _showAgenda = false;
  final bool _swiping = false;
  bool _showCompletedEvents = false;
  bool _showCompletedTasks = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  static const double _calendarContentMaxWidth = 360;

  // ── Month PageView ───────────────────────────────────────────────────────────
  static const int _pageBase = 12000; // page index for Jan 2000

  static int _monthToPage(DateTime month) =>
      _pageBase + (month.year - 2000) * 12 + (month.month - 1);

  static DateTime _pageToMonth(int page) {
    final delta = page - _pageBase;
    final year = 2000 + delta ~/ 12;
    final month = (delta % 12) + 1;
    return DateTime(year, month, 1);
  }

  late PageController _monthPageController;

  static const List<String> _weekDays = [
    'Mo',
    'Tu',
    'We',
    'Th',
    'Fr',
    'Sa',
    'Su',
  ];
  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    final initialMonth = ref.read(visibleMonthProvider);
    _monthPageController = PageController(
      initialPage: _monthToPage(initialMonth),
    );
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleMonth = ref.watch(visibleMonthProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final eventsState = ref.watch(dayEventsProvider);
    final tasksState = ref.watch(tasksProvider);
    final monthEventTypesState = ref.watch(monthEventTypesProvider);
    final writeState = ref.watch(calendarWriteControllerProvider);
    final viewMode = ref.watch(calendarViewModeProvider);
    final weekStart = ref.watch(visibleWeekStartProvider);
    final weekEventsState = ref.watch(weekEventsProvider);
    final agendaState = ref.watch(agendaEventsProvider);
    _syncSearchTargetDay(ref, selectedDay);

    ref.listen<AsyncValue<void>>(calendarWriteControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError) {
        AppFeedback.error(context, 'Unable to save calendar event.', ref: ref);
      }
    });

    final title = () {
      if (viewMode == CalendarViewMode.week) {
        final weekEnd = weekStart.add(const Duration(days: 6));
        final startLabel =
            '${_months[weekStart.month - 1].substring(0, 3)} ${weekStart.day}';
        final endLabel = weekStart.month == weekEnd.month
            ? '${weekEnd.day}'
            : '${_months[weekEnd.month - 1].substring(0, 3)} ${weekEnd.day}';
        return '$startLabel – $endLabel, ${weekEnd.year}';
      }
      if (viewMode == CalendarViewMode.day) {
        return '${_calendarWeekdayName(selectedDay.weekday)}, ${_months[selectedDay.month - 1].substring(0, 3)} ${selectedDay.day}';
      }
      return switch (_view) {
        _CalendarView.calendar =>
          '${_months[visibleMonth.month - 1]} ${visibleMonth.year}',
        _CalendarView.events =>
          'Events · ${_calendarWeekdayName(selectedDay.weekday)}, ${_months[selectedDay.month - 1].substring(0, 3)} ${selectedDay.day}',
        _CalendarView.tasks =>
          'Tasks · ${_calendarWeekdayName(selectedDay.weekday)}, ${_months[selectedDay.month - 1].substring(0, 3)} ${selectedDay.day}',
      };
    }();

    return _CalendarLayout(
      state: this,
      visibleMonth: visibleMonth,
      selectedDay: selectedDay,
      eventsState: eventsState,
      tasksState: tasksState,
      monthEventTypesState: monthEventTypesState,
      writeState: writeState,
      title: title,
      weekStart: weekStart,
      weekEventsState: weekEventsState,
      agendaState: agendaState,
    );
  }

  void _setView(_CalendarView view) {
    setState(() {
      _view = view;
      if (view != _CalendarView.calendar) _showAgenda = false;
    });
  }

  void _toggleAgenda() {
    setState(() => _showAgenda = !_showAgenda);
  }

  void _goToToday() {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    ref.read(selectedDayProvider.notifier).state = todayNorm;
    final todayMonth = DateTime(today.year, today.month, 1);
    ref.read(visibleMonthProvider.notifier).state = todayMonth;
    if (_monthPageController.hasClients) {
      final targetPage = _monthToPage(todayMonth);
      if (_monthPageController.page?.round() != targetPage) {
        unawaited(
          _monthPageController.animateToPage(
            targetPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
        );
      }
    }
  }

  void _toggleCompletedEventsVisibility() {
    setState(() => _showCompletedEvents = !_showCompletedEvents);
  }

  void _toggleCompletedTasksVisibility() {
    setState(() => _showCompletedTasks = !_showCompletedTasks);
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value.trim().toLowerCase());
  }

  void _syncSearchTargetDay(WidgetRef ref, DateTime selectedDay) {
    final target = ref.read(globalSearchDeepLinkTargetProvider);
    final kind = target?.kind;
    if (kind != GlobalSearchKind.event && kind != GlobalSearchKind.task) {
      return;
    }
    final targetView = kind == GlobalSearchKind.task
        ? _CalendarView.tasks
        : _CalendarView.events;
    if (_view != targetView) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _view == targetView) {
          return;
        }
        setState(() => _view = targetView);
      });
    }
    final recordDate = target?.recordDate;
    if (recordDate == null) {
      return;
    }
    final normalized = DateTime(
      recordDate.year,
      recordDate.month,
      recordDate.day,
    );
    if (_isSameDate(normalized, selectedDay)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>(() {
        if (!mounted) {
          return;
        }
        ref.read(selectedDayProvider.notifier).state = normalized;
        ref.read(visibleMonthProvider.notifier).state = DateTime(
          normalized.year,
          normalized.month,
          1,
        );
      });
    });
  }

  void _consumeSearchTarget(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDay,
    List<CalendarEvent> events,
  ) {
    final pendingTarget = ref.read(globalSearchDeepLinkTargetProvider);
    if (pendingTarget?.kind != GlobalSearchKind.event) {
      return;
    }
    final recordDate = pendingTarget?.recordDate;
    if (recordDate != null && !_isSameDate(recordDate, selectedDay)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>(() async {
        if (!context.mounted) {
          return;
        }
        final target = ref.read(globalSearchDeepLinkTargetProvider);
        if (target?.kind != GlobalSearchKind.event) {
          return;
        }
        final callbackDate = target?.recordDate;
        if (callbackDate != null && !_isSameDate(callbackDate, selectedDay)) {
          return;
        }
        ref.read(globalSearchDeepLinkTargetProvider.notifier).state = null;

        final recordId = target?.recordId;
        if (recordId == null) {
          return;
        }
        final event = events.where((item) => item.id == recordId).firstOrNull;
        if (event == null) {
          AppFeedback.info(
            context,
            'This calendar event no longer exists.',
            ref: ref,
          );
          return;
        }

        await _editEventWithSuperSheetImpl(this, context, event, selectedDay);
      });
    });
  }

  void _changeMonth(WidgetRef ref, int offset) {
    final visible = ref.read(visibleMonthProvider);
    final next = DateTime(visible.year, visible.month + offset, 1);
    ref.read(visibleMonthProvider.notifier).state = next;
    final selected = ref.read(selectedDayProvider);
    if (selected.year != next.year || selected.month != next.month) {
      ref.read(selectedDayProvider.notifier).state = DateTime(
        next.year,
        next.month,
        1,
      );
    }
    if (_monthPageController.hasClients) {
      final targetPage = _monthToPage(next);
      if (_monthPageController.page?.round() != targetPage) {
        unawaited(
          _monthPageController.animateToPage(
            targetPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
        );
      }
    }
  }

  void _changeWeek(WidgetRef ref, int offset) {
    final current = ref.read(visibleWeekStartProvider);
    final next = current.add(Duration(days: 7 * offset));
    ref.read(visibleWeekStartProvider.notifier).state = DateTime(
      next.year,
      next.month,
      next.day,
    );
    ref.read(selectedDayProvider.notifier).state = DateTime(
      next.year,
      next.month,
      next.day,
    );
    ref.read(visibleMonthProvider.notifier).state = DateTime(
      next.year,
      next.month,
      1,
    );
  }

  void _changeDay(WidgetRef ref, int offset) {
    final current = ref.read(selectedDayProvider);
    final next = current.add(Duration(days: offset));
    ref.read(selectedDayProvider.notifier).state = DateTime(
      next.year,
      next.month,
      next.day,
    );
    ref.read(visibleMonthProvider.notifier).state = DateTime(
      next.year,
      next.month,
      1,
    );
  }
}
