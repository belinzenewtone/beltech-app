part of 'app_drift_store.dart';

class _AppDriftSchemaMigrations {
  static Future<void> removeLegacySeedIncome(AppDriftStore store) async {
    await store._db.runDelete(
      'DELETE FROM incomes WHERE source = ? AND title = ?',
      ['seed', 'Salary'],
    );
  }

  static Future<void> seedDataIfEmpty(AppDriftStore store) async {
    final txCount = await store._countRows('transactions');
    if (txCount == 0) {
      final now = DateTime.now();
      final entries = [
        (
          'HOTEL DELITOS Via Kopo Kopo',
          'Food',
          140.0,
          now.subtract(const Duration(days: 1)),
        ),
        ('GRACE NGULI', 'Other', 100.0, now.subtract(const Duration(days: 2))),
        ('DELITOS HOTEL', 'Food', 400.0, now.subtract(const Duration(days: 3))),
        ('Unknown', 'Other', 623.53, now.subtract(const Duration(days: 4))),
        ('Unknown', 'Other', 865.93, now.subtract(const Duration(days: 5))),
        (
          'Airtime Topup',
          'Airtime',
          50.0,
          now.subtract(const Duration(days: 2)),
        ),
        (
          'Electricity Token',
          'Bills',
          20.0,
          now.subtract(const Duration(days: 3)),
        ),
      ];
      for (final entry in entries) {
        await store._db.runInsert(
          'INSERT INTO transactions(title, category, amount, occurred_at, source, source_hash) VALUES (?, ?, ?, ?, ?, ?)',
          [
            entry.$1,
            entry.$2,
            entry.$3,
            entry.$4.millisecondsSinceEpoch,
            'seed',
            null,
          ],
        );
      }
    }

    final taskCount = await store._countRows('tasks');
    if (taskCount == 0) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await store._db.runInsert(
        'INSERT INTO tasks(title, description, status, deadline, priority, reminder_offsets) VALUES (?, ?, ?, ?, ?, ?)',
        [
          'Prepare monthly spending review',
          'Review top spending categories and action items.',
          'pending',
          nowMs,
          'urgent',
          '30',
        ],
      );
      await store._db.runInsert(
        'INSERT INTO tasks(title, description, status, deadline, priority, completed_at, reminder_offsets) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          'Submit transport expense report',
          'Send final report to finance.',
          'completed',
          nowMs,
          'important',
          nowMs,
          '',
        ],
      );
    }

    final budgetCount = await store._countRows('budgets');
    if (budgetCount == 0) {
      await store._db.runInsert(
        'INSERT OR IGNORE INTO budgets(category, monthly_limit) VALUES (?, ?)',
        ['Food', 15000.0],
      );
      await store._db.runInsert(
        'INSERT OR IGNORE INTO budgets(category, monthly_limit) VALUES (?, ?)',
        ['Transport', 8000.0],
      );
    }
  }

  static Future<void> tryAddSourceHashColumn(AppDriftStore store) async {
    try {
      await store._db.runCustom(
        'ALTER TABLE transactions ADD COLUMN source_hash TEXT',
      );
    } catch (_) {
      return;
    }
  }

  static Future<void> tryAddBalanceAfterColumn(AppDriftStore store) async {
    try {
      await store._db.runCustom(
        'ALTER TABLE transactions ADD COLUMN balance_after REAL',
      );
    } catch (_) {
      return;
    }
  }

  static Future<void> tryAddTransactionTypeColumn(AppDriftStore store) async {
    try {
      await store._db.runCustom(
        'ALTER TABLE transactions ADD COLUMN transaction_type TEXT NOT NULL DEFAULT \'expense\'',
      );
    } catch (_) {
      return;
    }
  }

  static Future<void> tryAddTaskDescriptionColumn(AppDriftStore store) async {
    try {
      await store._db.runCustom(
        'ALTER TABLE tasks ADD COLUMN description TEXT',
      );
    } catch (_) {
      return;
    }
  }

  static Future<void> migrateTaskPriorityColumn(AppDriftStore store) async {
    // Ensure legacy 'high'/'medium'/'low' values map to Kotlin parity names.
    try {
      await store._db.runCustom(
        "UPDATE tasks SET priority = 'urgent' WHERE priority = 'high'",
      );
      await store._db.runCustom(
        "UPDATE tasks SET priority = 'important' WHERE priority = 'medium'",
      );
      await store._db.runCustom(
        "UPDATE tasks SET priority = 'neutral' WHERE priority = 'low' OR priority IS NULL OR priority = ''",
      );
    } catch (_) {
      return;
    }
  }

  static Future<void> migrateTaskStatusColumns(AppDriftStore store) async {
    try {
      await store._db.runCustom(
        'ALTER TABLE tasks ADD COLUMN status TEXT NOT NULL DEFAULT \'pending\'',
      );
    } catch (_) {}
    try {
      await store._db.runCustom(
        'ALTER TABLE tasks ADD COLUMN deadline INTEGER',
      );
    } catch (_) {}
    try {
      await store._db.runCustom(
        'UPDATE tasks SET deadline = due_at WHERE deadline IS NULL AND due_at IS NOT NULL',
      );
    } catch (_) {}
    try {
      await store._db.runCustom(
        'ALTER TABLE tasks ADD COLUMN completed_at INTEGER',
      );
    } catch (_) {}
    try {
      await store._db.runCustom(
        "UPDATE tasks SET status = 'completed', completed_at = ? WHERE completed = 1 OR completed = '1'",
        [DateTime.now().millisecondsSinceEpoch],
      );
    } catch (_) {}
    try {
      await store._db.runCustom(
        "UPDATE tasks SET status = 'pending' WHERE status IS NULL OR status = ''",
      );
    } catch (_) {}
  }

  static Future<void> migrateTaskReminderColumns(AppDriftStore store) async {
    try {
      await store._db.runCustom(
        'ALTER TABLE tasks ADD COLUMN reminder_offsets TEXT NOT NULL DEFAULT \'\'',
      );
    } catch (_) {}
    try {
      await store._db.runCustom(
        "UPDATE tasks SET reminder_offsets = reminder_minutes_before WHERE reminder_enabled = 1 AND (reminder_offsets IS NULL OR reminder_offsets = '')",
      );
    } catch (_) {}
  }

  static Future<void> migrateTaskAlarmColumn(AppDriftStore store) async {
    try {
      await store._db.runCustom(
        'ALTER TABLE tasks ADD COLUMN alarm_enabled INTEGER NOT NULL DEFAULT 0',
      );
    } catch (_) {}
  }

  static Future<void> tryAddIncomesSourceColumn(AppDriftStore store) async {
    try {
      await store._db.runCustom(
        'ALTER TABLE incomes ADD COLUMN source TEXT NOT NULL DEFAULT \'manual\'',
      );
    } catch (_) {
      return;
    }
  }

  static Future<void> tryAddRecurringPriorityColumn(AppDriftStore store) async {
    try {
      await store._db.runCustom(
        'ALTER TABLE recurring_templates ADD COLUMN priority TEXT',
      );
    } catch (_) {
      return;
    }
  }

  static Future<void> tryAddImportQueueSourceTimestampColumn(
    AppDriftStore store,
  ) async {
    try {
      await store._db.runCustom(
        'ALTER TABLE sms_import_queue ADD COLUMN source_timestamp INTEGER',
      );
    } catch (_) {
      return;
    }
  }

  static Future<void> tryAddEventCompletedColumn(AppDriftStore store) async {
    try {
      await store._db.runCustom(
        'ALTER TABLE events ADD COLUMN completed INTEGER NOT NULL DEFAULT 0',
      );
    } catch (_) {
      return;
    }
  }

  static Future<void> tryAddEventPriorityColumn(AppDriftStore store) async {
    try {
      await store._db.runCustom(
        'ALTER TABLE events ADD COLUMN priority TEXT NOT NULL DEFAULT \'medium\'',
      );
    } catch (_) {
      return;
    }
  }

  static Future<void> tryAddEventTypeColumn(AppDriftStore store) async {
    try {
      await store._db.runCustom(
        'ALTER TABLE events ADD COLUMN event_type TEXT NOT NULL DEFAULT \'general\'',
      );
    } catch (_) {
      return;
    }
  }

  static Future<void> tryAddEventReminderEnabledColumn(
    AppDriftStore store,
  ) async {
    try {
      await store._db.runCustom(
        'ALTER TABLE events ADD COLUMN reminder_enabled INTEGER NOT NULL DEFAULT 1',
      );
    } catch (_) {
      return;
    }
  }

  static Future<void> tryAddEventReminderMinutesColumn(
    AppDriftStore store,
  ) async {
    try {
      await store._db.runCustom(
        'ALTER TABLE events ADD COLUMN reminder_minutes_before INTEGER NOT NULL DEFAULT 15',
      );
    } catch (_) {
      return;
    }
  }

  static Future<void> migrateEventReminderColumns(AppDriftStore store) async {
    try {
      await store._db.runCustom(
        'ALTER TABLE events ADD COLUMN reminder_offsets TEXT NOT NULL DEFAULT \'15\'',
      );
    } catch (_) {}
    try {
      await store._db.runCustom(
        "UPDATE events SET reminder_offsets = reminder_minutes_before WHERE (reminder_offsets IS NULL OR reminder_offsets = '') AND reminder_minutes_before IS NOT NULL",
      );
    } catch (_) {}
  }

  static Future<void> migrateEventAlarmColumn(AppDriftStore store) async {
    try {
      await store._db.runCustom(
        'ALTER TABLE events ADD COLUMN alarm_enabled INTEGER NOT NULL DEFAULT 0',
      );
    } catch (_) {}
  }

  static Future<void> tryAddEventKindColumn(AppDriftStore store) async {
    try {
      await store._db.runCustom(
        "ALTER TABLE events ADD COLUMN event_kind TEXT NOT NULL DEFAULT 'event'",
      );
    } catch (_) {}
  }

  static Future<void> tryAddEventAllDayColumn(AppDriftStore store) async {
    try {
      await store._db.runCustom(
        'ALTER TABLE events ADD COLUMN all_day INTEGER NOT NULL DEFAULT 0',
      );
    } catch (_) {}
  }

  static Future<void> tryAddEventRepeatRuleColumn(AppDriftStore store) async {
    try {
      await store._db.runCustom(
        "ALTER TABLE events ADD COLUMN repeat_rule TEXT NOT NULL DEFAULT 'never'",
      );
    } catch (_) {}
  }

  static Future<void> tryAddEventGuestsColumn(AppDriftStore store) async {
    try {
      await store._db.runCustom(
        "ALTER TABLE events ADD COLUMN guests TEXT NOT NULL DEFAULT ''",
      );
    } catch (_) {}
  }

  static Future<void> tryAddEventTimeZoneColumn(AppDriftStore store) async {
    try {
      await store._db.runCustom(
        "ALTER TABLE events ADD COLUMN time_zone_id TEXT NOT NULL DEFAULT ''",
      );
    } catch (_) {}
  }

  static Future<void> tryAddEventReminderTimeColumn(AppDriftStore store) async {
    try {
      await store._db.runCustom(
        'ALTER TABLE events ADD COLUMN reminder_time_of_day_minutes INTEGER NOT NULL DEFAULT 480',
      );
    } catch (_) {}
  }
}
