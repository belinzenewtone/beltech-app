part of 'calendar_screen.dart';

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _calendarWeekRangeLabel(DateTime day) {
  final start = day.subtract(Duration(days: day.weekday - 1));
  final end = start.add(const Duration(days: 6));
  final startStr =
      '${_CalendarScreenState._months[start.month - 1].substring(0, 3)} ${start.day}';
  final endStr = start.month == end.month
      ? '${end.day}'
      : '${_CalendarScreenState._months[end.month - 1].substring(0, 3)} ${end.day}';
  return '$startStr – $endStr, ${end.year}';
}

String _calendarWeekdayName(int weekday) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return weekdays[weekday - 1];
}
