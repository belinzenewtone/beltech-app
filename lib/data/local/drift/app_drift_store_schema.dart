part of 'app_drift_store.dart';

class _AppDriftSchema {
  static Future<void> ensureInitialized(AppDriftStore store) async {
    if (store._initialized) {
      return;
    }
    await store._db.ensureOpen(const _StoreQueryExecutorUser());

    await store._db.runCustom(
      'CREATE TABLE IF NOT EXISTS transactions('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'title TEXT NOT NULL,'
      'category TEXT NOT NULL,'
      'amount REAL NOT NULL,'
      'occurred_at INTEGER NOT NULL,'
      'source TEXT NOT NULL,'
      'source_hash TEXT,'
      'transaction_type TEXT NOT NULL DEFAULT \'expense\','
      'balance_after REAL'
      ')',
    );
    await _AppDriftSchemaMigrations.tryAddSourceHashColumn(store);
    await _AppDriftSchemaMigrations.tryAddBalanceAfterColumn(store);
    await _AppDriftSchemaMigrations.tryAddTransactionTypeColumn(store);

    await store._db.runCustom(
      'CREATE TABLE IF NOT EXISTS tasks('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'title TEXT NOT NULL,'
      'description TEXT,'
      'completed INTEGER NOT NULL DEFAULT 0,'
      'due_at INTEGER,'
      'priority TEXT NOT NULL DEFAULT \'medium\','
      'reminder_enabled INTEGER NOT NULL DEFAULT 1,'
      'reminder_minutes_before INTEGER NOT NULL DEFAULT 30'
      ')',
    );
    await _AppDriftSchemaMigrations.tryAddTaskDescriptionColumn(store);
    await _AppDriftSchemaMigrations.tryAddTaskReminderEnabledColumn(store);
    await _AppDriftSchemaMigrations.tryAddTaskReminderMinutesColumn(store);
    await store._db.runCustom(
      'CREATE TABLE IF NOT EXISTS events('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'title TEXT NOT NULL,'
      'start_at INTEGER NOT NULL,'
      'end_at INTEGER,'
      'note TEXT,'
      'completed INTEGER NOT NULL DEFAULT 0,'
      'priority TEXT NOT NULL DEFAULT \'medium\','
      'event_type TEXT NOT NULL DEFAULT \'general\','
      'reminder_enabled INTEGER NOT NULL DEFAULT 1,'
      'reminder_minutes_before INTEGER NOT NULL DEFAULT 15'
      ')',
    );
    await _AppDriftSchemaMigrations.tryAddEventCompletedColumn(store);
    await _AppDriftSchemaMigrations.tryAddEventPriorityColumn(store);
    await _AppDriftSchemaMigrations.tryAddEventTypeColumn(store);
    await _AppDriftSchemaMigrations.tryAddEventReminderEnabledColumn(store);
    await _AppDriftSchemaMigrations.tryAddEventReminderMinutesColumn(store);
    await store._db.runCustom(
      'CREATE TABLE IF NOT EXISTS incomes('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'title TEXT NOT NULL,'
      'amount REAL NOT NULL,'
      'received_at INTEGER NOT NULL,'
      'source TEXT NOT NULL DEFAULT \'manual\''
      ')',
    );
    await store._db.runCustom(
      'CREATE TABLE IF NOT EXISTS budgets('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'category TEXT NOT NULL,'
      'monthly_limit REAL NOT NULL'
      ')',
    );
    await store._db.runCustom(
      'CREATE TABLE IF NOT EXISTS recurring_templates('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'kind TEXT NOT NULL,'
      'title TEXT NOT NULL,'
      'description TEXT,'
      'category TEXT,'
      'amount REAL,'
      'priority TEXT,'
      'cadence TEXT NOT NULL,'
      'next_run_at INTEGER NOT NULL,'
      'enabled INTEGER NOT NULL DEFAULT 1'
      ')',
    );
    await _AppDriftSchemaMigrations.tryAddIncomesSourceColumn(store);
    await _AppDriftSchemaMigrations.tryAddRecurringPriorityColumn(store);
    await store._db.runCustom(
      'CREATE TABLE IF NOT EXISTS sms_import_queue('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'scope TEXT NOT NULL,'
      'raw_message TEXT NOT NULL,'
      'source_hash TEXT NOT NULL,'
      'semantic_hash TEXT NOT NULL,'
      'source_timestamp INTEGER,'
      'status TEXT NOT NULL DEFAULT \'pending\','
      'route TEXT NOT NULL DEFAULT \'direct\','
      'confidence REAL NOT NULL DEFAULT 0,'
      'attempt INTEGER NOT NULL DEFAULT 0,'
      'next_retry_at INTEGER,'
      'created_at INTEGER NOT NULL,'
      'updated_at INTEGER NOT NULL,'
      'last_error TEXT'
      ')',
    );
    await _AppDriftSchemaMigrations.tryAddImportQueueSourceTimestampColumn(
      store,
    );
    await store._db.runCustom(
      'CREATE TABLE IF NOT EXISTS sms_import_audit('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'scope TEXT NOT NULL,'
      'source_hash TEXT NOT NULL,'
      'semantic_hash TEXT NOT NULL,'
      'route TEXT NOT NULL,'
      'confidence REAL NOT NULL,'
      'decision TEXT NOT NULL,'
      'status TEXT NOT NULL,'
      'attempt INTEGER NOT NULL DEFAULT 1,'
      'reason TEXT,'
      'payload TEXT,'
      'created_at INTEGER NOT NULL'
      ')',
    );
    await store._db.runCustom(
      'CREATE TABLE IF NOT EXISTS sms_review_queue('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'scope TEXT NOT NULL,'
      'source_hash TEXT NOT NULL,'
      'semantic_hash TEXT NOT NULL,'
      'title TEXT NOT NULL,'
      'category TEXT NOT NULL,'
      'amount REAL NOT NULL,'
      'occurred_at INTEGER NOT NULL,'
      'raw_message TEXT NOT NULL,'
      'confidence REAL NOT NULL,'
      'status TEXT NOT NULL DEFAULT \'pending\','
      'created_at INTEGER NOT NULL,'
      'resolved_at INTEGER'
      ')',
    );
    await store._db.runCustom(
      'CREATE TABLE IF NOT EXISTS sms_quarantine('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'scope TEXT NOT NULL,'
      'source_hash TEXT NOT NULL,'
      'semantic_hash TEXT NOT NULL,'
      'raw_message TEXT NOT NULL,'
      'reason TEXT NOT NULL,'
      'confidence REAL NOT NULL,'
      'status TEXT NOT NULL DEFAULT \'pending\','
      'created_at INTEGER NOT NULL'
      ')',
    );
    await store._db.runCustom(
      'CREATE TABLE IF NOT EXISTS paybill_registry('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'paybill TEXT NOT NULL,'
      'display_name TEXT NOT NULL,'
      'last_seen_at INTEGER NOT NULL,'
      'usage_count INTEGER NOT NULL DEFAULT 1'
      ')',
    );
    await store._db.runCustom(
      'CREATE TABLE IF NOT EXISTS merchant_categories('
      'merchant_key TEXT PRIMARY KEY,'
      'category TEXT NOT NULL,'
      'usage_count INTEGER NOT NULL DEFAULT 1,'
      'updated_at INTEGER NOT NULL'
      ')',
    );
    await store._db.runCustom(
      'CREATE TABLE IF NOT EXISTS fuliza_lifecycle_events('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'scope TEXT NOT NULL,'
      'mpesa_code TEXT NOT NULL,'
      'event_kind TEXT NOT NULL,'
      'amount REAL NOT NULL,'
      'occurred_at INTEGER NOT NULL,'
      'raw_message TEXT NOT NULL,'
      'linked_code TEXT,'
      'source_hash TEXT'
      ')',
    );
    await store._db.runCustom(
      'CREATE TABLE IF NOT EXISTS bills('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'name TEXT NOT NULL,'
      'amount REAL NOT NULL,'
      'due_date INTEGER NOT NULL,'
      'urgency TEXT NOT NULL DEFAULT \'medium\','
      'recurrence TEXT,'
      'paid INTEGER NOT NULL DEFAULT 0,'
      'created_at INTEGER NOT NULL'
      ')',
    );
    await store._db.runCustom(
      'CREATE TABLE IF NOT EXISTS loans('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'name TEXT NOT NULL,'
      'lender TEXT,'
      'total_amount REAL NOT NULL,'
      'outstanding_amount REAL NOT NULL,'
      'interest_rate REAL,'
      'start_date INTEGER,'
      'due_date INTEGER,'
      'status TEXT NOT NULL DEFAULT \'active\','
      'created_at INTEGER NOT NULL'
      ')',
    );
    await store._db.runCustom(
      'CREATE TABLE IF NOT EXISTS goals('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'title TEXT NOT NULL,'
      'target_amount REAL NOT NULL,'
      'current_amount REAL NOT NULL DEFAULT 0,'
      'deadline INTEGER,'
      'color TEXT,'
      'created_at INTEGER NOT NULL'
      ')',
    );
    await store._db.runCustom(
      'CREATE TABLE IF NOT EXISTS learning_sessions('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'topic TEXT NOT NULL,'
      'duration_minutes INTEGER NOT NULL,'
      'date INTEGER NOT NULL'
      ')',
    );
    await store._db.runCustom(
      'CREATE TABLE IF NOT EXISTS app_updates('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'platform TEXT NOT NULL DEFAULT \'android\','
      'current_version TEXT NOT NULL,'
      'minimum_supported_version TEXT,'
      'store_url TEXT,'
      'changelog TEXT,'
      'is_force INTEGER NOT NULL DEFAULT 0,'
      'active INTEGER NOT NULL DEFAULT 1,'
      'update_channel TEXT NOT NULL DEFAULT \'stable\','
      'created_at INTEGER NOT NULL'
      ')',
    );

    await store._db.runCustom(
      'CREATE TABLE IF NOT EXISTS task_time_entries('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'task_id INTEGER NOT NULL,'
      'started_at INTEGER,'
      'ended_at INTEGER,'
      'duration_sec INTEGER,'
      'note TEXT,'
      'FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE'
      ')',
    );
    await store._db.runCustom(
      'CREATE INDEX IF NOT EXISTS idx_time_entries_task ON task_time_entries(task_id)',
    );
    await store._db.runCustom(
      'CREATE INDEX IF NOT EXISTS idx_time_entries_started ON task_time_entries(started_at)',
    );

    await store._db.runCustom(
      'CREATE INDEX IF NOT EXISTS idx_tx_occurred_at ON transactions(occurred_at)',
    );
    await store._db.runCustom(
      'CREATE INDEX IF NOT EXISTS idx_tx_category ON transactions(category)',
    );
    await store._db.runCustom(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_tx_source_hash ON transactions(source_hash)',
    );
    await store._db.runCustom(
      'CREATE INDEX IF NOT EXISTS idx_tx_transaction_type ON transactions(transaction_type)',
    );
    await store._db.runCustom(
      'CREATE INDEX IF NOT EXISTS idx_tasks_completed ON tasks(completed)',
    );
    await store._db.runCustom(
      'CREATE INDEX IF NOT EXISTS idx_events_start_at ON events(start_at)',
    );
    await store._db.runCustom(
      'CREATE INDEX IF NOT EXISTS idx_incomes_received_at ON incomes(received_at)',
    );
    await store._db.runCustom(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_budgets_category ON budgets(LOWER(category))',
    );
    await store._db.runCustom(
      'CREATE INDEX IF NOT EXISTS idx_recurring_next_run_at ON recurring_templates(next_run_at)',
    );
    await store._db.runCustom(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_import_queue_scope_source_hash ON sms_import_queue(scope, source_hash)',
    );
    await store._db.runCustom(
      'CREATE INDEX IF NOT EXISTS idx_import_queue_status_due ON sms_import_queue(status, next_retry_at)',
    );
    await store._db.runCustom(
      'CREATE INDEX IF NOT EXISTS idx_import_queue_source_timestamp ON sms_import_queue(source_timestamp DESC)',
    );
    await store._db.runCustom(
      'CREATE INDEX IF NOT EXISTS idx_import_audit_scope_created ON sms_import_audit(scope, created_at DESC)',
    );
    await store._db.runCustom(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_review_scope_source_hash ON sms_review_queue(scope, source_hash)',
    );
    await store._db.runCustom(
      'CREATE INDEX IF NOT EXISTS idx_review_scope_status ON sms_review_queue(scope, status)',
    );
    await store._db.runCustom(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_quarantine_scope_source_hash ON sms_quarantine(scope, source_hash)',
    );
    await store._db.runCustom(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_paybill_value ON paybill_registry(paybill)',
    );
    await store._db.runCustom(
      'CREATE INDEX IF NOT EXISTS idx_merchant_categories_updated ON merchant_categories(updated_at DESC)',
    );
    await store._db.runCustom(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_fuliza_scope_code_kind ON fuliza_lifecycle_events(scope, mpesa_code, event_kind)',
    );
    await store._db.runCustom(
      'CREATE INDEX IF NOT EXISTS idx_bills_due_date ON bills(due_date)',
    );
    await store._db.runCustom(
      'CREATE INDEX IF NOT EXISTS idx_bills_paid ON bills(paid)',
    );
    await store._db.runCustom(
      'CREATE INDEX IF NOT EXISTS idx_loans_status ON loans(status)',
    );
    await store._db.runCustom(
      'CREATE INDEX IF NOT EXISTS idx_goals_deadline ON goals(deadline)',
    );
    await store._db.runCustom(
      'CREATE INDEX IF NOT EXISTS idx_learning_date ON learning_sessions(date)',
    );

    await _AppDriftSchemaMigrations.removeLegacySeedIncome(store);
    store._initialized = true;
  }

  static Future<void> seedDataIfEmpty(AppDriftStore store) =>
      _AppDriftSchemaMigrations.seedDataIfEmpty(store);
}
