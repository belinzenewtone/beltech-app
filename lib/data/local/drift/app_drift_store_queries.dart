part of 'app_drift_store.dart';

class _AppDriftQueries {
  static Future<HomeOverviewRecord> loadHomeOverview(
    AppDriftStore store,
  ) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    return HomeOverviewRecord(
      todayKes: await sumTransactionsBetween(store, todayStart, tomorrowStart),
      weekKes: await sumTransactionsBetween(store, weekStart, weekEnd),
      completedCount: await countWhere(store, "tasks", "status = 'completed'"),
      pendingCount: await countWhere(
        store,
        "tasks",
        "status != 'completed'",
      ),
      upcomingEventsCount: await countWhere(
        store,
        'events',
        'start_at >= ${todayStart.millisecondsSinceEpoch} AND completed = 0',
      ),
      weeklySpendingKes: await weeklySpending(store, now),
      recentTransactions: await loadRecentTransactions(store, limit: 5),
    );
  }

  static Future<ExpensesSnapshotRecord> loadExpensesSnapshot(
    AppDriftStore store,
  ) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    final categoryRows = await store._db.runSelect(
      'SELECT category, SUM(amount) AS total FROM transactions GROUP BY category',
      const [],
    );
    final categories =
        categoryRows
            .map(
              (row) => CategoryTotalRecord(
                category: (row['category'] ?? 'Other') as String,
                totalKes: store._asDouble(row['total']),
              ),
            )
            .toList()
          ..sort((a, b) => b.totalKes.compareTo(a.totalKes));

    return ExpensesSnapshotRecord(
      todayKes: await sumTransactionsBetween(store, todayStart, tomorrowStart),
      weekKes: await sumTransactionsBetween(store, weekStart, weekEnd),
      monthKes: await sumTransactionsBetween(store, monthStart, monthEnd),
      categories: categories,
      transactions: await loadRecentTransactions(store, limit: 20),
    );
  }

  static Future<List<DriftTaskRecord>> loadTasks(AppDriftStore store) async {
    final rows = await store._db.runSelect(
      'SELECT id, title, description, status, priority, deadline, completed_at, reminder_offsets, alarm_enabled FROM tasks ORDER BY deadline ASC, id DESC',
      const [],
    );
    return rows
        .map(
          (row) => DriftTaskRecord(
            id: store._asInt(row['id']),
            title: (row['title'] ?? '') as String,
            description: row['description'] as String?,
            status: (row['status'] ?? 'pending') as String,
            priority: (row['priority'] ?? 'neutral') as String,
            deadline: row['deadline'] == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(
                    store._asInt(row['deadline']),
                  ),
            completedAt: row['completed_at'] == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(
                    store._asInt(row['completed_at']),
                  ),
            reminderOffsets: _parseReminderOffsets(
              (row['reminder_offsets'] ?? '') as String,
            ),
            alarmEnabled: store._asInt(row['alarm_enabled']) == 1,
          ),
        )
        .toList();
  }

  static List<int> _parseReminderOffsets(String raw) {
    if (raw.isEmpty) return const [];
    return raw
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .where((m) => m >= 0)
        .toList();
  }

  static Future<List<DriftEventRecord>> loadEventsForDay(
    AppDriftStore store,
    DateTime day,
  ) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return loadEventsInRange(store, start, end);
  }

  static Future<List<DriftEventRecord>> loadAllEvents(
    AppDriftStore store,
  ) async {
    final rows = await store._db.runSelect(
      'SELECT id, title, start_at, end_at, note, completed, priority, event_type, event_kind, all_day, repeat_rule, reminder_offsets, alarm_enabled, guests, time_zone_id, reminder_time_of_day_minutes FROM events ORDER BY completed ASC, start_at ASC',
      const [],
    );
    return rows.map((row) => _eventRecordFromRow(store, row)).toList();
  }

  static Future<List<DriftEventRecord>> loadEventsInRange(
    AppDriftStore store,
    DateTime start,
    DateTime end,
  ) async {
    final rows = await store._db.runSelect(
      'SELECT id, title, start_at, end_at, note, completed, priority, event_type, event_kind, all_day, repeat_rule, reminder_offsets, alarm_enabled, guests, time_zone_id, reminder_time_of_day_minutes FROM events WHERE start_at >= ? AND start_at < ? ORDER BY completed ASC, start_at ASC',
      [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    return rows.map((row) => _eventRecordFromRow(store, row)).toList();
  }

  static DriftEventRecord _eventRecordFromRow(
    AppDriftStore store,
    Map<String, Object?> row,
  ) {
    return DriftEventRecord(
      id: store._asInt(row['id']),
      title: (row['title'] ?? '') as String,
      startAt: DateTime.fromMillisecondsSinceEpoch(
        store._asInt(row['start_at']),
      ),
      completed: store._asInt(row['completed']) == 1,
      priority: (row['priority'] ?? 'neutral') as String,
      eventType: (row['event_type'] ?? 'personal') as String,
      eventKind: (row['event_kind'] ?? 'event') as String,
      reminderOffsets: _parseReminderOffsets(
        (row['reminder_offsets'] ?? '') as String,
      ),
      alarmEnabled: store._asInt(row['alarm_enabled']) == 1,
      endAt: row['end_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              store._asInt(row['end_at']),
            ),
      note: row['note'] as String?,
      allDay: store._asInt(row['all_day']) == 1,
      repeatRule: (row['repeat_rule'] ?? 'never') as String,
      guests: (row['guests'] ?? '') as String,
      timeZoneId: (row['time_zone_id'] ?? '') as String,
      reminderTimeOfDayMinutes: store._asInt(
        row['reminder_time_of_day_minutes'],
      ),
    );
  }

  static Future<List<DriftTransactionRecord>> loadRecentTransactions(
    AppDriftStore store, {
    required int limit,
  }) async {
    final rows = await store._db.runSelect(
      'SELECT id, title, category, amount, occurred_at, balance_after FROM transactions ORDER BY occurred_at DESC LIMIT ?',
      [limit],
    );
    return rows
        .map(
          (row) => DriftTransactionRecord(
            id: store._asInt(row['id']),
            title: (row['title'] ?? '') as String,
            category: (row['category'] ?? 'Other') as String,
            amountKes: store._asDouble(row['amount']),
            occurredAt: DateTime.fromMillisecondsSinceEpoch(
              store._asInt(row['occurred_at']),
            ),
            balanceAfterKes: row['balance_after'] == null
                ? null
                : store._asDouble(row['balance_after']),
          ),
        )
        .toList();
  }

  static Future<Map<String, double>> weeklySpending(
    AppDriftStore store,
    DateTime now,
  ) async {
    const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final startSunday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday % 7));
    final result = <String, double>{};
    for (var index = 0; index < labels.length; index++) {
      final start = startSunday.add(Duration(days: index));
      final end = start.add(const Duration(days: 1));
      result[labels[index]] = await sumTransactionsBetween(store, start, end);
    }
    return result;
  }

  static Future<double> sumTransactionsBetween(
    AppDriftStore store,
    DateTime start,
    DateTime end,
  ) async {
    final rows = await store._db.runSelect(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM transactions WHERE occurred_at >= ? AND occurred_at < ?',
      [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    return store._asDouble(rows.first['total']);
  }

  static Future<int> countRows(AppDriftStore store, String tableName) async {
    final rows = await store._db.runSelect(
      'SELECT COUNT(*) AS total FROM $tableName',
      const [],
    );
    return store._asInt(rows.first['total']);
  }

  static Future<int> countWhere(
    AppDriftStore store,
    String tableName,
    String whereSql,
  ) async {
    final rows = await store._db.runSelect(
      'SELECT COUNT(*) AS total FROM $tableName WHERE $whereSql',
      const [],
    );
    return store._asInt(rows.first['total']);
  }
}
