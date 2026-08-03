import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:beltech/core/widgets/permission_rationale.dart';
import 'package:beltech/features/calendar/domain/entities/calendar_event.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalNotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final _tapController = StreamController<String>.broadcast();

  /// Emits the route payload string whenever a notification is tapped
  /// while the app is in the foreground or restored from background.
  Stream<String> get notificationTapRoutes => _tapController.stream;

  void dispose() => _tapController.close();

  // ── Notification ID namespaces ────────────────────────────────────────────
  // IDs are computed via FNV-1a hash of (namespace + ":" + recordId), so each
  // (namespace, recordId) pair maps to a unique, stable positive int32. This
  // eliminates the collision risk of the old additive-offset approach (which
  // would collide whenever a taskId exceeded 100,000).
  static const String _nsTask = 'task';
  static const String _nsEvent = 'event';
  static const String _nsInsight = 'insight';
  static const String _nsBill = 'bill';
  static const String _nsLearning = 'learning';

  /// Deterministic FNV-1a hash of [namespace]:[recordId] → positive int32.
  static int _notifId(String namespace, int recordId) {
    var hash = 0x811c9dc5; // FNV-1a 32-bit offset basis
    void fnvByte(int byte) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF; // FNV prime
    }

    for (final c in namespace.codeUnits) {
      fnvByte(c);
    }
    fnvByte(0x3A); // ':' separator
    var id = recordId;
    do {
      fnvByte(id & 0xFF);
      id >>= 8;
    } while (id > 0);
    return hash & 0x7FFFFFFF; // ensure positive (signed int32 safe)
  }

  static const String _channelId = 'task_event_reminders';
  static const String _channelName = 'Task and Event Reminders';
  static const String _channelDescription =
      'Notifications for task deadlines and calendar events.';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const int _maxOffsets = 20;

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> scheduleTaskReminder({
    required int taskId,
    required String title,
    required DateTime deadline,
    List<int> reminderOffsets = const [30],
    bool alarmEnabled = false,
  }) async {
    await cancelTaskReminder(taskId);
    final now = DateTime.now();
    final triggers = _computeTaskReminderTriggers(deadline, reminderOffsets, now);
    for (var i = 0; i < triggers.length; i++) {
      await _scheduleAt(
        id: _notifId(_nsTask, taskId * 100 + i),
        title: alarmEnabled ? 'Task Alarm' : 'Task Reminder',
        body: alarmEnabled ? '$title is due now.' : '$title is due soon.',
        when: triggers[i],
        payload: '/tasks',
        alarmEnabled: alarmEnabled,
      );
    }
  }

  List<DateTime> _computeTaskReminderTriggers(
    DateTime deadline,
    List<int> reminderOffsets,
    DateTime now,
  ) {
    return reminderOffsets
        .map((minutes) => deadline.subtract(Duration(minutes: minutes)))
        .where((trigger) => trigger.isAfter(now))
        .toList()
      ..sort();
  }

  Future<void> cancelTaskReminder(int taskId) async {
    for (var i = 0; i < _maxOffsets; i++) {
      await _cancelById(_notifId(_nsTask, taskId * 100 + i));
    }
  }

  Future<void> scheduleEventReminder({
    required int eventId,
    required String title,
    required DateTime startAt,
    List<int> reminderOffsets = const [15],
    bool alarmEnabled = false,
    CalendarEventKind kind = CalendarEventKind.event,
    bool allDay = false,
    int reminderTimeOfDayMinutes = 480,
    RepeatRule repeatRule = RepeatRule.never,
  }) async {
    await cancelEventReminder(eventId);
    final now = DateTime.now();

    final yearly = repeatRule == RepeatRule.yearly ||
        kind == CalendarEventKind.anniversary ||
        kind == CalendarEventKind.birthday;

    // Map every RepeatRule to the OS DateTimeComponents that matches its
    // cadence so the alarm continues firing on the right schedule after the
    // anchor date passes — not just once on the first future occurrence.
    //
    // monFri uses DateTimeComponents.time (daily) as an approximation: the OS
    // has no 5-day weekday component, and daily is safer than no repeat.
    final DateTimeComponents? matchComponents = switch (repeatRule) {
      RepeatRule.yearly => DateTimeComponents.dateAndTime,
      RepeatRule.monthly => DateTimeComponents.dayOfMonthAndTime,
      RepeatRule.weekly => DateTimeComponents.dayOfWeekAndTime,
      RepeatRule.monFri => DateTimeComponents.time,
      RepeatRule.daily => DateTimeComponents.time,
      RepeatRule.never => yearly ? DateTimeComponents.dateAndTime : null,
    };

    final isRepeating = matchComponents != null;

    // Yearly occasions: advance anchor to the next future occurrence so the
    // repeating OS alarm has a valid seed date.
    final effectiveStart =
        yearly ? _nextYearlyOccurrence(startAt, now) : startAt;

    final triggers = _computeEventReminderTriggers(
      startAt: effectiveStart,
      offsets: reminderOffsets,
      now: now,
      allDay: allDay,
      reminderTimeOfDayMinutes: reminderTimeOfDayMinutes,
      // Repeating alarms may legitimately have past anchors — the OS
      // advances them to the next matching date/time automatically.
      allowPast: isRepeating,
    );

    for (var i = 0; i < triggers.length; i++) {
      await _scheduleAt(
        id: _notifId(_nsEvent, eventId * 100 + i),
        title: alarmEnabled ? 'Event Alarm' : 'Upcoming Event',
        body: alarmEnabled ? '$title starts now.' : '$title starts soon.',
        when: triggers[i],
        payload: '/calendar',
        alarmEnabled: alarmEnabled,
        matchDateTimeComponents: matchComponents,
      );
    }
  }

  /// Returns [anchor] advanced to its next occurrence on/after [now], keeping
  /// the same month/day/time (used for yearly-recurring reminders).
  static DateTime _nextYearlyOccurrence(DateTime anchor, DateTime now) {
    var candidate = anchor;
    while (candidate.isBefore(now)) {
      candidate = DateTime(
        candidate.year + 1,
        anchor.month,
        anchor.day,
        anchor.hour,
        anchor.minute,
      );
    }
    return candidate;
  }

  List<DateTime> _computeEventReminderTriggers({
    required DateTime startAt,
    required List<int> offsets,
    required DateTime now,
    required bool allDay,
    required int reminderTimeOfDayMinutes,
    bool allowPast = false,
  }) {
    final hour = reminderTimeOfDayMinutes ~/ 60;
    final minute = reminderTimeOfDayMinutes % 60;
    final useAllDayStyle = allDay ||
        startAt.hour == 0 && startAt.minute == 0;

    final triggers = offsets.map((offset) {
      if (useAllDayStyle) {
        // offset is in days; fire at the configured time of day.
        final day = startAt.subtract(Duration(days: offset));
        return DateTime(day.year, day.month, day.day, hour, minute);
      }
      return startAt.subtract(Duration(minutes: offset));
    });
    // For yearly reminders the anchor is already the next occurrence, so a
    // trigger slightly in the past is fine — the OS rolls it to next year.
    return (allowPast
            ? triggers.toList()
            : triggers.where((trigger) => trigger.isAfter(now)).toList())
      ..sort();
  }

  Future<void> cancelEventReminder(int eventId) async {
    for (var i = 0; i < _maxOffsets; i++) {
      await _cancelById(_notifId(_nsEvent, eventId * 100 + i));
    }
  }

  /// Show a generic notification immediately.
  Future<void> showNotification({
    required String id,
    required String title,
    required String body,
    Map<String, String>? payload,
  }) async {
    final enabled = await isNotificationsEnabled();
    if (!enabled) {
      return;
    }
    await _ensureInitialized();
    // Use FNV hash of id string to get a stable numeric ID
    int idHash = 0x811c9dc5;
    for (final byte in id.codeUnits) {
      idHash ^= byte;
      idHash = (idHash * 0x01000193) & 0xFFFFFFFF;
    }
    final numericId = idHash & 0x7FFFFFFF;
    await _plugin.show(
      id: numericId,
      title: title,
      body: body,
      notificationDetails: _details,
      payload: payload?['type'] ?? '/home',
    );
  }

  Future<void> showInsight({
    required int insightId,
    required String title,
    required String body,
  }) async {
    final enabled = await isNotificationsEnabled();
    if (!enabled) {
      return;
    }
    await _ensureInitialized();
    await _plugin.show(
      id: _notifId(_nsInsight, insightId),
      title: title,
      body: body,
      notificationDetails: _details,
      payload: '/home',
    );
  }

  Future<bool> isNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
    if (!enabled) {
      await cancelAllReminders();
    }
  }

  Future<(int, int)> getDailyDigestScheduleTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('daily_digest_hour') ?? 7;
    final minute = prefs.getInt('daily_digest_minute') ?? 0;
    return (hour, minute);
  }

  Future<void> setDailyDigestScheduleTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daily_digest_hour', hour);
    await prefs.setInt('daily_digest_minute', minute);
    await scheduleDailyDigest();
  }

  Future<(double, double, double)> getBudgetAlertThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    final high = prefs.getDouble('budget_alert_high_threshold') ?? 90.0;
    final medium = prefs.getDouble('budget_alert_medium_threshold') ?? 70.0;
    final low = prefs.getDouble('budget_alert_low_threshold') ?? 50.0;
    return (high, medium, low);
  }

  Future<void> setBudgetAlertThresholds(
    double high,
    double medium,
    double low,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('budget_alert_high_threshold', high);
    await prefs.setDouble('budget_alert_medium_threshold', medium);
    await prefs.setDouble('budget_alert_low_threshold', low);
  }

  Future<double> getFulizaLimit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('fuliza_limit') ?? 0.0;
  }

  Future<void> setFulizaLimit(double limit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fuliza_limit', limit);
  }

  /// Authoritative outstanding Fuliza balance, last stated in an SMS charge
  /// notice or limit summary. `0` when never seen.
  Future<double> getFulizaOutstanding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('fuliza_outstanding') ?? 0.0;
  }

  Future<(int, int)> getDoNotDisturbHours() async {
    final prefs = await SharedPreferences.getInstance();
    final startHour = prefs.getInt('dnd_start_hour') ?? 22;
    final endHour = prefs.getInt('dnd_end_hour') ?? 7;
    return (startHour, endHour);
  }

  Future<void> setDoNotDisturbHours(int startHour, int endHour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dnd_start_hour', startHour);
    await prefs.setInt('dnd_end_hour', endHour);
  }

  Future<bool> requestNotificationPermissionWithRationale(
    BuildContext context,
  ) async {
    final alreadyEnabled = await isNotificationsEnabled();
    if (alreadyEnabled) {
      return true;
    }
    if (!context.mounted) return false;
    final accepted = await showPermissionRationaleSheet(
      context: context,
      icon: Icons.notifications_outlined,
      title: 'Stay on Track',
      description:
          'Get reminded about tasks, events, bills, and learning sessions so you never miss a deadline.',
      bulletPoints: const [
        'Task and event reminders',
        'Bill due date alerts',
        'Learning streak nudges',
        'You can disable anytime in Settings',
      ],
    );
    if (!accepted) {
      return false;
    }
    await setNotificationsEnabled(true);
    await _ensureInitialized();
    await _requestPlatformPermission();
    return true;
  }

  // Days-before-due at which a bill reminder fires, all at [_billReminderHour].
  static const List<int> _billOffsetDays = [3, 1, 0];
  static const int _billReminderHour = 9;

  /// Schedules OS-level reminders for a single bill at its due date (and 1/3
  /// days before). Content is fully known now, so these fire on time even when
  /// the app is killed. Cancel-then-reschedule makes it idempotent.
  Future<void> scheduleBillReminder({
    required int billId,
    required String billName,
    required double amount,
    required DateTime dueDate,
  }) async {
    await cancelBillReminder(billId);
    final now = DateTime.now();
    final dueAtHour = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      _billReminderHour,
    );
    for (var i = 0; i < _billOffsetDays.length; i++) {
      final offset = _billOffsetDays[i];
      final when = dueAtHour.subtract(Duration(days: offset));
      if (!when.isAfter(now)) continue;
      final body = offset == 0
          ? 'Bill "$billName" is due today. Amount: ${amount.toStringAsFixed(0)}'
          : 'Bill "$billName" is due in $offset day(s). Amount: ${amount.toStringAsFixed(0)}';
      await _scheduleAt(
        id: _notifId(_nsBill, billId * 100 + i),
        title: 'Bill Reminder',
        body: body,
        when: when,
        payload: '/bills',
      );
    }
  }

  Future<void> cancelBillReminder(int billId) async {
    for (var i = 0; i < _maxOffsets; i++) {
      await _cancelById(_notifId(_nsBill, billId * 100 + i));
    }
  }

  // Reserved record-ids for the singleton daily repeating reminders. Chosen
  // high to avoid colliding with real insight/learning record ids.
  static const int _digestSlot = 999001;
  static const int _learningDailySlot = 999002;

  /// Daily repeating "your summary is ready" reminder at the user's chosen
  /// digest time. Fires every day even when the app is closed; tapping it opens
  /// the app which renders the live figures.
  Future<void> scheduleDailyDigest() async {
    await cancelDailyDigest();
    if (!await isNotificationsEnabled()) return;
    final prefs = await SharedPreferences.getInstance();
    // Respects the Settings "Daily Summary" toggle (defaults on).
    if (!(prefs.getBool('notifications_daily_digest') ?? true)) return;
    final (hour, minute) = await getDailyDigestScheduleTime();
    await _scheduleAt(
      id: _notifId(_nsInsight, _digestSlot),
      title: 'Daily Summary',
      body: 'Your spending summary is ready — tap to review today.',
      when: _nextTimeOfDay(hour, minute, DateTime.now()),
      payload: '/home',
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyDigest() =>
      _cancelById(_notifId(_nsInsight, _digestSlot));

  /// Daily repeating learning-streak nudge at the user's chosen time.
  Future<void> scheduleLearningDailyReminder() async {
    await cancelLearningDailyReminder();
    if (!await isNotificationsEnabled()) return;
    if (!await isLearningReminderEnabled()) return;
    final (hour, minute) = await getLearningReminderTime();
    await _scheduleAt(
      id: _notifId(_nsLearning, _learningDailySlot),
      title: 'Learning Streak',
      body: 'Keep your streak alive — log a learning session today.',
      when: _nextTimeOfDay(hour, minute, DateTime.now()),
      payload: '/learning',
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelLearningDailyReminder() =>
      _cancelById(_notifId(_nsLearning, _learningDailySlot));

  Future<(int, int)> getLearningReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('learning_reminder_hour') ?? 19;
    final minute = prefs.getInt('learning_reminder_minute') ?? 0;
    return (hour, minute);
  }

  Future<void> setLearningReminderTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('learning_reminder_hour', hour);
    await prefs.setInt('learning_reminder_minute', minute);
    await scheduleLearningDailyReminder();
  }

  Future<bool> isLearningReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_learning_reminder') ?? true;
  }

  Future<void> setLearningReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_learning_reminder', enabled);
    await scheduleLearningDailyReminder();
  }

  /// Returns the next [hour]:[minute] on/after [now] (today, or tomorrow if
  /// that time already passed today).
  static DateTime _nextTimeOfDay(int hour, int minute, DateTime now) {
    var when = DateTime(now.year, now.month, now.day, hour, minute);
    if (!when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }
    return when;
  }

  Future<void> cancelAllReminders() async {
    await _ensureInitialized();
    await _plugin.cancelAll();
  }

  Future<void> cleanupOrphanedReminders({
    required Iterable<int> activeTaskIds,
    required Iterable<int> activeEventIds,
    Iterable<int> activeBillIds = const [],
  }) async {
    await _ensureInitialized();
    final pending = await _plugin.pendingNotificationRequests();

    // Build the complete set of IDs that SHOULD currently be scheduled. Each
    // task/event/bill fans out to up to _maxOffsets scheduled ids using the
    // same (recordId * 100 + offsetIndex) scheme used when scheduling — the
    // previous version whitelisted only the bare recordId, so every real
    // reminder was treated as orphaned and cancelled on the next app open.
    final validIds = <int>{
      for (final id in activeTaskIds)
        for (var i = 0; i < _maxOffsets; i++) _notifId(_nsTask, id * 100 + i),
      for (final id in activeEventIds)
        for (var i = 0; i < _maxOffsets; i++) _notifId(_nsEvent, id * 100 + i),
      for (final id in activeBillIds)
        for (var i = 0; i < _maxOffsets; i++) _notifId(_nsBill, id * 100 + i),
      // Singleton daily-repeating reminders.
      _notifId(_nsInsight, _digestSlot),
      _notifId(_nsLearning, _learningDailySlot),
    };

    for (final item in pending) {
      if (!validIds.contains(item.id)) {
        await _plugin.cancel(id: item.id);
      }
    }
  }

  Future<bool> _ensureExactAlarmPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }
    final status = await Permission.scheduleExactAlarm.status;
    if (status.isGranted) {
      return true;
    }
    final result = await Permission.scheduleExactAlarm.request();
    return result.isGranted;
  }

  Future<void> _scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
    bool alarmEnabled = false,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    final enabled = await isNotificationsEnabled();
    if (!enabled) {
      return;
    }
    // Repeating notifications (matchDateTimeComponents != null) may legitimately
    // have a first anchor in the past — the OS advances them to the next match.
    if (matchDateTimeComponents == null && !when.isAfter(DateTime.now())) {
      return;
    }
    await _ensureInitialized();
    // Choose the strongest schedule mode the OS will allow, but NEVER silently
    // drop the reminder: if exact-alarm permission is denied, fall back to an
    // inexact (but still while-idle) alarm so it still fires — just less
    // precisely — instead of not firing at all.
    final canScheduleExact = await _ensureExactAlarmPermission();
    final AndroidScheduleMode scheduleMode;
    if (!canScheduleExact) {
      scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
    } else if (alarmEnabled) {
      scheduleMode = AndroidScheduleMode.alarmClock;
    } else {
      scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
    }
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: _details,
      androidScheduleMode: scheduleMode,
      matchDateTimeComponents: matchDateTimeComponents,
      payload: payload,
    );
  }

  Future<void> _cancelById(int id) async {
    await _ensureInitialized();
    await _plugin.cancel(id: id);
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && !_tapController.isClosed) {
      _tapController.add(payload);
    }
  }

  /// Initialises the plugin and returns the route payload from the notification
  /// that cold-started the app, or `null` if the app was launched normally.
  Future<String?> getNotificationLaunchRoute() async {
    await _ensureInitialized();
    if (kIsWeb) return null;
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return details.notificationResponse?.payload;
  }

  /// Public entry point so callers (e.g. [AppShell]) can eagerly initialise
  /// the plugin on startup without scheduling a notification first.
  Future<void> initialize() => _ensureInitialized();

  /// Requests the OS-level permissions that gate delivery — POST_NOTIFICATIONS
  /// (Android 13+) and exact-alarm scheduling (Android 12+). Safe to call on
  /// every launch: the OS only prompts once and no-ops thereafter. Without
  /// this, a fresh Android 13+ install never shows the notification prompt and
  /// nothing fires at all.
  Future<void> ensurePlatformPermissions() async {
    if (kIsWeb) return;
    if (!await isNotificationsEnabled()) return;
    await _ensureInitialized();
    await _requestPlatformPermission();
    await _ensureExactAlarmPermission();
  }

  Future<void> _requestPlatformPermission() async {
    await _ensureInitialized();
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      windows: WindowsInitializationSettings(
        appName: 'BELTECH',
        appUserModelId: 'beltech.app',
        guid: 'cd8f4c25-95e8-420f-b74b-c30db7b8e8c9',
      ),
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
  }

  NotificationDetails get _details {
    const android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      silent: false,
    );
    const darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    return const NotificationDetails(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );
  }
}
