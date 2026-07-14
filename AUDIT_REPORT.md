# BELTECH App — Fresh Codebase Audit
> Generated: March 2026 | Flutter / Dart | Reviewer: Claude | Version: 1.0.1+2

---

## What's Changed Since the Last Audit

The previous audit flagged 10+ issues that have since been resolved. The app has matured significantly. Key improvements confirmed in this read-through:

- **go_router is now fully integrated** — named routes exist for all secondary screens; Settings/Budget/Income/Recurring/Search/Export/Analytics are all proper GoRouter routes.
- **Dynamic greeting is implemented** — `_buildGreeting()` correctly maps time-of-day to Morning / Afternoon / Evening / Night and personalises it with the user's first name.
- **Priority is fully visible on task cards** — `TaskItemCard` has a coloured left-border stripe AND a `_PriorityBadge` chip (Urgent / Important / Neutral) with correct colours from `AppColors`.
- **Swipe-to-delete is implemented natively** — `TaskItemCard` uses `Dismissible` with swipe-right-to-complete and swipe-left-to-delete.
- **flutter_markdown is in use** — `AssistantConversationList` renders AI responses with `MarkdownBody`; the `replaceAll('**', '')` hack is gone.
- **Retry buttons exist** — All error states (`homeOverviewProvider`, `assistantMessagesProvider`, etc.) have `onRetry: () => ref.invalidate(...)` wired up.
- **Currency is centralised** — `CurrencyFormatter` uses `intl`'s `NumberFormat.currency(locale: 'en_KE', symbol: 'KES')`. No more scattered string literals.
- **intl is installed and used** — `intl: ^0.20.2` is in `pubspec.yaml` and used properly.
- **Budget feature is fully built** — Monthly targets per category, progress bars, spend-vs-limit summary card with month navigation, and warning-level alerts.
- **Income tracking is built** — Full CRUD for income records with a total summary card.
- **Recurring templates are built** — Supports expense, income, task, and event kinds across daily / weekly / monthly cadences with a `RecurringMaterializerService`.
- **Global Search is built** — Cross-feature search across expenses, income, tasks, events, budgets, and recurring items.
- **Data Export is built** — CSV export per scope (all / expenses / incomes / tasks / events / budgets / recurring) saved to app documents directory.
- **Analytics screen is built** — Trend line chart, bar chart, overview cards, and category breakdown with weekly/monthly period toggle.
- **Notifications are fully wired** — `LocalNotificationService` schedules task and event reminders. `NotificationInsightsService` runs budget threshold alerts (at 80%, 100%, 120%) and a daily digest. Settings screen has three notification toggles.
- **Profile avatar is implemented** — `ProfileAvatar` displays initials fallback, supports gallery image picker, and handles network URL or base64 data URIs.
- **Merchant learning service exists** — `MerchantLearningService` learns user-assigned categories and applies them on future imports.
- **Test coverage has grown substantially** — 19 test files covering repositories, services, and core utilities across every feature.
- **Package name is fixed** — `pubspec.yaml` shows `name: beltech`; all imports use `package:beltech/...`.
- **App update system is built** — `AppUpdateService` + `AppUpdateDialog` with force-update support and install progress tracking.
- **Biometric lock is wired to lifecycle** — `AppShell` locks the app after 2+ seconds of background time and re-authenticates on resume.
- **Background sync is running** — `BackgroundSyncCoordinator` with platform-aware intervals, `SmsAutoImportService` polling every 20 minutes on Android, and recurring materializer.
- **Light theme is implemented** — Full `AppTheme.lightTheme` with a distinct colour scheme; theme toggle in Settings.
- **`show all transactions` button exists** — The `.take(20)` cap now has a visible "Show all transactions (N)" toggle button.
- **`BackdropFilter` sigma is adaptive** — `GlassStyles.blurSigmaFor(brightness)` returns different values for dark vs light, addressing the worst-case blur cost.
- **Calendar event dots are in the grid** — `CalendarMonthGrid` receives `eventTypes: Map<int, CalendarEventType>` and renders a coloured 4px dot under each day that has events.
- **Calendar events are colour-coded by type** — Work / Personal / Finance / Health / General each render with a distinct colour from `AppColors`.

---

## 1. Remaining Issues

### 1.1 Budget Screen — Category Targets Lack Progress Bars

The `_BudgetSummaryCard` shows progress bars for categories, but the "Category Targets" section below it (the editable list of `BudgetTarget` rows) only shows the name and monthly limit — no current spend and no progress bar per row. The user set a target but can't see at a glance how much of it they've consumed without looking at the summary above.

**Fix:** Each `BudgetTarget` row should show a compact `LinearProgressIndicator` with the current spend against the limit. The `BudgetSnapshot.items` already contains `spentKes` and `usageRatio` per category — join them to the targets list by category name.

---

### 1.2 Budget Summary Card — Capped at 6 Items Silently

`_BudgetSummaryCard` renders `.take(6)` categories with no "Show more" button or count label. If the user has 8+ category budgets, the overflow is silently discarded.

**Fix:** Either remove the cap or add a "Show all (N)" expansion button identical to the expenses list pattern already in the app.

---

### 1.3 Recurring Screen — No Edit Action

`_RecurringRow` has only a delete button. There is no way to edit a recurring template after creation. Every other list in the app (tasks, expenses, income) has an edit flow. This is a significant UX gap for recurring items whose next-run date or amount needs updating.

**Fix:** Add an `onEdit` handler to `_RecurringRow` using `showRecurringTemplateDialog` with pre-populated initial values, mirroring the income and task edit patterns.

---

### 1.4 Recurring Screen — Amount Formatting is Inconsistent

`_RecurringRow` displays the amount as `'KES ${template.amountKes!.toStringAsFixed(2)}'` — a raw string interpolation. Every other monetary value in the app uses `CurrencyFormatter.money()`. This produces `KES 500.00` instead of the proper `KES500.00` formatted by `intl`.

**Fix:** Replace with `CurrencyFormatter.money(template.amountKes!)`.

---

### 1.5 Income Screen — No Income Chart

The Income screen shows a total at the top and a flat list below. There is no visual trend — no monthly chart showing income over time, no comparison against total expenses, and no net cashflow figure (income − expenses). This makes the screen feel like a data entry form rather than a financial insight tool.

**Fix:** Add a monthly income trend line chart (reuse `AnalyticsTrendChart`) and a net cashflow card that pulls the current month's total expenses from `homeOverviewProvider` or a shared provider.

---

### 1.6 Export Screen — No Share Sheet

The Export screen saves files to the app documents directory and shows the file path as `SelectableText`, but there is no share button. On Android the documents directory is sandboxed — users cannot easily navigate to it in a file manager. Without a share sheet, exported files are effectively inaccessible to most users.

`url_launcher` is already in `pubspec.yaml`. `share_plus` is not, but it is lightweight and solves this cleanly.

**Fix:** Add `share_plus` and trigger `Share.shareXFiles([XFile(result.filePath)])` after a successful export. Alternatively use `url_launcher` to open the directory if share_plus is not desired.

---

### 1.7 Global Search — No Tap-Through Navigation

Search results display well, but tapping a result does nothing. There is no navigation to the underlying item. A user who finds "Electricity Token - KES 3,200" in search results has no way to view or edit it from there.

**Fix:** Add an `onTap` to each search result row that navigates to the relevant screen. For expenses, this could push to `ExpensesScreen` pre-filtered. For tasks, push to `TasksScreen`. This requires the `GlobalSearchResult` entity to carry enough context (feature type + item ID) to resolve the destination.

---

### 1.8 Assistant — No Live Data Context

The `AssistantProxyService.generateReply()` accepts an `analyticsContext` string parameter, suggesting the intent is to inject user data into the AI prompt. However, inspecting the provider chain shows this context is either empty or only partially populated. The assistant cannot answer "How much did I spend this week?" with the user's real numbers.

**Fix:** Before calling `generateReply`, build a structured context string from the currently loaded `homeOverviewProvider` (today's spend, weekly spend, pending tasks, upcoming events). Inject it as the `context` payload. This is the highest-leverage AI improvement possible — it turns the assistant from a general chatbot into a genuinely personal finance assistant.

---

### 1.9 Calendar — No Swipe Gesture for Month Navigation

Month navigation requires tapping the `<` and `>` chevron buttons in `CalendarScreen`. There are no swipe gestures. On mobile, swiping left/right to change months is the standard UX pattern (as seen in Google Calendar, Apple Calendar, etc.).

**Fix:** Wrap `CalendarMonthGrid` in a `GestureDetector` with `onHorizontalDragEnd` that detects velocity direction, or use a `PageView` with the month grid as each page.

---

### 1.10 Calendar — No Week or Agenda View

The calendar only has a month grid view. There is no week view (showing time slots) or agenda view (linear list of upcoming events). For users who manage many events, the month grid with small dots is insufficient.

**Fix:** Add a view toggle (Month / Agenda) in the `CalendarScreen` app bar. The agenda view would be a simple `ListView` of upcoming events sorted by date — very low implementation cost and very high UX value.

---

### 1.11 Settings — No App Version / About Section

Settings contains Security, Appearance, and Data & Tools sections, but has no About section and no visible app version. This is required for both App Store and Play Store compliance, and users typically need it to report bugs.

**Fix:** Add a bottom section to `SettingsScreen` that reads version from `package_info_plus` (already installed) and shows version name + build number. Add an "Account Deletion" option here as well (required by both stores for apps with accounts).

---

### 1.12 Domain Entities — No Immutability

All domain entities (`TaskItem`, `ExpenseItem`, `BudgetTarget`, `CalendarEvent`, `IncomeItem`, etc.) are plain `const` classes with no `copyWith`, no `==` override, and no `hashCode`. Riverpod relies on value equality to decide whether to rebuild — without `==` overrides, every time a stream emits the same logical data, all watching widgets rebuild unnecessarily.

**Fix:** Either implement `==` and `hashCode` manually for each entity, or add `freezed` + `json_serializable` to generate them. `freezed` also gives `copyWith` for free, which simplifies mutation logic throughout the codebase.

---

### 1.13 No Custom Font

`AppTheme` defines font sizes and weights but does not specify a `fontFamily`. The app renders with the system default (Roboto on Android, SF Pro on iOS). The glassmorphism aesthetic would pair strongly with a modern geometric sans-serif.

**Fix:** Add `google_fonts: ^6.x` and apply `GoogleFonts.dmSansTextTheme()` or `GoogleFonts.interTextTheme()` inside `AppTheme.darkTheme` and `AppTheme.lightTheme`. This is a two-line change with a large visual impact.

---

### 1.14 No Accessibility Semantics

No widget in the codebase uses `Semantics`, `MergeSemantics`, `ExcludeSemantics`, or `Tooltip` in a meaningful way. Screen readers (TalkBack on Android, VoiceOver on iOS) would produce near-useless output for every interactive element. This will be a barrier to App Store approval in markets with accessibility requirements.

**Fix:** At minimum, add `Semantics(label: ...)` to icon-only buttons (the send button in the assistant, the camera button in the avatar, the swipe-to-complete/delete interactions). Add `excludeSemantics: true` to decorative elements.

---

### 1.15 No Onboarding Flow

New users are dropped directly into the home dashboard. There is no first-run onboarding screen explaining what the app does or how to get started (especially relevant for the MPESA import feature, which many users may not discover on their own).

**Fix:** Show a simple 3-slide onboarding on first launch using `introduction_screen` or a custom `PageView`. Store the completion flag in `SharedPreferences`. Slides: (1) Track your spending automatically with MPESA, (2) Manage tasks and calendar, (3) Ask the AI assistant anything.

---

### 1.16 AppShell — `unawaited()` Without Import

`AppShell` uses `unawaited()` calls (`unawaited(_startBackgroundSync())`, etc.) without explicitly importing `dart:async` or `package:flutter/foundation.dart`. This depends on the function being implicitly available. While Dart permits this in many cases, it is better practice to add the explicit `// ignore: unawaited_futures` directive or use `_startBackgroundSync().ignore()` for clarity.

---

### 1.17 Test Coverage — UI Layer is Untested

The test suite covers repositories, services, and utilities well (19 files). However, there are no widget tests for any screen or presentation-layer component. Key business flows — submitting a task, importing MPESA, sending an assistant message — have no automated UI-layer verification.

**Fix:** Add widget tests for at minimum: `TaskItemCard` (priority colour rendering, swipe actions), `HomeScreen` (greeting personalisation), `AssistantScreen` (send → loading state), and the `AuthGate` transition.

---

### 1.18 Expenses — Date Formatting is Hand-Written

`ExpensesSnapshotContent` formats transaction timestamps as:
```dart
'${tx.occurredAt.month}/${tx.occurredAt.day}, ${tx.occurredAt.hour}:${tx.occurredAt.minute.toString().padLeft(2, '0')}'
```
This is a manual format that ignores locale, produces ambiguous M/D format (is `3/4` March 4th or April 3rd?), and doesn't use `intl` which is already in the project. Similarly, `IncomeScreen` and `RecurringScreen` format dates with raw string interpolation.

**Fix:** Use `DateFormat('MMM d, HH:mm').format(tx.occurredAt)` from `intl` consistently across all date displays in the app.

---

### 1.19 No Logging Infrastructure

There is no logging in the codebase. Errors in repositories and services are silently swallowed (the `catch (_) { return 0; }` pattern appears in `SmsAutoImportService`, `NotificationInsightsService`, and elsewhere). This makes diagnosing production issues very difficult.

**Fix:** Add `logger: ^2.x` and create a singleton `AppLogger` in `core/`. Replace silent `catch (_)` blocks with `AppLogger.error(...)` calls. Wire Riverpod's `ProviderObserver` to log state changes in debug mode.

---

## 2. Quick Wins (Do These First)

Low effort, high impact — each can be completed in under half a day:

1. **`CurrencyFormatter.money()` in RecurringScreen** — one-line fix, eliminates the last inconsistent money format
2. **Edit button on RecurringRow** — mirrors the income pattern already in place
3. **`show more` in BudgetSummaryCard** — remove the silent `.take(6)` cap
4. **Version number in Settings** — 3 lines using `package_info_plus`
5. **Date formatting with `intl`** — replace all hand-written date strings in expenses, income, and recurring rows
6. **`share_plus` for export** — single share button after CSV is written
7. **`google_fonts` + Inter/DM Sans** — 2 lines in `AppTheme`, transforms visual quality
8. **Semantics on icon-only buttons** — add `tooltip:` to the send button, camera button, and swipe backgrounds

---

## 3. Feature Gaps Remaining

| Feature | Status | Notes |
|---|---|---|
| Budget progress per editable target row | Missing | Data exists, just not plumbed to the row widget |
| Edit recurring templates | Missing | Delete exists, edit does not |
| Tap-through on search results | Missing | Results render but are not interactive |
| Live data context in AI assistant | Partial | Parameter exists, context injection incomplete |
| Month swipe on calendar | Missing | Chevron buttons only |
| Agenda / week view on calendar | Missing | Month grid only |
| Net cashflow card (income − expenses) | Missing | Both values are available but never combined |
| Share sheet for exports | Missing | File saved but not surfaced to user |
| Account deletion option | Missing | Required for App Store compliance |
| Onboarding flow | Missing | Users land on empty dashboard with no guidance |
| Custom font | Missing | System default (Roboto/SF Pro) in use |

---

## 4. Architecture Assessment (Updated)

**Routing** — go_router is fully integrated with named routes. The one remaining inconsistency is that the `AppShell` and its 6 tabs are not expressed as go_router `ShellRoute` children. Tab-level deep linking (e.g., a notification that opens directly to the Calendar tab) is not possible without a `ShellRoute`. This is not urgent but worth planning for.

**State Management** — Riverpod is used well throughout. Controllers follow the `AsyncNotifier` pattern consistently. One notable gap: providers for domain entities don't override `==`, so unnecessary rebuilds are occurring silently (see §1.12).

**Data Layer** — The dual local (Drift) + remote (Supabase) repository pattern with `useSupabaseProvider` flag is clean and well-executed. The `SmsAutoImportService` is production-ready with idempotency (SHA-256 hash deduplication), overlap windows, and user-scoped sync state.

**Background Work** — `BackgroundSyncCoordinator` with `workmanager` for OS-level scheduling is architecturally correct. The platform-aware strategy (tighter Android cadence) shows real-world thinking.

**Testing** — 19 test files with coverage across all features is a meaningful improvement. The gap is UI/widget test coverage (currently zero) and the Supabase repository implementations (tests only cover local implementations).

---

## 5. Updated Ratings

| Area | Previous | Now | Change |
|---|---|---|---|
| Architecture | ★★★★☆ | ★★★★☆ | → Stable. ShellRoute is the remaining gap. |
| Code Quality | ★★★★☆ | ★★★★☆ | → Consistent patterns; date formatting is the main smell. |
| UI/UX Design | ★★★☆☆ | ★★★★☆ | ↑ Priority visibility, event dots, light theme, swipe gestures are now live. |
| Feature Completeness | ★★☆☆☆ | ★★★★☆ | ↑↑ Budget, income, recurring, search, export, analytics are all built. |
| Performance | ★★★☆☆ | ★★★★☆ | ↑ Adaptive blur sigma, `AnimatedSwitcher` transitions, stagger reveal animations. |
| Testing | ★★☆☆☆ | ★★★☆☆ | ↑ 19 test files, but zero widget/UI tests. |
| Accessibility | ★★☆☆☆ | ★★☆☆☆ | → No change. No semantics added. |
| Production Readiness | ★★☆☆☆ | ★★★★☆ | ↑↑ Package renamed, notifications wired, app update system, biometric lifecycle. |

---

## 6. Summary

The BELTECH app has undergone a significant transformation since the last audit. The foundational gaps — routing, dynamic greeting, priority visibility, markdown rendering, currency formatting, notifications, budget tracking, income, recurring templates, search, export, and analytics — have all been addressed. The architecture is now genuinely production-grade.

The remaining issues are refinements rather than gaps. The most impactful next steps are: injecting live data into the AI assistant (turns it from a chatbot into a personal finance tool), adding tap-through navigation to search results, adding swipe navigation to the calendar, and resolving domain entity equality to eliminate unnecessary rebuilds. The accessibility gap is the biggest risk for App Store review.

This is no longer a prototype. With 3–4 focused sprints addressing the items above, this is a shippable product.
