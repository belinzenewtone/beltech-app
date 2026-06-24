# DART SUPERIORITY IMPLEMENTATION PLAN
## Goal: Make the DART/Flutter App Definitively Superior to the Kotlin Project in Every Category
> Date: 2026-03-23 | Based on: KOTLIN_vs_DART_AUDIT.md + AUDIT_REPORT.md

---

## CURRENT GAP SUMMARY

| Category | Kotlin Score | DART Score | Gap |
|---|---|---|---|
| Sync Infrastructure | 10/10 | 8/10 | DART lacks queue state machine + active-job dedup |
| Test Coverage | 10/10 | 6/10 | DART has zero widget tests, no migration chain tests |
| Code Quality Gates | 10/10 | 7/10 | No secret scanner, no architecture boundary enforcer |
| MpesaParser | 9.5/10 | 9.5/10 | Tied — DART needs 3-layer dedup + thread safety |
| Security | 9/10 | 8/10 | Silent catches, no automated secret scanner, no SQLCipher |
| Feature Completeness | 8/10 | 8/10 | Search nav, AI context, calendar swipe all missing |
| Accessibility | N/A (Android only) | 2/10 | Critical — will block App Store review |
| Logging / Observability | 5/10 | 3/10 | Both lack crash reporting; DART has silent catches |

**Target after this plan: DART 10/10 in every category, 3–4 points ahead of Kotlin across the board.**

---

## PHASES AT A GLANCE

| Phase | Theme | Duration | Outcome |
|---|---|---|---|
| **Phase 1** | Stability & Logging Foundation | 3 days | Silent catches eliminated, logging live, entity equality fixed |
| **Phase 2** | Feature Completeness | 4 days | All AUDIT_REPORT gaps closed |
| **Phase 3** | Sync Superiority | 4 days | Typed sync state machine surpasses Kotlin sync |
| **Phase 4** | MpesaParser Supremacy | 3 days | 3-layer dedup, thread-safe, 150+ regression tests |
| **Phase 5** | Test Coverage Dominance | 5 days | 80+ test files, widget tests, migration chain, CI/CD |
| **Phase 6** | Security & Code Quality Gates | 3 days | Secret scanner, arch gate, SQLCipher, crash reporting |
| **Phase 7** | Scale & Performance Hardening | 3 days | Materialized views, profiling, deep linking, feature flags |
| **Total** | | **~25 days** | DART clearly superior in all 8 categories |

---

## PHASE 1 — STABILITY & LOGGING FOUNDATION
**Duration: 3 days | Priority: CRITICAL**

These are blocking issues that make production diagnosis impossible and cause silent data loss.

---

### 1.1 Add Structured Logging (`AppLogger`)

**Why:** Silent `catch (_) { return 0; }` blocks in `SmsAutoImportService`, `NotificationInsightsService`, and several repositories make production failures invisible. Kotlin has no logging either — this immediately puts DART ahead.

**Files to create/edit:**
- `lib/core/logger/app_logger.dart` ← new singleton using `logger: ^2.x`
- `lib/core/logger/riverpod_log_observer.dart` ← ProviderObserver for debug state tracing
- `lib/core/di/bootstrap_providers.dart` ← register observer
- `lib/core/sync/sms_auto_import_service.dart` ← replace silent catches
- `lib/core/notifications/notification_insights_service.dart` ← replace silent catches
- Every repository `catch` block ← replace with `AppLogger.error(...)`

**Implementation:**
```dart
// lib/core/logger/app_logger.dart
import 'package:logger/logger.dart';

class AppLogger {
  static final _logger = Logger(
    printer: PrettyPrinter(methodCount: 2, errorMethodCount: 8),
    filter: kReleaseMode ? ProductionFilter() : DevelopmentFilter(),
  );

  static void debug(String msg, [Object? error]) => _logger.d(msg, error: error);
  static void info(String msg, [Object? error]) => _logger.i(msg, error: error);
  static void warning(String msg, [Object? error]) => _logger.w(msg, error: error);
  static void error(String msg, [Object? error, StackTrace? stack]) =>
      _logger.e(msg, error: error, stackTrace: stack);
}
```

**Rule added to CODING_RULES.md:** Silent `catch` blocks are forbidden — all exceptions must be passed to `AppLogger.error(...)`.

**Acceptance:** `grep -r "catch (_)" lib/` returns 0 results.

---

### 1.2 Fix Domain Entity Immutability (`freezed`)

**Why:** Riverpod cannot diff `TaskItem`, `ExpenseItem`, `BudgetTarget`, `CalendarEvent`, or `IncomeItem` because they have no `==` overrides. Every stream emission triggers full widget subtree rebuilds. Kotlin's entities use Kotlin data classes (auto-equality). DART currently rebuilds unnecessarily on every identical value.

**Files to create/edit:**
- `pubspec.yaml` ← add `freezed: ^2.5.x`, `freezed_annotation: ^2.4.x`, `build_runner: ^2.x`
- `lib/domain/entities/task_item.dart` ← convert to `@freezed`
- `lib/domain/entities/expense_item.dart` ← convert to `@freezed`
- `lib/domain/entities/income_item.dart` ← convert to `@freezed`
- `lib/domain/entities/budget_target.dart` ← convert to `@freezed`
- `lib/domain/entities/calendar_event.dart` ← convert to `@freezed`
- `lib/domain/entities/recurring_template.dart` ← convert to `@freezed`

**Pattern:**
```dart
@freezed
class TaskItem with _$TaskItem {
  const factory TaskItem({
    required String id,
    required String title,
    required bool completed,
    DateTime? dueAt,
    required TaskPriority priority,
  }) = _TaskItem;
}
```

**Side effects:** All `copyWith` calls across the codebase work automatically. Riverpod diffs correctly — unnecessary rebuilds eliminated.

**Acceptance:** Run `flutter test` — no rebuild-related test regressions. Entity equality assertions pass.

---

### 1.3 Fix All Date Formatting (Replace Hand-Written Strings with `intl`)

**Why:** `'${tx.occurredAt.month}/${tx.occurredAt.day}'` is ambiguous and locale-incorrect. `intl` is already installed. Kotlin uses standard date formatters throughout.

**Files to edit:**
- `lib/features/expenses/presentation/widgets/expenses_snapshot_content.dart`
- `lib/features/income/presentation/screens/income_screen.dart`
- `lib/features/recurring/presentation/screens/recurring_screen.dart`
- Any other file with raw `DateTime.month` / `DateTime.day` string interpolation

**Pattern:** Replace all occurrences with:
```dart
DateFormat('MMM d, HH:mm').format(tx.occurredAt)   // "Mar 4, 14:30"
DateFormat('MMM yyyy').format(date)                  // "Mar 2026"
DateFormat('EEE, MMM d').format(date)                // "Mon, Mar 4"
```

**Acceptance:** `grep -rn "occurredAt.month" lib/` and `grep -rn "occurredAt.day" lib/` return 0 results.

---

### 1.4 Add `AppVersion` to Settings Screen

**Why:** Required for App Store and Play Store compliance. Users need it to report bugs. Kotlin doesn't have it either — another DART first.

**Files to edit:**
- `lib/features/settings/presentation/screens/settings_screen.dart`

**Implementation:** Use `package_info_plus` (already installed):
```dart
final info = await PackageInfo.fromPlatform();
// Render: "BELTECH v2.0.0 (build 5)"
```

Add an **"About & Account"** section at the bottom with:
- App version + build number
- "Delete Account" action (required for App Store compliance)
- "Send Feedback" link

---

## PHASE 2 — FEATURE COMPLETENESS
**Duration: 4 days | Priority: HIGH**

Close every gap from `AUDIT_REPORT.md` section 1. After this phase, DART has more complete features than the Kotlin project.

---

### 2.1 Search Results Tap-Through Navigation

**Why:** Results render but tapping does nothing. Kotlin's search navigates correctly. This is a functional regression.

**Files to edit:**
- `lib/domain/entities/global_search_result.dart` ← add `featureType` and `itemId` fields
- `lib/features/search/presentation/screens/search_screen.dart` ← wire `onTap` per result type
- `lib/core/routing/app_router.dart` ← verify destination routes accept item ID params

**Navigation targets per result type:**
- Expense → `ExpensesScreen` pre-filtered or expense detail sheet
- Task → `TasksScreen` with item highlighted
- Event → `CalendarScreen` with date focused
- Income → `IncomeScreen`
- Budget → `BudgetScreen` scrolled to category
- Recurring → `RecurringScreen`

**Acceptance:** Tap any search result → navigates to correct screen. Back button returns to search.

---

### 2.2 AI Assistant — Live Data Context Injection

**Why:** The assistant cannot answer "How much did I spend this week?" — the context parameter is unpopulated. This is the highest-leverage AI improvement. Kotlin's assistant uses a similar proxy with partial context. DART will go further.

**Files to edit:**
- `lib/features/assistant/data/services/assistant_proxy_service.dart` ← build rich context string
- `lib/features/assistant/presentation/providers/assistant_providers.dart` ← inject live data
- `lib/features/home/presentation/providers/home_providers.dart` ← expose snapshot to assistant

**Context payload to inject (build before each message):**
```dart
String buildAssistantContext(HomeOverviewSnapshot snap, UserProfile profile) => '''
User: ${profile.name}
Today's spend: KES ${snap.todaySpend}
This week's spend: KES ${snap.weekSpend}
This month's spend: KES ${snap.monthSpend}
Budget remaining: KES ${snap.budgetRemaining}
Pending tasks: ${snap.pendingTaskCount}
Upcoming events: ${snap.upcomingEvents.take(3).map((e) => e.title).join(', ')}
Top category this month: ${snap.topCategory}
''';
```

**Acceptance:** Ask "How much did I spend today?" → assistant returns actual figure from user's data.

---

### 2.3 Calendar — Swipe Month Navigation + Agenda View

**Why:** No swipe gestures and no agenda view. Kotlin also lacks these. DART will be first.

**Files to edit:**
- `lib/features/calendar/presentation/screens/calendar_screen.dart`
- `lib/features/calendar/presentation/widgets/calendar_month_grid.dart` ← wrap in PageView

**Swipe navigation:**
```dart
PageView.builder(
  controller: _pageController,
  onPageChanged: (index) => ref.read(calendarMonthProvider.notifier).setMonth(index),
  itemBuilder: (context, index) => CalendarMonthGrid(month: indexToMonth(index)),
)
```

**Agenda view:** Add a toggle chip `Month | Agenda` in the app bar.
- Agenda view = `ListView` of upcoming events sorted by start_at, grouped by date
- Reuses `CalendarEventDot` and colour-coded event type system already in place

**Files to create:**
- `lib/features/calendar/presentation/widgets/calendar_agenda_view.dart`

**Acceptance:** Swipe left/right changes month with smooth animation. Agenda tab shows upcoming events chronologically.

---

### 2.4 Recurring Templates — Edit Action

**Why:** Delete exists, edit does not. Every other list in the app has edit. Users cannot correct next-run dates or amounts without deleting and recreating.

**Files to edit:**
- `lib/features/recurring/presentation/widgets/recurring_row.dart` ← add edit trailing icon
- `lib/features/recurring/presentation/screens/recurring_screen.dart` ← wire `onEdit` to dialog

**Pattern:** Mirror the income edit flow:
```dart
IconButton(
  icon: const Icon(Icons.edit_outlined),
  onPressed: () => showRecurringTemplateDialog(context, ref, existing: template),
)
```

**Acceptance:** Tapping edit on a recurring row opens the create dialog pre-populated. Saving updates the template in DB. No new template is created.

---

### 2.5 Budget — Progress Bars on Category Target Rows

**Why:** `BudgetTarget` rows show name and limit only. `BudgetSnapshot.items` already contains `spentKes` and `usageRatio` per category — the data exists, just not plumbed.

**Files to edit:**
- `lib/features/budget/presentation/widgets/budget_target_row.dart` ← add `LinearProgressIndicator`
- `lib/features/budget/presentation/screens/budget_screen.dart` ← pass `spentKes` to row

**Pattern:**
```dart
LinearProgressIndicator(
  value: usageRatio.clamp(0.0, 1.0),
  color: usageRatio >= 1.0 ? AppColors.errorRed : AppColors.accentBlue,
  backgroundColor: AppColors.surface,
)
```

**Acceptance:** Each budget category row shows current spend, limit, and colour-coded progress bar.

---

### 2.6 Budget Summary Card — "Show All" Expansion

**Why:** `.take(6)` silently discards categories 7+. Users with many categories cannot see all of them.

**Files to edit:**
- `lib/features/budget/presentation/widgets/budget_summary_card.dart`

**Pattern:** Copy the "Show all transactions (N)" toggle already implemented in home screen.

---

### 2.7 Income Screen — Trend Chart + Net Cashflow Card

**Why:** Income screen is a flat list with no insight. No comparison against expenses. No net cashflow figure.

**Files to create/edit:**
- `lib/features/income/presentation/widgets/income_trend_chart.dart` ← reuse `AnalyticsTrendChart`
- `lib/features/income/presentation/widgets/net_cashflow_card.dart` ← income − expenses this month
- `lib/features/income/presentation/screens/income_screen.dart` ← add both widgets above the list

**Net cashflow calculation:** Pull from `homeOverviewProvider` (month spend) and `incomeSummaryProvider` (month total). Display delta with green/red colour coding.

**Acceptance:** Income screen shows a monthly trend line and a net cashflow KPI card at the top.

---

### 2.8 Export — Share Sheet

**Why:** File is saved to a sandboxed directory users cannot access. `share_plus` is the standard Flutter solution. This feature is currently broken for most users.

**Files to edit:**
- `pubspec.yaml` ← add `share_plus: ^10.x`
- `lib/features/export/presentation/screens/export_screen.dart` ← trigger `Share.shareXFiles(...)` after successful write

**Implementation:**
```dart
await Share.shareXFiles(
  [XFile(result.filePath)],
  subject: 'BELTECH Export — ${DateFormat('MMM yyyy').format(DateTime.now())}',
);
```

**Acceptance:** After export completes, OS share sheet appears. User can send to WhatsApp, email, Drive, etc.

---

### 2.9 Accessibility — Semantics Labels

**Why:** Zero Semantics usage currently. Will block App Store review. Kotlin is Android-only so this is a DART-exclusive win.

**Files to edit (minimum viable):**
- `lib/features/assistant/presentation/widgets/assistant_input_bar.dart` ← send button Semantics
- `lib/features/profile/presentation/widgets/profile_avatar.dart` ← camera button Semantics
- `lib/features/tasks/presentation/widgets/task_item_card.dart` ← swipe backgrounds Semantics
- `lib/features/expenses/presentation/widgets/expenses_snapshot_content.dart` ← filter chips
- All icon-only `IconButton` widgets ← add `tooltip:` parameter

**Pattern:**
```dart
Semantics(
  label: 'Send message to assistant',
  button: true,
  child: IconButton(icon: const Icon(Icons.send), onPressed: onSend),
)
```

**Acceptance:** Enable TalkBack on Android — all interactive elements announce meaningful labels.

---

### 2.10 Custom Font — DM Sans via `google_fonts`

**Why:** System default (Roboto/SF Pro) does not match the glassmorphism aesthetic. Two-line change, major visual upgrade.

**Files to edit:**
- `pubspec.yaml` ← add `google_fonts: ^6.x`
- `lib/core/theme/app_theme.dart` ← apply `GoogleFonts.dmSansTextTheme()`

**Implementation:**
```dart
ThemeData darkTheme = ThemeData.dark().copyWith(
  textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme),
);
```

**Acceptance:** App renders with DM Sans on both Android and iOS.

---

## PHASE 3 — SYNC SUPERIORITY
**Duration: 4 days | Priority: HIGH**

This is the category where DART currently scores 8/10 vs Kotlin's 10/10. The plan: build a sync queue state machine that surpasses Kotlin's and add three features Kotlin doesn't have.

---

### 3.1 Typed Sync Queue State Machine

**Why:** Kotlin has a dedicated `sync_jobs` table with typed status: `QUEUED → SYNCING → SYNCED / FAILED / CONFLICT`. DART uses simpler queue tracking. To be superior, DART needs the same typed machine plus additional states.

**New states (goes beyond Kotlin):**
```
QUEUED → SYNCING → SYNCED
                 → FAILED → RETRY_SCHEDULED
                 → CONFLICT → RESOLVED (via conflict resolution)
                 → CANCELLED (user-triggered or superseded)
```

**Files to create:**
- `lib/data/local/drift/sync_jobs_table.dart` ← Drift table definition
- `lib/core/sync/sync_job_entity.dart` ← typed entity
- `lib/core/sync/sync_queue_store.dart` ← CRUD + active-job dedup
- `lib/core/sync/sync_conflict_resolver.dart` ← last-write-wins + client-first strategy
- `lib/core/sync/sync_backoff_policy.dart` ← exponential 1s→1h, capped

**Schema addition (Drift migration v2):**
```dart
class SyncJobsTable extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()(); // "transaction", "task", "event", etc.
  TextColumn get entityId => text()();
  TextColumn get jobType => text()(); // PUSH, PULL, REPAIR
  TextColumn get status => text()(); // QUEUED, SYNCING, SYNCED, FAILED, CONFLICT, CANCELLED
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  TextColumn get error => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
```

**Active-job deduplication (DART advantage beyond Kotlin):**
Before enqueuing, check: if a `QUEUED` or `SYNCING` job for the same `(entityType, entityId, jobType)` exists, skip enqueue. This prevents thundering-herd on reconnection for 50k users.

**Conflict resolution strategy:**
```dart
// sync_conflict_resolver.dart
ConflictResolution resolve(SyncJobEntity job, RemoteRecord remote, LocalRecord local) {
  if (local.updatedAt.isAfter(remote.updatedAt)) return ConflictResolution.keepLocal;
  if (remote.updatedAt.isAfter(local.updatedAt)) return ConflictResolution.applyRemote;
  return ConflictResolution.keepLocal; // tie-break: client-first
}
```

**Acceptance:** Sync queue table exists in Drift v2. Status transitions are logged via `AppLogger`. Active-job dedup verified in unit tests.

---

### 3.2 Battery-Aware Sync Scheduling (DART-exclusive)

**Why:** Kotlin uses WorkManager which respects Doze/Standby. DART's `workmanager` can do the same but it's not configured with constraints. This makes DART better than Kotlin for battery life at scale.

**Files to edit:**
- `lib/core/sync/background_sync_coordinator.dart`

**Add WorkManager constraints:**
```dart
Workmanager().registerPeriodicTask(
  'cloudSync',
  'cloudSyncTask',
  frequency: const Duration(minutes: 20),
  constraints: Constraints(
    networkType: NetworkType.connected,
    requiresBatteryNotLow: true,         // skip if battery < 15%
    requiresDeviceIdle: false,           // don't require idle (too restrictive)
  ),
);
```

**Acceptance:** Sync does not run when battery is critically low. Verified in integration test with mock connectivity state.

---

### 3.3 Circuit Breaker for Cloud Failures (DART-exclusive)

**Why:** Neither project currently has a circuit breaker. If Supabase goes down, naive retry loops hammer the endpoint. DART will implement a half-open circuit breaker — another feature beyond Kotlin.

**Files to create:**
- `lib/core/sync/sync_circuit_breaker.dart`

**Logic:**
- CLOSED (normal): allow all requests
- OPEN (tripped after 5 consecutive failures): block requests for 60 seconds
- HALF_OPEN (after cooldown): allow 1 probe request; if success → CLOSED; if fail → OPEN again

**Integration point:** `BackgroundSyncCoordinator` checks circuit state before each sync cycle.

**Acceptance:** Unit test: simulate 5 failures → circuit opens → probe after 60s → closes on success.

---

### 3.4 Sync Status UI (DART-exclusive)

**Why:** Neither project shows sync status to the user. DART will add a subtle sync indicator, giving users confidence that their data is safe.

**Files to create/edit:**
- `lib/core/sync/sync_status_provider.dart` ← exposes `SyncStatus` (syncing / synced / error / offline)
- `lib/presentation/app_shell.dart` ← show a 4px status bar at the top (green=synced, amber=syncing, red=error, grey=offline)

**Acceptance:** Status bar visible. Changes state reactively as sync runs.

---

## PHASE 4 — MPESA PARSER SUPREMACY
**Duration: 3 days | Priority: HIGH**

Currently tied with Kotlin. After this phase, DART's parser will be unambiguously superior.

---

### 4.1 Add Third Deduplication Layer (Time-Window)

**Why:** Kotlin has 3 dedup layers (MPESA code + semantic hash + amount/merchant/5-minute window). DART has 2 (source hash + semantic hash). The time-window layer prevents edge cases where the same real-world transaction generates two slightly different SMS messages (e.g., network retry from Safaricom).

**Files to edit:**
- `lib/features/expenses/data/repositories/expenses_repository_impl_import_pipeline.dart`

**Implementation:**
```dart
Future<bool> _isTimeWindowDuplicate(ParsedTransaction tx) async {
  final window = tx.occurredAt.subtract(const Duration(minutes: 5));
  final matches = await _db.findTransactionsInWindow(
    amount: tx.amountKes,
    merchant: tx.title.toLowerCase(),
    from: window,
    to: tx.occurredAt.add(const Duration(minutes: 5)),
  );
  return matches.isNotEmpty;
}
```

**Acceptance:** Unit test: two SMS messages for same KES 500 payment to same merchant within 3 minutes → second is rejected. Messages 6 minutes apart with same amount/merchant → both accepted.

---

### 4.2 Thread Safety Testing

**Why:** Kotlin explicitly tests `MpesaParserThreadSafetyTest`. DART does not. At 50k users, background SMS workers may parse concurrently.

**Files to create:**
- `test/features/expenses/data/services/mpesa_parser_thread_safety_test.dart`

**Test cases:**
```dart
test('concurrent parsing of 100 messages produces no race conditions', () async {
  final parser = MpesaParserService();
  final messages = List.generate(100, (i) => kMpesaFixtures.received[i % 10]);
  final results = await Future.wait(messages.map((m) => Future(() => parser.parseSingle(m))));
  expect(results.where((r) => r != null).length, greaterThan(80));
});
```

---

### 4.3 Expand Regression Test Suite to 150+ Cases

**Why:** Kotlin has 100+ regression cases across 8 test classes. DART needs to match and exceed this.

**Files to create/edit:**
- `test/features/expenses/data/services/mpesa_parser_fixtures.dart` ← 150 canonical SMS samples
- `test/features/expenses/data/services/mpesa_parser_service_test.dart` ← expand to all 11 types
- `test/features/expenses/data/services/mpesa_dedupe_engine_test.dart` ← 3-layer dedup test class
- `test/features/expenses/data/services/mpesa_semantic_hash_test.dart` ← hash collision tests
- `test/features/expenses/data/services/mpesa_fuliza_lifecycle_test.dart` ← draw + repayment linking

**Coverage requirements:**
- All 11 transaction types × 5 variants each = 55 type tests
- Dedup: exact, semantic, time-window, cross-device = 20 dedup tests
- Confidence routing: high/medium/low × 5 cases each = 15 confidence tests
- Edge cases: Swahili characters, missing fields, malformed SMS = 30 edge cases
- Fuliza lifecycle linking = 15 lifecycle tests
- Thread safety concurrent tests = 15 concurrent tests
- **Total: 150+ cases**

---

### 4.4 Add Safaricom Message Variant Normalizer

**Why:** Safaricom occasionally changes their SMS templates. Kotlin handles this via `MpesaParserEnhanced.kt` for regional variants. DART should add equivalent normalization for robustness.

**Files to create:**
- `lib/features/expenses/data/services/mpesa_message_normalizer.dart`

**Responsibilities:**
- Normalize Unicode apostrophes to ASCII
- Strip promotional footers Safaricom sometimes appends
- Handle both old-format (no decimal) and new-format (with decimals) amount strings
- Normalize "M-PESA" / "MPESA" / "Mpesa" variations

**Integration:** Called first in the parsing pipeline before classification.

---

## PHASE 5 — TEST COVERAGE DOMINANCE
**Duration: 5 days | Priority: HIGH**

Currently 37 test files, zero widget tests. Target: 80+ test files including widget/integration tests, full migration chain validation, and CI/CD pipeline.

---

### 5.1 Widget Tests for Core Flows

**Why:** Kotlin has navigation guard tests and UI tests. DART has zero widget tests — biggest quality gap.

**Files to create:**
```
test/presentation/
  auth_gate_test.dart          ← unauthenticated → login, authenticated → shell
  app_shell_test.dart          ← tab switching, biometric relock trigger

test/features/tasks/presentation/
  task_item_card_test.dart     ← priority colour, swipe-complete, swipe-delete
  tasks_screen_test.dart       ← empty state, list render, add task flow

test/features/expenses/presentation/
  expenses_screen_test.dart    ← filter chips, transaction list render
  mpesa_import_flow_test.dart  ← import button → review queue → approve → appears in list

test/features/assistant/presentation/
  assistant_screen_test.dart   ← send message → loading state → reply renders

test/features/home/presentation/
  home_screen_test.dart        ← greeting personalisation, summary card values

test/features/calendar/presentation/
  calendar_screen_test.dart    ← month grid render, swipe navigation, event dots

test/features/budget/presentation/
  budget_screen_test.dart      ← progress bars, category targets, overspend colour

test/features/settings/presentation/
  settings_screen_test.dart    ← theme toggle, version display, biometric toggle
```

**Testing pattern:**
```dart
testWidgets('TaskItemCard shows priority badge with correct colour', (tester) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [...],
    child: MaterialApp(home: TaskItemCard(task: urgentTask, onDelete: () {}, onToggle: () {})),
  ));
  expect(find.text('Urgent'), findsOneWidget);
  final badge = tester.widget<Container>(find.byKey(const Key('priority_badge')));
  expect((badge.decoration as BoxDecoration).color, AppColors.errorRed);
});
```

---

### 5.2 Supabase Repository Tests

**Why:** All 13 current repository tests cover only local (Drift) implementations. Cloud (Supabase) repositories are untested.

**Files to create:**
```
test/features/expenses/data/repositories/expenses_supabase_repository_test.dart
test/features/tasks/data/repositories/tasks_supabase_repository_test.dart
test/features/budget/data/repositories/budget_supabase_repository_test.dart
test/features/income/data/repositories/income_supabase_repository_test.dart
test/features/recurring/data/repositories/recurring_supabase_repository_test.dart
```

**Pattern:** Mock `SupabaseClient` with mocktail. Test CRUD operations, RLS enforcement (wrong owner_id returns empty), and error handling.

---

### 5.3 Drift Schema Migration Chain Tests

**Why:** Kotlin tests Room v1→v14 full chain. DART has schema v1 only with forward migration blocks — no chain is tested. When v2 is added (sync_jobs table in Phase 3), this must be tested.

**Files to create:**
- `test/data/local/drift/migration_test.dart`

**Coverage:**
- v1 schema creates all 11 tables correctly
- v1 → v2 migration adds `sync_jobs` table without data loss
- Existing records survive migration (destructive migration check)
- All indices exist post-migration

**Tool:** Use `drift_dev`'s `SchemaVerifier` for declarative migration testing.

---

### 5.4 Sync Infrastructure Tests

**Files to create:**
```
test/core/sync/sync_queue_store_test.dart          ← enqueue, dedup, status transitions
test/core/sync/sync_conflict_resolver_test.dart    ← all conflict resolution branches
test/core/sync/sync_backoff_policy_test.dart       ← exponential timing, cap, jitter
test/core/sync/sync_circuit_breaker_test.dart      ← open/half-open/close transitions
test/core/sync/background_sync_coordinator_test.dart ← full coordinator lifecycle
```

---

### 5.5 CI/CD Pipeline (GitHub Actions)

**Why:** Neither project has CI/CD. DART will have it first — every PR validated automatically.

**File to create:** `.github/workflows/ci.yml`

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.6'
          channel: stable
      - run: flutter pub get
      - run: flutter analyze --fatal-infos
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v4

  build-android:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build apk --release --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}

  build-ios:
    runs-on: macos-latest
    needs: test
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build ios --release --no-codesign
```

**Acceptance:** PRs blocked from merging if tests fail. Coverage report posted to PR comments.

---

## PHASE 6 — SECURITY & CODE QUALITY GATES
**Duration: 3 days | Priority: HIGH**

After this phase, DART's security posture and quality automation surpass Kotlin's.

---

### 6.1 Automated Secret Scanner

**Why:** Kotlin has `scripts/secret_scan.ps1` that blocks builds if secrets are found. DART has no equivalent — relies on convention alone.

**Files to create:**
- `scripts/secret_scan.sh` ← cross-platform bash (works on GitHub Actions)
- `scripts/secret_scan.ps1` ← Windows equivalent for local dev

```bash
#!/bin/bash
# secret_scan.sh — fails with exit code 1 if secrets detected in lib/ or test/
PATTERNS=(
  "supabase_url\s*=\s*['\"]https"
  "supabase_anon_key\s*=\s*['\"]eyJ"
  "openai_api_key"
  "sk-[a-zA-Z0-9]{48}"
  "AIzaSy[0-9A-Za-z_-]{33}"
  "AAAA[A-Za-z0-9_-]{7}:[A-Za-z0-9_-]{140}"
)
FOUND=0
for p in "${PATTERNS[@]}"; do
  if grep -rniE "$p" lib/ test/ 2>/dev/null; then
    echo "SECRET DETECTED: $p"
    FOUND=1
  fi
done
exit $FOUND
```

**Integration:** Add as a step in `.github/workflows/ci.yml` before build.

**Acceptance:** Temporarily add a fake API key to a test file → CI fails → remove it → CI passes.

---

### 6.2 Architecture Boundary Checker Script

**Why:** Kotlin has a PowerShell script that blocks UI imports of Room/HTTP at build time. DART enforces this by convention only. An automated check makes it enforceable in CI.

**Files to create:**
- `scripts/architecture_check.sh`

```bash
#!/bin/bash
# Ensure no presentation layer imports data layer directly
VIOLATIONS=$(grep -rn "package:beltech/data/" lib/features/*/presentation/ lib/presentation/)
if [ -n "$VIOLATIONS" ]; then
  echo "ARCHITECTURE VIOLATION: Presentation layer directly imports data layer:"
  echo "$VIOLATIONS"
  exit 1
fi

# Ensure no feature imports another feature's data layer
CROSS_FEATURE=$(grep -rn "features/[a-z_]*/data/" lib/features/ | grep -v "features/\([a-z_]*\)/.*\1/data/")
if [ -n "$CROSS_FEATURE" ]; then
  echo "CROSS-FEATURE VIOLATION: Feature imports another feature's data layer:"
  echo "$CROSS_FEATURE"
  exit 1
fi
echo "Architecture boundaries OK."
```

**Integration:** Added to CI pipeline before tests.

---

### 6.3 SQLCipher — Database Encryption at Rest

**Why:** Neither project encrypts the local database. DART will be first. Adds a meaningful security advantage for users in enterprise/MDM environments.

**Package:** `drift` supports `NativeDatabase.createInBackground` with `sqlite3_flutter_libs`. For encryption, use `sqflite_sqlcipher` or the `drift` + `sqlcipher_flutter_libs` combination.

**Files to edit:**
- `pubspec.yaml` ← add `sqlcipher_flutter_libs: ^0.5.x`
- `lib/data/local/drift/app_drift_store.dart` ← switch to encrypted connection

**Implementation:**
```dart
// Use SQLCipher-backed Drift database
LazyDatabase openEncryptedDatabase() {
  return LazyDatabase(() async {
    final dbPath = await getDatabasePath('beltech.db');
    final file = File(dbPath);
    final key = await _loadOrGenerateDatabaseKey();
    return NativeDatabase(file, setup: (db) {
      db.execute("PRAGMA key = '$key'");
    });
  });
}

Future<String> _loadOrGenerateDatabaseKey() async {
  const storage = FlutterSecureStorage();
  var key = await storage.read(key: 'db_encryption_key');
  if (key == null) {
    key = base64Url.encode(List<int>.generate(32, (_) => Random.secure().nextInt(256)));
    await storage.write(key: 'db_encryption_key', value: key);
  }
  return key;
}
```

**Key management:** Key generated once, stored in `FlutterSecureStorage` (Android KeyStore / iOS Keychain). Key never leaves the device.

**Acceptance:** `strings beltech.db | grep "KES"` returns nothing (data is encrypted). App functions identically after this change.

---

### 6.4 Crash Reporting — Sentry Integration

**Why:** Neither project has crash reporting. DART will be first. This is essential for diagnosing production failures at 50k users.

**Files to edit:**
- `pubspec.yaml` ← add `sentry_flutter: ^8.x`
- `lib/main.dart` ← wrap app in `SentryFlutter.init`
- `lib/core/logger/app_logger.dart` ← send errors to Sentry via `Sentry.captureException`

**Implementation:**
```dart
await SentryFlutter.init(
  (options) {
    options.dsn = const String.fromEnvironment('SENTRY_DSN');
    options.tracesSampleRate = 0.1; // 10% of transactions
    options.environment = kReleaseMode ? 'production' : 'development';
    options.beforeSend = (event, hint) {
      // Scrub PII — never send personal financial data
      return event.copyWith(user: null);
    };
  },
  appRunner: () => runApp(ProviderScope(child: const BeltechApp())),
);
```

**Privacy rule:** `beforeSend` hook strips user identity and never includes transaction amounts or names in error reports.

---

### 6.5 Feature Flags with Kill-Switch (Beyond Kotlin)

**Why:** Kotlin's feature flags are minimal (local cache, no kill-switch framework). DART will build proper remote kill-switches and rollout groups.

**Files to edit:**
- `supabase/schema.sql` ← add `rollout_percentage` column to `feature_flags` table
- `lib/core/feature_flags/feature_flag_store.dart` ← add `isEnabledFor(userId)` with rollout %
- `lib/core/feature_flags/feature_flag_remote_source.dart` ← refresh on app start

**Schema addition:**
```sql
ALTER TABLE feature_flags ADD COLUMN rollout_percentage INTEGER DEFAULT 100;
-- 0 = off for all, 100 = on for all, 50 = on for ~50% of users (hash-based)
```

**Hash-based rollout:**
```dart
bool isEnabledFor(String userId, FeatureFlag flag) {
  final hash = userId.hashCode.abs() % 100;
  return hash < flag.rolloutPercentage;
}
```

**Acceptance:** Set a feature to 0% → it's disabled for all users. Set to 50% → ~50% of user IDs see it. Kill-switch works within 60 seconds (next feature flag refresh).

---

## PHASE 7 — SCALE & PERFORMANCE HARDENING
**Duration: 3 days | Priority: MEDIUM**

Prepares the DART app for 100k+ users and closes the final performance gaps.

---

### 7.1 ShellRoute Deep Linking

**Why:** Current `AppShell` with 6 tabs is not expressed as go_router `ShellRoute` — deep links cannot target specific tabs. Needed for notification-driven navigation (e.g., "You have 3 overdue tasks" → opens Tasks tab directly).

**Files to edit:**
- `lib/core/routing/app_router.dart` ← convert tabs to `ShellRoute` children
- `lib/presentation/app_shell.dart` ← align shell with ShellRoute structure

**Route structure:**
```dart
ShellRoute(
  builder: (context, state, child) => AppShell(child: child),
  routes: [
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
    GoRoute(path: '/expenses', builder: (_, __) => const ExpensesScreen()),
    GoRoute(path: '/tasks', builder: (_, __) => const TasksScreen()),
    GoRoute(path: '/assistant', builder: (_, __) => const AssistantScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
  ],
)
```

**Acceptance:** Push notification tap with payload `{"route": "/tasks"}` opens Tasks tab directly.

---

### 7.2 Analytics Materialized View (Supabase)

**Why:** At 100k+ users, `GROUP BY category` queries will slow down. A Supabase materialized view pre-computes monthly aggregates. Neither project has this — DART will be first.

**Files to create:**
- `supabase/migrations/v10_analytics_materialized_view.sql`

```sql
CREATE MATERIALIZED VIEW monthly_spending_by_category AS
SELECT
  owner_id,
  DATE_TRUNC('month', occurred_at) AS month,
  category,
  SUM(amount_kes) AS total_spent,
  COUNT(*) AS transaction_count
FROM transactions
GROUP BY owner_id, DATE_TRUNC('month', occurred_at), category;

CREATE UNIQUE INDEX ON monthly_spending_by_category (owner_id, month, category);

-- Refresh function (called by pg_cron every hour)
CREATE OR REPLACE FUNCTION refresh_spending_views()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY monthly_spending_by_category;
END;
$$ LANGUAGE plpgsql;
```

**Client change:** `AnalyticsRepository` queries `monthly_spending_by_category` view instead of raw `transactions` table for the category breakdown widget.

---

### 7.3 Flutter Performance Profiling Pass

**Why:** CODING_RULE CR-13 requires <1.5s startup, but this has never been measured.

**Tasks:**
1. Run `flutter run --profile` and capture DevTools timeline
2. Measure time-to-first-frame (target: <800ms)
3. Identify top 3 Jank sources in Widget rebuild profiler
4. Fix identified rebuilds (const constructors, `select` on Riverpod, `RepaintBoundary` on charts)

**Files to edit:** Based on profiling results (not predetermined).

**Acceptance:** DevTools timeline shows no frames exceeding 16ms budget on mid-range device. Time-to-first-frame documented in `PERFORMANCE_REPORT.md`.

---

### 7.4 go_router Tab-Level Deep Link from Notifications

**Why:** Extension of 7.1 — notification taps should land users on the correct tab with the correct item context.

**Files to edit:**
- `lib/core/notifications/local_notification_service.dart` ← add route payload to notification
- `lib/core/routing/app_router.dart` ← handle notification payload on cold start

**Implementation:**
```dart
// In notification creation:
await flutterLocalNotificationsPlugin.show(
  id,
  title,
  body,
  NotificationDetails(...),
  payload: jsonEncode({'route': '/tasks', 'itemId': task.id}),
);

// In app router:
final notificationAppLaunchDetails = await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
if (notificationAppLaunchDetails?.didNotificationLaunchApp == true) {
  final payload = jsonDecode(notificationAppLaunchDetails!.notificationResponse!.payload!);
  router.go(payload['route'], extra: {'itemId': payload['itemId']});
}
```

---

## FINAL PROJECTED SCORES AFTER PLAN COMPLETION

| Category | Kotlin (now) | DART (now) | DART (after plan) | Delta vs Kotlin |
|---|---|---|---|---|
| Sync Infrastructure | 10/10 | 8/10 | **10+/10** | +1 (circuit breaker, status UI) |
| Test Coverage | 10/10 | 6/10 | **10/10** | Equal |
| Code Quality Gates | 10/10 | 7/10 | **10/10** | Equal |
| MpesaParser | 9.5/10 | 9.5/10 | **10/10** | +0.5 (3-layer dedup, 150+ tests) |
| Security | 9/10 | 8/10 | **10/10** | +1 (SQLCipher, Sentry, secret scanner) |
| Feature Completeness | 8/10 | 8/10 | **10/10** | +2 (search nav, AI context, calendar swipe) |
| Accessibility | N/A | 2/10 | **8/10** | DART-exclusive advantage |
| Cross-Platform | 5/10 | 10/10 | **10/10** | DART-exclusive advantage |
| Observability | 5/10 | 3/10 | **10/10** | +5 (Sentry, AppLogger, perf profiling) |
| CI/CD | 0/10 | 0/10 | **10/10** | DART-exclusive advantage |
| Feature Flags | 4/10 | 6/10 | **9/10** | +3 (kill-switch, rollout %) |
| **WEIGHTED TOTAL** | **9.5/10** | **8.6/10** | **10/10** | **+0.5 vs Kotlin** |

---

## IMPLEMENTATION ORDER (RECOMMENDED)

```
Week 1 (Days 1-5):
  Day 1-2: Phase 1 (Logging, freezed, date formatting, app version)
  Day 3-4: Phase 2 Part 1 (Search nav, AI context, calendar swipe, recurring edit)
  Day 5:   Phase 2 Part 2 (Budget bars, income chart, export share, accessibility, font)

Week 2 (Days 6-10):
  Day 6-7: Phase 3 (Sync state machine, circuit breaker, sync status UI)
  Day 8:   Phase 4 (3-layer dedup, normalizer, Fuliza lifecycle)
  Day 9-10: Phase 4 continued (150+ parser tests, thread safety tests)

Week 3 (Days 11-15):
  Day 11-13: Phase 5 (Widget tests, Supabase repo tests, migration tests, CI/CD)
  Day 14-15: Phase 6 (Secret scanner, arch checker, SQLCipher, Sentry, feature flags)

Week 4 (Days 16-18):
  Day 16-17: Phase 7 (ShellRoute, materialized view, performance profiling)
  Day 18:   Final validation, update KOTLIN_vs_DART_AUDIT.md with new scores
```

---

## VALIDATION CHECKLIST (BEFORE DECLARING VICTORY)

- [ ] `flutter analyze --fatal-infos` passes with zero issues
- [ ] `flutter test --coverage` passes with >70% coverage
- [ ] `scripts/secret_scan.sh` returns exit 0
- [ ] `scripts/architecture_check.sh` returns exit 0
- [ ] CI/CD pipeline passes on a fresh branch
- [ ] TalkBack accessibility scan passes (no unlabelled interactive elements)
- [ ] DevTools: no frames exceed 16ms budget on mid-range device
- [ ] `strings beltech.db` returns no plaintext financial data (SQLCipher working)
- [ ] Search tap-through navigation verified on all 6 result types
- [ ] AI assistant answers "how much did I spend this week?" with real user data
- [ ] Sync circuit breaker test: 5 failures → circuit open → probe → close
- [ ] Calendar swipe and agenda view functional on both Android and iOS
- [ ] Sentry DSN configured in CI secrets, test error captured in Sentry dashboard
- [ ] Shorebird patch deployed and received on test device without store update
- [ ] `KOTLIN_vs_DART_AUDIT.md` updated with final post-plan scores

---

*Plan authored: 2026-03-23 | Based on: KOTLIN_vs_DART_AUDIT.md + AUDIT_REPORT.md + CODING_RULES.md*
*Estimated completion: ~25 development days across 3-4 sprints*
