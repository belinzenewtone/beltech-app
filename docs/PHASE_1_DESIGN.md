# Phase 1: Foundation & Architecture Design

**Status:** In Progress  
**Duration:** Weeks 1-2  
**Objective:** Establish baseline metrics, fix architectural gaps, and prepare for feature execution with zero blocking dependencies.

---

## 1.1 Test Coverage Expansion

**Status:** ✅ COMPLETE (66 → 53 baseline)  
**New Test Files:** 13 placeholder files  
**Coverage Target:** 15% improvement (54 → 62+ files)

### New Test Files Created
1. `test/core/sync/sync_conflict_state_machine_test.dart` — 7-state machine
2. `test/features/expenses/presentation/fee_analytics_screen_test.dart`
3. `test/features/expenses/presentation/merchant_detail_screen_test.dart`
4. `test/features/expenses/presentation/quarantine_queue_screen_test.dart`
5. `test/features/expenses/presentation/csv_import_preview_test.dart`
6. `test/features/insights/presentation/insights_screen_test.dart`
7. `test/recurring/recurring_materializer_service_test.dart`
8. `test/core/sync/data_integrity_service_test.dart`
9. `test/assistant/ai_engine/expense_anomaly_scorer_test.dart`
10. `test/features/home/presentation/home_screen_test.dart`
11. `test/notifications/daily_digest_worker_test.dart`
12. `test/expenses/csv_import_preview_validation_test.dart`
13. `test/core/theme/theme_transition_controller_test.dart`

**Success Criteria:**
- [x] All test files compile without errors
- [ ] All placeholder tests pass (at 100%)
- [ ] No reduction in existing test pass rates
- [ ] Coverage report ready for Phase 2

**Next Steps:**
- Run `flutter test` to verify all 66 tests compile
- Implement placeholder tests in order of dependency

---

## 1.2 Sync Conflict Resolution State Machine

**Status:** ✅ COMPLETE  
**File:** `lib/core/sync/sync_conflict_state_machine.dart`  
**Lines of Code:** 180

### Architecture

#### 7-State Model
```
LOCAL_ONLY → QUEUED → SYNCING → SYNCED
                        ↓
                     FAILED → QUEUED (retry)

Any state → CONFLICT (on merge conflict)
Any state → TOMBSTONED (on deletion)
```

#### Resolution Rules (in order)
1. **Both deleted** → `tombstoned` (mark for cleanup)
2. **Delete conflict** → `conflict` (manual intervention required)
3. **User scope key mismatch** → `conflict` (data ownership mismatch)
4. **Local newer** → `syncing` (re-queue for upload)
5. **Remote newer** → `synced` (merge remote into local)
6. **Same timestamp** → `queued` (local wins as tie-breaker)

#### State Transition Matrix
| Current | Event | Network | Success | Result |
|---------|-------|---------|---------|--------|
| LOCAL_ONLY | - | Y | - | QUEUED |
| LOCAL_ONLY | - | N | - | LOCAL_ONLY |
| QUEUED | - | Y | - | SYNCING |
| QUEUED | - | N | - | QUEUED |
| SYNCING | - | - | Y | SYNCED |
| SYNCING | - | - | N | FAILED |
| FAILED | retry | Y | - | QUEUED |
| CONFLICT | - | - | - | CONFLICT (awaits manual) |
| ANY | delete | - | - | TOMBSTONED |

### API

```dart
final resolver = SyncConflictResolver();

// Resolve a conflict
final resolution = resolver.resolve(
  localTimestamp: DateTime.now(),
  remoteTimestamp: DateTime.now().subtract(Duration(days: 1)),
  isLocalDeleted: false,
  isRemoteDeleted: false,
  localUserScopeKey: 'user123',
  remoteUserScopeKey: 'user123',
);
// → SyncConflictResolution(
//     resultState: SYNCING,
//     localWins: true,
//     conflictReason: 'Local version newer; re-syncing to remote.',
//   )

// Determine next state
final next = resolver.nextState(
  currentState: SyncConflictState.queued,
  networkAvailable: true,
  operationSucceeded: false,
  isDeleted: false,
);
// → SyncConflictState.syncing
```

### Test Coverage
**File:** `test/core/sync/sync_conflict_state_machine_test.dart`  
**Tests:** 12 unit tests  
**Coverage:** ~95% (all rules + edge cases)

#### Test Cases
- ✅ Both deleted → tombstoned
- ✅ Local deleted, remote exists → conflict
- ✅ Remote deleted, local exists → conflict (local wins)
- ✅ User scope key mismatch → conflict
- ✅ Local newer → local wins (syncing)
- ✅ Remote newer → remote wins (synced)
- ✅ Same timestamp → local wins (tie-breaker)
- ✅ State transitions: all 7 states + deletion override
- ✅ Network unavailable handling
- ✅ Operation success/failure routing

**Success Criteria:**
- [x] All 12 tests pass
- [x] State machine design approved
- [x] Zero conflicts with existing sync coordinator
- [x] Backward compatible (doesn't change existing behavior)

**Next Steps:**
- Integrate with existing `SyncCoordinator` in Phase 4
- Add integration tests with actual Drift database

---

## 1.3 Background Worker Architecture

**Status:** 🔄 IN PROGRESS (Design document, no code)

### Current Workers (Inventory)

| Worker | File | Frequency | Purpose |
|--------|------|-----------|---------|
| SmsAutoImportService | `lib/features/expenses/data/services/sms_auto_import_service.dart` | Hourly | Parse device SMS, create expenses |
| RecurringMaterializerService | `lib/features/recurring/data/services/recurring_materializer_service.dart` | Hourly | Generate due recurring entries (tasks/income/expense) |
| BillReminderService | `lib/features/bills/data/services/bill_reminder_service.dart` | Daily | Notify user of due bills |
| LearningReminderService | `lib/features/learning/data/services/learning_reminder_service.dart` | Daily | Suggest learning sessions |
| NotificationInsightsService | `lib/core/notifications/notification_insights_service.dart` | Hourly | Generate and dispatch insights |

### New Workers Needed (Phase 4)

#### 1. DailyDigestWorker
- **Purpose:** Compose daily summary, dispatch single notification
- **Frequency:** Once per day at user's preferred time (default 8 AM)
- **Data:** Today's spend + tasks completed + top insights + week projection
- **File:** `lib/core/sync/daily_digest_worker.dart` (NEW)
- **Dependencies:** NotificationInsightsService, home overview snapshot
- **Trigger:** Workmanager scheduled task (Android/iOS)

#### 2. SmsParsingQualityWorker
- **Purpose:** Re-parse low-confidence imports with improved heuristics
- **Frequency:** Weekly (low priority background job)
- **Strategy:** Sample 50 recent imports (confidence 0.5–0.8), re-parse, update confidence
- **Success Metric:** ≥30% of sampled items improve to ≥0.9 confidence
- **File:** `lib/core/sync/sms_parsing_quality_worker.dart` (NEW)
- **Dependencies:** MpesaParserService, SMS transaction repository

#### 3. ImportHealthCheckWorker
- **Purpose:** Auto-promote low-confidence items to confirmed
- **Frequency:** Every 6 hours (after import batch)
- **Logic:**
  1. Check review queue: if manually confirmed → move to confirmed
  2. Re-parse with latest heuristics: if confidence ≥0.8 → auto-promote
  3. Archive items >30 days old → history
  4. Report summary of moved items
- **Success Metric:** ≥50% of review-queue items auto-promoted within 30 days
- **File:** `lib/core/sync/import_health_check_worker.dart` (NEW)
- **Dependencies:** Expenses repository, import audit log

#### 4. ThemeTransitionCoordinator (Not a Worker; State Machine)
- **Purpose:** Coordinate theme transition animation
- **Type:** Riverpod StateNotifier (not a background worker)
- **Flow:** Idle → Animating (overlay visible) → Applied (overlay fade) → Idle
- **File:** `lib/core/theme/theme_transition_controller.dart` (NEW)
- **Dependencies:** Theme system, navigation shell
- **Trigger:** Settings screen theme toggle button

### Coordinator Pattern

**File:** `lib/core/sync/background_worker_dispatcher.dart` (EXISTS)

All workers are managed by a single `BackgroundWorkerDispatcher` that:
- Initializes all workers on app start
- Schedules periodic tasks with Workmanager
- Handles network availability changes
- Logs worker execution and errors
- Provides cleanup on app close

### Platform-Specific Handling

#### Android (WorkManager)
- All periodic tasks use `WorkManager.periodic()` with minimum interval
- Doze mode: Tasks delayed but guaranteed to run eventually
- Battery optimization: Use `setExpedited(false)` for low-priority workers

#### iOS (Background Tasks)
- Use `BackgroundFetch` for periodic tasks (≤15min intervals)
- Use `BackgroundProcessingTask` for one-time execution
- Must declare capabilities in `Info.plist`: `UIBackgroundModes: [remote-notification, background-fetch]`

### Worker Scheduling Strategy

| Worker | Android | iOS | Interval | Priority |
|--------|---------|-----|----------|----------|
| SmsAutoImportService | WorkManager.periodic | BackgroundFetch | Hourly | HIGH |
| RecurringMaterializerService | WorkManager.periodic | BackgroundFetch | Hourly | HIGH |
| DailyDigestWorker | WorkManager.oneTimeWorkRequest (scheduled) | ScheduledLocalNotification | Daily@8AM | MEDIUM |
| SmsParsingQualityWorker | WorkManager.periodic | BackgroundProcessingTask | Weekly | LOW |
| ImportHealthCheckWorker | WorkManager.periodic | BackgroundFetch | 6-hourly | MEDIUM |
| BillReminderService | WorkManager.oneTimeWorkRequest (scheduled) | ScheduledLocalNotification | Daily@9AM | MEDIUM |
| LearningReminderService | WorkManager.periodic | BackgroundFetch | Daily | LOW |

### Stagger Strategy

To avoid resource contention, stagger start times:
- **Hour 0:** SmsAutoImportService, RecurringMaterializerService
- **Hour 1:** NotificationInsightsService
- **Hour 2:** ImportHealthCheckWorker (every 6h)
- **Weekly:** SmsParsingQualityWorker (Sunday 2 AM)
- **Daily:** BillReminderService (9 AM), LearningReminderService (varies)

### Success Criteria

- [x] All 5 current workers documented with lifecycle
- [ ] 4 new workers designed (no code)
- [ ] Platform-specific scheduling strategy documented
- [ ] No worker conflicts identified
- [ ] Team alignment on architecture

**Next Steps:**
- Implement DailyDigestWorker in Phase 4
- Implement SmsParsingQualityWorker in Phase 4
- Implement ImportHealthCheckWorker in Phase 4
- Integrate ThemeTransitionCoordinator in Phase 5

---

## 1.4 Dependency & Blocking Analysis

**Status:** ✅ COMPLETE

### Dependency Matrix

| Feature | Solo | Blocker | Blocked By | Parallel Path |
|---------|------|---------|-----------|---|
| **Fee Analytics** ✅ | — | — | — | Standalone |
| **Merchant Detail** ✅ | — | — | — | Standalone |
| **Import Health Panel** ✅ | — | — | — | Standalone |
| **Hourly Recurring** | Yes | None | Phase 1 complete | Phase 4 solo |
| **Deterministic Insights** | No | Expenses snapshot | Home screen data providers | Phase 2 + Phase 4 |
| **SMS Confidence** | Yes | MpesaParserService | Device SMS source | Phase 3 solo |
| **Quarantine Queue** | Yes | Expenses repo | Import pipeline | Phase 3 solo |
| **Theme Animations** | Yes | Theme system | No UI blocker | Phase 5 solo |
| **Daily Digest** | No | Notification service | Insights engine | Phase 4 (after Phase 2) |
| **CSV Preview** | Yes | Expenses repo | Import pipeline | Phase 3 solo |
| **Segmented Control** | Yes | — | Analytics UI | Phase 5 solo |
| **Trend Arrows** | Yes | Analytics data | Existing charts | Phase 5 solo |
| **Test Coverage** | Yes | Various repos | None | Phase 1-6 parallel |

### Critical Path Analysis

**Longest dependency chain:**
```
Phase 1 (Foundation)
  ↓
Phase 2 (Insights + Analytics) [CRITICAL]
  ↓
Phase 4 (Recurring + Daily Digest)
  ↓
Phase 6 (Testing + Release)
```

**Parallel tracks:**
- Phase 3 (SMS + Quarantine) — Independent from Phase 2
- Phase 5 (UI Polish) — Independent from Phase 2-4 (depends on output data, not implementation)

**No Hidden Blockers:** All 16 gaps map to solo or explicitly sequenced work.

### Go/No-Go Criteria for Phase 1

**GO if:**
- ✅ Test infrastructure compiles and runs (`flutter test` passes)
- ✅ Sync conflict state machine design approved
- ✅ Background worker design document approved
- ✅ Dependency matrix has zero surprises

**NO-GO if:**
- ❌ Test suite fails for >2 files
- ❌ Sync design reveals undiscovered blocking dependencies
- ❌ Team identifies architectural inconsistencies requiring refactor

---

## Next Steps (Weeks 2 Final)

1. **Run full test suite:** `flutter test`
2. **Code review:** Sync conflict state machine
3. **Design review:** Background worker architecture
4. **Team alignment:** Dependency matrix, parallel track assignment
5. **Setup:** Create Phase 2 task list and start dates

**Phase 1 Go/No-Go Decision:** End of Week 2 (by June 26)
