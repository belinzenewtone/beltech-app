# DART-2.0 UI Revamp Plan

**Principle:** Features built for the app — not the app built around features.
Every screen should feel like it belongs to one cohesive product. The React Native
revamp established the design language; this plan ports and elevates it natively
into Flutter.

---

## What Is Wrong Right Now

Before prescribing fixes, here is an honest diagnosis of the current state:

### Structural Issues

**No unified page shell.** Every screen rolls its own `SafeArea + SingleChildScrollView`
with different internal padding, different header styles, and no shared atmospheric
treatment. The result is that screens feel like independent widgets stacked in a
tab container rather than chapters of a single app.

**No consistent page header pattern.** HomeScreen uses a logo + `titleLarge` text.
ExpensesScreen uses a plain `Text` title with an inline button. TasksScreen uses a
title + count subtitle with no eyebrow. There is no system — every screen invents
its own header layout.

**The tab bar is a Material NavigationBar in a GlassCard.** This works, but it
has no animated selection indicator that slides between tabs. The pill is static.
It reads as Material-themed rather than the product's own visual language.

**Two-tone GlassCard only.** The current GlassCard has `standard` and `accent`
tones. There is no `muted` tone for lower-emphasis surfaces (e.g. empty states,
secondary info cards, hint sections). This collapses the surface hierarchy.

**No button variant system.** Screens use raw `FilledButton`, `OutlinedButton`,
`TextButton`, and `OutlinedButton.icon` calls everywhere — each with inline
`styleFrom(...)` overrides. There is no `AppButton` widget, so the same button
type looks different across five screens.

**Missing third text level.** The color system has `textPrimary` and `textSecondary`
but no `textMuted` (~`#74839A`). Tertiary labels, placeholders, and metadata all
fall back to `textSecondary`, which blurs hierarchy.

**Category colors missing.** The app has tasks and expenses by category but no
shared category color tokens. Each screen that needs them either hardcodes hex
values or invents a local function. This creates drift.

**No typography role names.** Text styles are accessed by Material3 slot
(`titleLarge`, `bodyMedium`). These names don't communicate intent. A developer
needs to memorise which Material slot maps to which role. The RN app uses names
like `pageTitle`, `sectionTitle`, `eyebrow`, `amount`, `amountLg` — these are
self-documenting.

### Screen-Level Issues

**HomeScreen:** Logo is treated as a decorative element in the header row rather
than a branding mark. No user avatar or profile quick-access. No spend snapshot
strip. No eyebrow label. The analytics button is floated right as a freestanding
element with no relationship to the layout grid.

**ExpensesScreen:** The tab label says "Expenses" but the RN app calls the same
tab "Finance" — and the full feature covers income, budgets, recurring templates,
and SMS import, not just expenses. The label undersells the feature.

**TasksScreen:** Filter chips are visually disconnected from the list below.
TaskItemCard uses inconsistent internal spacing and the category dot/label
treatment differs from how categories appear in other screens.

**AssistantScreen:** The CircleAvatar header is a relic of early design. It
reads as a chat app, not a personal OS assistant. The "Online" status badge adds
noise without value. Quick-prompt chips are oversized.

**ProfileScreen:** The three icon-only buttons at the top (profile/analytics/settings)
have no labels. They're ambiguous and discoverable only by trial. The section
below has no visual grouping — it's a flat list of items.

**CalendarScreen:** The month grid and event list have no eyebrow labels or
contextual header. Navigation between months has no swipe gesture support
(flagged in the audit).

**Secondary screens (Analytics, Budget, Recurring, Settings, Export, Income,
Search):** These use entirely different layout approaches. Some have AppBars,
some don't. Some use GlassCard wrappers, some use plain Scaffold backgrounds.
There is no shared back-navigation header pattern.

---

## The Revamp — Five Phases

---

### Phase 1 — Design Token Foundation

**Goal:** One source of truth for every visual value in the app.

#### 1a. `app_colors.dart` — expand the palette

Add the missing tokens:

```
textMuted          #74839A (dark) / #8AA0BF (light)   — third text level
glowBlue           rgba(77, 154, 255, 0.24)            — page background glow
glowTeal           rgba(38, 196, 182, 0.18)            — teal page glow
glowIndigo         rgba(109, 119, 232, 0.18)           — violet page glow

categoryWork       #4F8CFF
categoryGrowth     #8B6DFF
categoryPersonal   #2DCF91
categoryBill       #F39A4D
categoryHealth     #E45C5C (reuse danger)
categoryOther      #5F7395 (reuse slate)
```

Add a `categoryColorFor(String category)` static helper.

#### 1b. `app_typography.dart` — new file for semantic text roles

Create `AppTypography` as a companion to the theme's `TextTheme`. It exposes
static methods that resolve against a `BuildContext`:

```
pageTitle(context)     → w700, 28px, lineHeight 34    (RN: pageTitle)
sectionTitle(context)  → w600, 17px, lineHeight 24    (RN: sectionTitle)
cardTitle(context)     → w600, 15px, lineHeight 22    (RN: cardTitle)
bodyMd(context)        → w400, 15px, lineHeight 22    (RN: bodyMd)
bodySm(context)        → w400, 13px, lineHeight 20    (RN: bodySm)
eyebrow(context)       → w600, 11px, letterSpacing 0.5, uppercase (RN: eyebrow)
amount(context)        → w700, 22px, lineHeight 28    (RN: amount)
amountLg(context)      → w700, 30px, lineHeight 36    (RN: amountLg)
```

All resolved via `GoogleFonts.inter(...)` so they inherit the project font.

#### 1c. `app_radius.dart` — new file for corner radius tokens

```
sm   8
md   12
lg   16
xl   22
xxl  28
full 9999
```

#### 1d. `app_spacing.dart` — extend existing

Add the named layout constants the RN app uses:
```
sectionGap    20
cardGap       16
listGap        8
fabBottom    132   (matches RN's fabBottom offset)
```

**Deliverables:** 2 new files (`app_typography.dart`, `app_radius.dart`), 2
updated files (`app_colors.dart`, `app_spacing.dart`).

---

### Phase 2 — Core Widget System

**Goal:** A complete set of shared widgets that every screen composes from.
Nothing in a screen file should ever call `styleFrom(...)` inline again.

#### 2a. `glass_card.dart` — add muted tone

Add `GlassCardTone.muted` as a third variant: lower opacity background, no
glow shadow, faint border. Used for empty states, hint cards, metadata sections.

The existing standard and accent tones remain unchanged.

#### 2b. `app_button.dart` — new file

A single `AppButton` widget wrapping Flutter's button primitives with a clean
variant + size API:

```dart
AppButton(
  label: 'Save',
  onPressed: ...,
  variant: AppButtonVariant.primary,  // primary | secondary | ghost | danger
  size: AppButtonSize.md,              // sm | md | lg
  icon: Icons.save,                    // optional leading icon
  loading: false,
  fullWidth: false,
)
```

Size specs (matching RN exactly):
- `sm`: height 38, horizontal padding 14, font 13px w600
- `md`: height 46, horizontal padding 18, font 15px w600
- `lg`: height 54, horizontal padding 22, font 16px w600

Variant specs:
- `primary`: accent fill, white text
- `secondary`: accent border, accent text, transparent fill
- `ghost`: no border, accent text, transparent fill
- `danger`: danger fill, white text

#### 2c. `page_shell.dart` — new file

The most important new widget. Every tab screen and routed screen composes
inside `PageShell`. It provides:

- **Atmospheric background glow** — a `PositionedRadialGlow` at top-right with
  a per-tab/per-screen accent color (same system as AppShell's radial gradient,
  but a second softer glow at bottom-left for depth)
- **Optional scroll** — `scrollable: true` wraps content in `CustomScrollView`
  with correct physics; `scrollable: false` gives a fixed Column
- **Reveal animation** — on first build, content fades in + slides up 12px over
  180ms (respects `reduceMotion`)
- **Safe area + bottom clearance** — automatically pads for nav bar height via
  `AppSpacing.contentBottomSafe`
- **Horizontal padding** — applies `AppSpacing.screenHorizontal` by default,
  overridable

```dart
PageShell(
  scrollable: true,
  glowColor: AppColors.glowBlue,       // optional override
  child: Column(children: [...]),
)
```

#### 2d. `page_header.dart` — new file

A consistent header widget for every screen:

```dart
PageHeader(
  eyebrow: 'YOUR DAY',           // optional small caps label above title
  title: 'Good Morning, Belinze',
  subtitle: "Here's your day at a glance",
  action: Widget?,               // top-right slot (avatar, icon button, etc.)
  leading: Widget?,              // optional left-side icon/logo
)
```

Eyebrow renders in `AppTypography.eyebrow` with `AppColors.textMuted`.
Title renders in `AppTypography.pageTitle` with `AppColors.textPrimary`.
Subtitle renders in `AppTypography.bodySm` with `AppColors.textSecondary`.
Action is aligned to the top-right of the header row.

#### 2e. `search_bar.dart` — new file (thin wrapper)

A consistent `AppSearchBar` widget so search inputs look identical across
GlobalSearch, TasksScreen, ExpensesScreen, and CalendarScreen.

#### 2f. `section_header.dart` — new file

A lightweight widget for in-screen section labels:

```dart
SectionHeader(label: 'Recent Transactions', action: TextButton(...))
```

Renders eyebrow-style label on the left, optional action link on the right.

**Deliverables:** 1 updated file (`glass_card.dart`), 5 new files
(`app_button.dart`, `page_shell.dart`, `page_header.dart`, `app_search_bar.dart`,
`section_header.dart`).

---

### Phase 3 — Navigation Shell

**Goal:** Replace the static Material NavigationBar with a custom animated
pill tab bar that matches the RN FloatingTabBar.

#### Custom `AppTabBar` widget

The current `NavigationBar` inside `AppShell` is replaced with a custom widget
built from scratch. It is still housed inside the `GlassCard`, but internally:

- An `AnimatedPositioned` (or `AnimationController`) drives a pill background
  that slides to the selected tab position
- The pill is accent-colored (`accentSoft` fill, accent border at 0.5 opacity)
- On tap: pill slides (150ms, `easeOutCubic`), icon scales up (1.0→1.15→1.0,
  100ms), label opacity fades in (0 or 1 based on selection state)
- Unselected tabs show icon only at `textMuted` opacity; selected tab shows icon
  (accent) + label below it
- Height stays 66px to match current nav clearance
- Icon set upgrade:

```
Home         Icons.grid_view_rounded (was home_outlined)
Calendar     Icons.calendar_today_rounded (was calendar_month_outlined)
Finance      Icons.account_balance_wallet_rounded (was receipt_long_outlined)
Tasks        Icons.task_alt_rounded (was check_circle_outline)
Assistant    Icons.auto_awesome_rounded (was smart_toy_outlined)
Profile      Icons.person_rounded (was person_outline)
```

- The tab label for "Expenses" is renamed to **"Finance"** to match the RN app
  and reflect the full feature scope (income + expenses + budgets + recurring)

**Deliverable:** New `app_tab_bar.dart` in `core/navigation/widgets/`, update
to `app_shell.dart` to use it.

---

### Phase 4 — Screen Revamp

Each screen is rebuilt using `PageShell` + `PageHeader` + the new widget system.
Business logic and providers are **not touched** — this is a pure presentation
layer revamp.

#### 4a. HomeScreen

**Before:** Logo row + subtitle + floating Analytics button + content
**After:**

```
PageShell(scrollable: true)
  PageHeader(
    eyebrow: 'YOUR DAY',
    title: greeting,        // dynamic hour-based greeting
    subtitle: "Here's your day at a glance",
    action: UserAvatarButton(onTap: goToProfile)
  )
  SpendSnapshotStrip(today, week)   // two metric pills in a Row
  AiInsightCard(...)                // shown when insight available
  SectionHeader('Today\'s Tasks')
  TodayTasksList(...)
  SectionHeader('This Month', action: SeeAllButton)
  MonthBalanceCard(...)
  SectionHeader('Recent', action: SeeAllButton)
  RecentTransactionList(...)
```

The `UserAvatarButton` shows initials in an accent circle (matching RN). The
Analytics button moves from a freestanding floated element to a secondary action
inside the profile area or via the Home overview cards.

#### 4b. CalendarScreen

**Before:** No header pattern, raw title inside screen
**After:**

```
PageShell(scrollable: false)
  PageHeader(
    eyebrow: 'PLAN',
    title: 'Calendar',
    action: AddEventButton
  )
  ViewToggle(month | week | day)
  CalendarMonthGrid(...)     // swipe gesture support added
  EventsCard(...)
```

#### 4c. ExpensesScreen (rename UI label to "Finance")

**Before:** "Expenses" + Import SMS inline + flat content
**After:**

```
PageShell(scrollable: false)
  PageHeader(
    eyebrow: 'MONEY',
    title: 'Finance',
    action: ImportSmsButton + AddButton (icon row)
  )
  PeriodFilterRow(today | week | month | year | all)
  SummaryCardsRow(income | expense | balance | savings rate)
  SpendingTrendChart(...)
  SectionHeader('By Category', action: BudgetButton)
  CategoryBreakdownList(...)
  SectionHeader('Transactions')
  TransactionGroupedList(...)
  FAB(add transaction)
```

#### 4d. TasksScreen

**Before:** Title + count subtitle + chips + list
**After:**

```
PageShell(scrollable: false)
  PageHeader(
    eyebrow: 'FOCUS',
    title: 'Tasks',
    subtitle: '${count} pending',
    action: SearchIconButton
  )
  CategoryFilterRow(all | work | growth | personal | bill)
  StatusFilterRow(all | pending | completed)
  TaskList(...)   — cards with category color left-bar accent
  FAB(add task)
```

TaskItemCard gets a left-edge category color bar (2px wide, rounded), matching
the RN TaskCard visual treatment. Category dot colors use the new `categoryColorFor`
token.

#### 4e. AssistantScreen

**Before:** CircleAvatar header + "BELTECH Assistant" + "Online" status
**After:**

```
PageShell(scrollable: false)
  PageHeader(
    eyebrow: 'AI COACH',
    title: 'Assistant',
    action: ClearChatsButton (icon only, shown when history exists)
  )
  ConversationChips(new | saved convos)
  Expanded → MessageList or QuickPromptGrid
  AnimatedComposer(keyboard-aware, GlassCard input row)
```

The CircleAvatar is removed. "Online" status badge is removed. The composer
timing is already correct (180ms, matches RN); the keyboard inset animation
just needs verification.

#### 4f. ProfileScreen

**Before:** Three unlabeled icon buttons at top + flat settings list
**After:**

```
PageShell(scrollable: true)
  PageHeader(
    eyebrow: 'ACCOUNT',
    title: 'Profile',
  )
  ProfileIdentityCard(avatar, name, email, member since)
  SectionHeader('Personal')
  EditProfileRow
  SectionHeader('Security')
  BiometricRow + PasswordRow
  SectionHeader('Workspace')
  ToolHubGrid(Analytics | Recurring | Export | Search | Settings)
  DangerSection
    SignOutButton(variant: danger)
  VersionLabel
```

The three unlabeled icon buttons are removed. Navigation to Analytics and Settings
moves into the `ToolHubGrid`, a 2-column grid of `GlassCard(muted)` tap targets
with icon + label, matching RN's workspace tools section.

#### 4g. Secondary Screens (Analytics, Settings, Budget, Recurring, Export, Income, Search)

All secondary screens get a shared `SecondaryPageShell` that wraps them:

```dart
SecondaryPageShell(
  title: 'Analytics',    // used in back-nav header
  child: ...,
)
```

This widget renders:
- A back arrow + title row (replacing the `AppBar` where it exists, or adding
  one where it's missing)
- Same `PageShell` atmospheric background treatment
- Consistent top + horizontal padding

Currently some of these screens have `AppBar`, some don't. After this phase
they all use the same back-navigation header pattern.

**Deliverables:** Updated versions of all 6 tab screens + 7 secondary screens.

---

### Phase 5 — Consistency Sweep

**Goal:** Find and eliminate every inconsistency that wasn't addressed in Phases 1–4.

#### 5a. Replace all inline `styleFrom(...)` button calls with `AppButton`

Search every file for `FilledButton.styleFrom`, `OutlinedButton.styleFrom`,
`TextButton.styleFrom` and replace with the appropriate `AppButton` variant.

#### 5b. Replace all inline `Text(...)` title calls with `AppTypography`

Replace direct `textTheme.titleLarge` / `textTheme.bodyMedium` calls with
`AppTypography.pageTitle(context)` etc. where the semantic name is clearer.

#### 5c. Normalize GlassCard usage

Audit every `GlassCard` call for:
- Correct tone (standard / accent / muted)
- Consistent `borderRadius` (use `AppRadius` tokens, not raw ints)
- Consistent `padding` (use `AppSpacing` values, not raw EdgeInsets)

#### 5d. Dialog consistency

All dialogs currently use `showAppDialog(...)` which is good. Audit all dialog
builders for consistent use of `AppButton`, `AppTypography`, and padding.

#### 5e. Empty states

Every list screen (Tasks, Expenses, Calendar, Recurring, Search) has a different
empty state treatment. Create a shared `AppEmptyState` widget:

```dart
AppEmptyState(
  icon: Icons.task_alt_rounded,
  title: 'No tasks yet',
  subtitle: 'Tap + to add your first task',
  action: AppButton(label: 'Add Task', ...),
)
```

#### 5f. Loading states

All loading spinners use `LoadingIndicator()`. Verify every screen uses it
consistently — no raw `CircularProgressIndicator` calls.

#### 5g. FAB positioning

All FABs should use `AppSpacing.fabBottom` for bottom offset. Audit and normalize.

---

## File Change Summary

### New files (10)

```
lib/core/theme/app_typography.dart
lib/core/theme/app_radius.dart
lib/core/widgets/app_button.dart
lib/core/widgets/page_shell.dart
lib/core/widgets/page_header.dart
lib/core/widgets/app_search_bar.dart
lib/core/widgets/section_header.dart
lib/core/widgets/app_empty_state.dart
lib/core/navigation/widgets/app_tab_bar.dart
lib/core/widgets/secondary_page_shell.dart
```

### Modified files (major)

```
lib/core/theme/app_colors.dart          ← new tokens (textMuted, glow, category)
lib/core/theme/app_spacing.dart         ← new constants (sectionGap, cardGap, listGap)
lib/core/widgets/glass_card.dart        ← muted tone
lib/core/navigation/app_shell.dart      ← use AppTabBar, rename Expenses→Finance tab
lib/features/home/presentation/home_screen.dart
lib/features/calendar/presentation/calendar_screen.dart
lib/features/expenses/presentation/expenses_screen.dart
lib/features/tasks/presentation/tasks_screen.dart
lib/features/tasks/presentation/widgets/task_item_card.dart
lib/features/assistant/presentation/assistant_screen.dart
lib/features/profile/presentation/profile_screen.dart
lib/features/analytics/presentation/analytics_screen.dart
lib/features/settings/presentation/settings_screen.dart
lib/features/budget/presentation/budget_screen.dart
lib/features/recurring/presentation/recurring_screen.dart
lib/features/export/presentation/export_screen.dart
lib/features/income/presentation/income_screen.dart
lib/features/search/presentation/global_search_screen.dart
```

### Not touched

All `data/`, `domain/`, provider, repository, and service files remain unchanged.
This revamp is **presentation-layer only**.

---

## Execution Order

```
Phase 1   Design tokens        (app_colors, app_typography, app_radius, app_spacing)
Phase 2   Core widgets         (glass_card, app_button, page_shell, page_header, etc.)
Phase 3   Navigation shell     (app_tab_bar, app_shell update)
Phase 4   Screens
  4a  HomeScreen
  4b  CalendarScreen
  4c  ExpensesScreen
  4d  TasksScreen
  4e  AssistantScreen
  4f  ProfileScreen
  4g  Secondary screens
Phase 5   Consistency sweep    (buttons, typography, dialogs, empty states, loading)
```

Each phase builds on the last. Phases 1–3 can be reviewed visually by running
the app and checking the shell + home tab before moving to 4–5.

---

## What This Revamp Is Not

- It does not add or remove features
- It does not change routing
- It does not change data flow, providers, or repositories
- It does not introduce new dependencies (all required packages already exist)
- It does not change the Supabase schema or edge functions

---

*Ready to begin. Phase 1 is the natural starting point — design tokens first,
everything else builds on them.*
