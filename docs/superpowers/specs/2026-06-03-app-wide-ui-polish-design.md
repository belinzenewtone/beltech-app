# App-Wide UI/UX Polish Design Spec

## Date: 2026-06-03
## Scope: All screens, components, and form sheets
## Reference: React Native app screenshots (47 images in `REACT FINAL/`)

---

## 1. Problem Statement

The Flutter app has the following issues across **all screens** (main tabs + deep pages):

1. **Inconsistent design system** — `GlassCard` styling varies, typography sizes differ across screens, spacing is ad-hoc
2. **Overlapping / illegible colors** — `surfaceMuted` text on `surfaceElevated` backgrounds in some places; `ListTile` inside `GlassCard` creates visual noise; some category colors clash with card backgrounds
3. **Text cut-off** — Missing `maxLines`/`overflow` on many `Text` widgets; `FittedBox` causes unpredictable sizing
4. **Slow page loads** — Screens like `ExpensesScreen` watch 8+ providers simultaneously causing excessive rebuilds; `HomeScreen` triggers sync on every mount
5. **"Afterthought" feel on deep pages** — Goals, Loans, Learning use plain `Text` for empty states, `ListTile` inside glass cards, inconsistent currency labels (`XAF` vs `KES`)

---

## 2. Design Principles (from RN Reference)

1. **Dark, solid surfaces** — No heavy glassmorphism blur. Cards are solid `surface` or `surfaceElevated` with subtle `border` (1px). Flat, not glossy.
2. **Consistent border radius** — Cards: 16px. Buttons: full rounded (pill). Input fields: 12px.
3. **Minimal shadows** — No large box shadows. At most a subtle 4px blur for elevation.
4. **Single accent color** — Teal (`#0F766E`) for all primary actions, active states, and highlights.
5. **Clean typography hierarchy**:
   - Screen titles: 28px, weight 700
   - Card titles: 16px, weight 600
   - Body: 14px, weight 400
   - Labels/captions: 12-13px, weight 500
   - Stats/numbers: 20-24px, weight 700
6. **Generous whitespace** — 20px between sections, 16px inside cards, 12px between list items.
7. **Full-width primary buttons** — All create/submit buttons are full-width, pill-shaped, teal fill.

---

## 3. Foundation Changes (Affect All Screens)

### 3.1 GlassCard Standardization

Current problems:
- `borderRadius: 22` — too round, feels bubbly
- `shadow blurRadius: 14` — too heavy, looks outdated
- `padding: EdgeInsets.all(16)` — sometimes too much, sometimes not enough

New spec:
```dart
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 16,        // CHANGED: 22 -> 16
    this.tone = GlassCardTone.standard,
    this.accentColor,
    this.onTap,
  });
```

Shadow changes:
- Remove `shadow blurRadius: 14` → use `blurRadius: 4, offset: Offset(0, 2)` or remove entirely
- Border stays at 1px with current colors

### 3.2 PageShell Bottom Padding Fix

Current: `contentBottomSafe = 172` — excessive empty space at bottom of scrollable pages.

New: `contentBottomSafe = 24` — let content breathe but don't force huge gaps. The nav bar already has its own safe area padding.

### 3.3 Typography Standardization

Current issues:
- Home "Today" header is 32px — RN is ~28px
- Various screens use different header sizes
- `AppTypography.title(context)` and `AppTypography.headlineMd` are used inconsistently

New tokens (add to `AppTypography`):
```dart
static TextStyle screenTitle(BuildContext context) =>
    Theme.of(context).textTheme.headlineMedium!.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    );

static TextStyle cardTitle(BuildContext context) =>
    Theme.of(context).textTheme.titleLarge!.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );

static TextStyle statNumber(BuildContext context) =>
    Theme.of(context).textTheme.headlineSmall!.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    );
```

### 3.4 Text Overflow Protection

Rule: **Every `Text` widget that displays dynamic data must have `maxLines` and `overflow` set.**

Audit all screens and add:
```dart
Text(
  dynamicValue,
  maxLines: 1,           // or 2 where appropriate
  overflow: TextOverflow.ellipsis,
)
```

Remove `FittedBox` from `HomeSpendSnapshotStrip` — use fixed font sizes with overflow protection.

### 3.5 Layout Stability (Anti-Jitter)

**Rule: No layout shifting when content changes.** This applies to ALL forms, bottom sheets, and expandable sections across the app.

Problems found:
- `super_add_sheet.dart`: Switching tabs (Task→Event→Birthday) causes content to jump because the `Column` height changes inside `AppFormSheet`'s scroll view
- `super_add_sheet.dart`: Expanding/collapsing "Hide details" shifts the visible viewport
- `event_dialogs.dart`: Same issue when form content changes
- Any form with `StatefulBuilder` inside a scrollable will exhibit this if not handled

Fixes:
1. Wrap dynamic content sections in `AnimatedSize` with `clipBehavior: Clip.none` so height changes animate smoothly instead of jumping
2. Keep the kind selector / tab bar in a fixed-height container so it never shifts vertically
3. Use a `ScrollController` maintained across rebuilds so the scroll offset doesn't reset
4. Ensure `AppFormSheet`'s internal scroll view uses `physics: const ClampingScrollPhysics()` to prevent overscroll bounce that amplifies jitter

### 3.6 Performance Fixes

**ExpensesScreen:**
- Group related providers: `expenseReviewQueueProvider`, `expenseQuarantineQueueProvider`, `expensePaybillProfilesProvider`, `expenseFulizaLifecycleProvider` are only needed for the advanced section
- Use `select()` to only rebuild on `isLoading` changes, not full state objects

**CalendarScreen:**
- The Month/Week/Day view selector adds complexity. Keep Month as primary, but simplify the nested tab structure.

**HomeScreen:**
- Keep the 60-second debounce on sync, but add a check: only sync if user has been away > 30 seconds

---

## 4. Screen-by-Screen Changes

### 4.1 Home Screen (Already Best — Minor Polish)

- Reduce "Today" header from 32px → 28px
- Remove `FittedBox` from spending snapshot strip
- Ensure tool pills use consistent border radius (16px pill)

### 4.2 Finance / Expenses Screen (High Priority)

- Fix `horizontalPadding: 0` with manual padding — restore standard padding and let banner be edge-to-edge via `margin: EdgeInsets.symmetric(horizontal: -24)` if needed
- Remove heavy provider rebuilds
- Standardize transaction list item card styling
- Fix import health banner colors — ensure text is legible on the banner background

### 4.3 Calendar Screen (High Priority)

**Critical fix:** Remove the double tab bar.
- Keep only the Month | Tasks | Events segmented control (matching RN)
- Remove the second Month/Events/Tasks selector inside the month view
- Week/Day views accessible via swipe, not tabs

### 4.4 Profile Screen (Already Good — Minor Polish)

- Profile hero card: make the teal background solid (not glassmorphism) with dark inner tool hub cards
- Ensure tool hub uses consistent grid spacing

### 4.5 Goals Screen (High Priority — Currently Plain)

Current issues:
- Empty state is `Center(child: Text('No goals yet'))` — no styling
- Uses `ListView.builder` with `GoalItemCard` but needs consistent card styling
- Floating action button label is just "Goal" — should be "Add Goal" or use the FAB style from RN

Changes:
- Empty state: use `AppEmptyState` with icon, title, subtitle
- Ensure `GoalItemCard` uses standardized `GlassCard` (radius 16, subtle border)
- FAB: match RN style (circular with + icon, no label, or full-width pill if extended)

### 4.6 Bills Screen (Medium Priority)

- Fix delete dialog: replace `AlertDialog` with a styled bottom sheet or custom dialog matching RN
- Ensure section headers use standardized `eyebrow` typography
- Check commitment card — ensure teal accent doesn't clash with warning color

### 4.7 Loans Screen (High Priority)

Current issues:
- Currency shows `XAF` instead of `KES` — **bug**
- Empty state is plain `Text`
- `GlassCard` with nested `Padding` creates double padding

Changes:
- Fix currency to `KES`
- Empty state: use `AppEmptyState`
- Remove double padding — let `GlassCard` handle its own padding
- Ensure outstanding amount uses `statNumber` typography

### 4.8 Learning Screen (High Priority)

Current issues:
- Uses `ListTile` inside `GlassCard` — looks very Material, not matching RN clean cards
- `ListTile.leading` is just `Icon(Icons.school_outlined)` — no styled circle avatar background
- Date format is `d/M/yyyy` — should match RN format
- Streak/monthly cards are too compact

Changes:
- Replace `ListTile` with custom row layout: circle avatar with icon → title + subtitle column → trailing action
- Add circle avatar backgrounds with subtle color tints (like RN)
- Standardize date format
- Make streak cards larger with proper spacing

### 4.9 Settings Screen (Already Good — Consistency Only)

- Ensure all toggle rows use consistent padding and icon sizing
- Check that section headers match `eyebrow` style

### 4.10 Insights / Analytics Screens (Already Good — Consistency Only)

- Ensure stat cards use standardized `statNumber` style
- Check chart colors against RN reference

### 4.11 Form Sheets / Bottom Sheets (High Priority)

Current issues:
- `AppFormSheet` uses gradient background — RN uses solid dark background
- Input fields have inconsistent styling across different form sheets
- Some forms use `TextField` without proper dark theme styling
- Priority/category selectors use different chip styles across Task vs Event vs Bill forms

Changes:
- Simplify `AppFormSheet` background: solid `surface` color, no gradient
- Standardize all input fields: `filled: true`, `fillColor: surfaceMuted`, `borderRadius: 12`, subtle border
- Standardize all selection chips (Priority, Category, Frequency): pill shape, 1px border, selected = teal fill
- Ensure all submit buttons are full-width, pill-shaped, teal

---

## 5. Color / Legibility Fixes

Specific fixes for overlapping/illegible colors:

1. **LearningScreen ListTile inside GlassCard**: The default `ListTile` text colors are designed for Material surfaces, not dark glass cards. Replace with custom row.
2. **ExpensesScreen ImportHealthBanner**: Ensure the banner background color has enough contrast with its text. If banner uses `surfaceAccent`, text must be `textPrimary` or white.
3. **BillsScreen CommitmentCard**: The warning icon on warning-muted background — verify this is visible in dark mode.
4. **Category chips across the app**: Ensure `categoryColorFor()` colors have sufficient contrast against `surface` backgrounds. Some colors like `slate` (`#475569`) may be too close to `surface` (`#151B22`).
5. **Calendar WeekView day cells**: Selected day uses `AppColors.accent` fill — verify the day number text color switches to white/light when selected.

---

## 6. Implementation Phases

### Phase 1: Foundation (Affects all screens)
- [ ] Standardize `GlassCard` (radius 16, lighter shadow)
- [ ] Fix `PageShell` bottom padding
- [ ] Add standardized typography tokens
- [ ] Add text overflow audit script / fixes
- [ ] Performance: narrow provider rebuilds in ExpensesScreen

### Phase 2: Main Tab Screens
- [ ] Home: header size, snapshot strip
- [ ] Finance: padding structure, provider optimization
- [ ] Calendar: remove double tabs
- [ ] Profile: hero card polish

### Phase 3: Deep Pages (Most "Off")
- [ ] Goals: empty state, card styling
- [ ] Loans: currency fix, empty state, card styling
- [ ] Learning: replace ListTile, date format, card sizing
- [ ] Bills: delete dialog, section headers
- [ ] Budget, Income, Recurring: consistency pass

### Phase 4: Forms & Sheets
- [ ] Simplify AppFormSheet background
- [ ] Standardize input fields across all forms
- [ ] Standardize chip selectors
- [ ] Standardize submit buttons

### Phase 5: Color Legibility
- [ ] Fix specific contrast issues listed in Section 5
- [ ] Verify all category colors on dark backgrounds

### Phase 6: Verification
- [ ] `flutter analyze` — 0 errors
- [ ] Visual QA on all screens
- [ ] Performance test: tab switching should feel instant

---

## 7. Success Criteria

1. **Every screen** uses the same `GlassCard` styling, same typography tokens, same spacing
2. **No text is cut off** on any screen at any font scale (test with accessibility large text)
3. **Tab switching** between Home/Finance/Calendar/AI/Profile feels instant (< 100ms perceived)
4. **All empty states** use styled `AppEmptyState` with icon, not plain text
5. **All colors** pass basic contrast check (text readable on its background)
6. **All forms** look and behave consistently (same input style, same chip style, same submit button)
7. **flutter analyze** reports 0 errors

---

## 8. Files Expected to Change

**Foundation:**
- `lib/core/widgets/glass_card.dart`
- `lib/core/widgets/page_shell.dart`
- `lib/core/theme/app_typography.dart`
- `lib/core/theme/app_spacing.dart`

**Main Tabs:**
- `lib/features/home/presentation/home_screen.dart`
- `lib/features/home/presentation/widgets/home_spending_cards.dart`
- `lib/features/expenses/presentation/expenses_screen.dart`
- `lib/features/calendar/presentation/calendar_screen.dart`
- `lib/features/calendar/presentation/calendar_screen_layout.dart`
- `lib/features/profile/presentation/profile_screen.dart`
- `lib/features/profile/presentation/widgets/profile_content_section.dart`

**Deep Pages:**
- `lib/features/goals/presentation/screens/goals_screen.dart`
- `lib/features/goals/presentation/widgets/goal_item_card.dart`
- `lib/features/loans/presentation/screens/loans_screen.dart`
- `lib/features/loans/presentation/widgets/loan_item_card.dart`
- `lib/features/learning/presentation/screens/learning_screen.dart`
- `lib/features/bills/presentation/screens/bills_screen.dart`
- `lib/features/bills/presentation/widgets/bill_item_card.dart`
- `lib/features/budget/presentation/budget_screen.dart`
- `lib/features/income/presentation/income_screen.dart`
- `lib/features/recurring/presentation/recurring_screen.dart`

**Forms:**
- `lib/core/widgets/app_form_sheet.dart`
- `lib/features/tasks/presentation/widgets/task_dialogs.dart`
- `lib/features/expenses/presentation/widgets/expense_dialogs.dart`
- `lib/features/bills/presentation/widgets/bill_form_sheet.dart`
- `lib/features/loans/presentation/widgets/loan_form_sheet.dart`
- `lib/features/goals/presentation/widgets/goal_form_sheet.dart`
- `lib/features/learning/presentation/widgets/learning_form_sheet.dart`

**Estimated total: 25-30 files**

---

*This spec is ready for review. Once approved, an implementation plan will be written before any code changes.*
