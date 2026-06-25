import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:beltech/core/widgets/permission_rationale.dart';

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

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> scheduleTaskReminder({
    required int taskId,
    required String title,
    required DateTime dueDate,
    int minutesBefore = 30,
  }) async {
    final hasExplicitTime = dueDate.hour != 0 || dueDate.minute != 0;
    final dueAnchor = hasExplicitTime
        ? dueDate
        : DateTime(dueDate.year, dueDate.month, dueDate.day, 9);
    final reminderAt = minutesBefore <= 0
        ? dueAnchor
        : dueAnchor.subtract(Duration(minutes: minutesBefore));
    await _scheduleAt(
      id: _notifId(_nsTask, taskId),
      title: 'Task Reminder',
      body: '$title is due soon.',
      when: reminderAt,
      payload: '/tasks',
    );
  }

  Future<void> cancelTaskReminder(int taskId) {
    return _cancelById(_notifId(_nsTask, taskId));
  }

  Future<void> scheduleEventReminder({
    required int eventId,
    required String title,
    required DateTime startAt,
    int minutesBefore = 15,
  }) async {
    final now = DateTime.now();
    final preferredReminderAt = minutesBefore <= 0
        ? startAt
        : startAt.subtract(Duration(minutes: minutesBefore));
    final reminderAt = preferredReminderAt.isAfter(now)
        ? preferredReminderAt
        : startAt;
    await _scheduleAt(
      id: _notifId(_nsEvent, eventId),
      title: 'Upcoming Event',
      body: '$title starts soon.',
      when: reminderAt,
      payload: '/calendar',
    );
  }

  Future<void> cancelEventReminder(int eventId) {
    return _cancelById(_notifId(_nsEvent, eventId));
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

  Future<void> showBillReminder({
    required int billId,
    required String billName,
    required double amount,
    required int daysUntil,
  }) async {
    final enabled = await isNotificationsEnabled();
    if (!enabled) return;
    await _ensureInitialized();
    final body = daysUntil <= 0
        ? 'Bill "$billName" is overdue! Amount: ${amount.toStringAsFixed(0)}'
        : 'Bill "$billName" is due in $daysUntil day(s). Amount: ${amount.toStringAsFixed(0)}';
    await _plugin.show(
      id: _notifId(_nsBill, billId),
      title: 'Bill Reminder',
      body: body,
      notificationDetails: _details,
      payload: '/bills',
    );
  }

  Future<void> showLearningReminder({required int dayOffset}) async {
    final enabled = await isNotificationsEnabled();
    if (!enabled) return;
    await _ensureInitialized();
    await _plugin.show(
      id: _notifId(_nsLearning, dayOffset),
      title: 'Learning Streak',
      body: dayOffset == 0
          ? 'Log a learning session today to keep your streak alive!'
          : 'You have not logged a learning session recently. Keep the momentum!',
      notificationDetails: _details,
      payload: '/learning',
    );
  }

  Future<void> cancelAllReminders() async {
    await _ensureInitialized();
    await _plugin.cancelAll();
  }

  Future<void> cleanupOrphanedReminders({
    required Iterable<int> activeTaskIds,
    required Iterable<int> activeEventIds,
  }) async {
    await _ensureInitialized();
    final pending = await _plugin.pendingNotificationRequests();

    // Build the complete set of IDs that should currently be scheduled.
    // Insights use show() (immediate) so they never appear in pending — safe
    // to cancel anything not in this whitelist.
    final validIds = <int>{
      for (final id in activeTaskIds) _notifId(_nsTask, id),
      for (final id in activeEventIds) _notifId(_nsEvent, id),
    };

    for (final item in pending) {
      if (!validIds.contains(item.id)) {
        await _plugin.cancel(id: item.id);
      }
    }
  }

  Future<void> _scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
  }) async {
    final enabled = await isNotificationsEnabled();
    if (!enabled) {
      return;
    }
    if (!when.isAfter(DateTime.now())) {
      return;
    }
    await _ensureInitialized();
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
