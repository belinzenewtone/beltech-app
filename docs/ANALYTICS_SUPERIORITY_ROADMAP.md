# Flutter Analytics — Superiority Roadmap

**Goal:** Close every gap against the Kotlin app's analytics/insights/review surface, then surpass it on motion, visual system, accessibility, and net-new features. We are not matching Kotlin — we are making Flutter better in every UI aspect.

**Timeline:** 4 phases + cross-cutting foundations · ~15–19 days

**Legend:**
- ↑ **Exceeds Kotlin** — Flutter version is noticeably better than what Kotlin has
- ≈ **Closes gap** — brings Flutter to feature parity with Kotlin
- ★ **Net-new** — feature that doesn't exist anywhere in the Kotlin app

---

## ✓ Prerequisite — build is green (resolved)

The `assembleDebug` failure is fixed. `flutter run` now succeeds. Root causes that were corrected:

1. **`compileSdk = 37 → 36`** — AGP 8.11.1 can't handle Android SDK 37 (platform installs as `android-37.0` but AGP looks for `android-37`).
2. **Kotlin `2.1.20 → 2.2.20`** — Flutter's Gradle plugin requires Kotlin 2.2.20+.
3. **`sourceCompatibility = VERSION_21 → VERSION_17`** — the machine has JDK 17, so Java 21 source/target failed with `invalid source release: 21`.
4. **Third-party plugin buildscript blocks removed** — `sqlcipher_flutter_libs` and `flutter_windowmanager` in `third_party/` had hardcoded AGP versions (8.0.1 and a nonexistent 9.1.0) conflicting with the project's AGP 8.11.1 + `android.newDsl=true`.
5. **`--enable-native-access=ALL-UNNAMED`** added to `gradle.properties` to suppress Java native-access warnings.

> Note: the fix pinned the toolchain to **JDK 17 / Java 17 target**. Keep new code and any Gradle changes on Java 17 — don't reintroduce Java 21 source/target settings. Phase 0 can begin.

---

## Cross-cutting threads — woven through every phase, never a separate stage

| Thread | What it means |
|---|---|
| **Design tokens** | One source of truth for category colours (light + dark), the type scale, and currency. Built in Phase 1's Foundation block, consumed everywhere after. Kotlin scatters hardcoded hex and mixes two currency formats. |
| **Motion-safety** | Every animation checks `MediaQuery.disableAnimations` and degrades to an instant state. Motion must never gate comprehension. |
| **Accessibility** | ≥48dp touch targets, `Semantics` on every chart, 200% text-scale resilience, WCAG-AA contrast in both themes. Kotlin's Compose charts are silent to screen readers. |
| **Verification** | Golden tests lock each widget's pixels; widget tests cover interaction. Flutter's structural edge — this repo's Kotlin has no comparable per-widget visual snapshot. |

**Definition of Done (per task):** complete only when its widget has a passing **golden test** + **interaction test**, renders correctly in **light and dark**, survives **200% text scale** without overflow, and behaves with **animations disabled**. Ship each phase behind a flag so partial work never reaches users.

---

## Phase 0 — Hotfixes & Quick Wins (~4 hours)

Data bugs, missing copy, and one-line UI additions. Do these before anything else — some are silent regressions.

| Task | Type | Effort |
|---|---|---|
| **Fix `AnalyticsSnapshot ==`** — add `feesPaidKes`, `postIncomeAvgDailySpendKes`, `otherDaysAvgDailySpendKes` to the equality operator and `hashCode`. When only these change, Riverpod sees the snapshot as unchanged and the Fees card + Payday Pulse silently show stale data. | ≈ | 5 min |
| **Monthly Wrapped nav** — disable ← when `!hasData`. `_prev()` currently has no lower bound; users tap back forever into empty states. Mirror Kotlin's `enabled = state.hasData`. | ≈ | 10 min |
| **Fees card** — surface `topFeeCategory`. Add to the fees SQL query (group by category, order by sum of fee DESC, take first), add to `AnalyticsSnapshot`, render in `analytics_fees_card.dart`. | ≈ | 25 min |
| **Payday Pulse** — add `incomeEventsCount` + percentage sentence. Subtitle "N income events · avg daily spend" and message "You spend X% more in the 7 days after income arrives" (or disciplined variant). | ≈ | 20 min |
| **Monthly Wrapped verdict** — add "Income KSh X · Spend KSh Y" breakdown line in `_VerdictCard`. Both values already in `MonthlyWrappedData`. | ≈ | 10 min |
| **Fuliza card** — add advice text: "Try to keep this below 3 times per month." | ≈ | 5 min |
| **Monthly Trend** — highlight current month bar label in `primary` + `FontWeight.w700`; add "Tap a bar to view Wrapped →" hint in the legend. | ≈ | 10 min |
| **Insights tab** — Average Monthly + Total Tracked stat cards below the bar chart. Data already in `monthlyHistory`. | ≈ | 20 min |
| **Category sparklines** — global max normalization. Each `_Sparkline` currently normalizes against its own max. **Kotlin already computes a global max** — this is a regression in the current Flutter port, not an enhancement. Pass one `globalMax` from `CategorySpendCards` to every `_CategoryCard`. | ≈ | 20 min |
| **Spending comparison pill** — human-readable copy ("Spent KSh X more" / "Saved KSh X") instead of icon + compact delta. | ≈ | 10 min |

---

## Phase 1 — Foundations + Feature Parity (5–6 days)

Build the shared foundation everything depends on, then build every screen/section that exists in Kotlin but is absent in Flutter.

### Foundation — build first, everything below and every later phase depends on it

**Design tokens: category colours + type scale + currency** — ↑ Exceeds Kotlin — *2 h*
The most leveraged task in the whole plan. Create `lib/core/theme/category_colors.dart` mapping all 16 categories (food→amber, transport→blue, utilities→purple, groceries→teal, rent→red, airtime→cyan, entertainment→pink, health→orange, education→indigo, shopping→fuchsia, savings→green, investment→teal-2, bills→amber-2, housing→red-2, loans→dark-red, default→slate) with **separate light and dark variants**. Kotlin reuses one hex in both themes — a contrast flaw to fix here.
- Expose as a `ThemeExtension` so widgets read `Theme.of(context).extension<CategoryColors>()` — theme-reactive, not a global function.
- Define the analytics type scale as documented constants (consumed by the Phase 3 typography audit).
- Unify on one `CurrencyFormatter`. The audit found Kotlin mixes `"Ksh X"` inline with `formatCurrency()` — Flutter should have exactly one path.

**Motion-safety + chart-semantics primitives** — ★ Net-new — *1.5 h*
Build the shared helpers Phases 2–4 depend on, so they are correct by default: an `AppMotion` helper that reads `MediaQuery.disableAnimations` and returns `Duration.zero` when set (every later animation degrades gracefully), and a `ChartSemantics` wrapper that attaches a spoken `Semantics` label to any chart (e.g. "Spending trend, 6 months, highest in March"). Kotlin ships neither.

### Insights Tab

**Monthly History Breakdown section** — ≈ Closes gap — *1.5 days*
The biggest missing section. Kotlin renders 6 expandable month cards — each shows month label, ±% delta badge, total, and tx count, expanding to top-5 category bars.
- Create `lib/features/analytics/presentation/widgets/monthly_breakdown_section.dart`. Takes `List<MonthlyTotalPoint> history` and the full `categoryBreakdown`.
- Each card: month label + `_DeltaBadge` pill (±X.X% in danger/success) + total + tx count in a header row.
- Expandable body with top-5 categories (requires one extra SQL query grouping by category within each month's window).
- Use `AnimatedSize` for expand/collapse + `AnimatedRotation` on the chevron. Kotlin has no animation here — this immediately exceeds it.
- Render between the month highlight tiles and the InsightsSection in `_InsightsTab`.

**Insights tab — "Top Category All Time" insight row** — ≈ Closes gap — *30 min*
Kotlin includes this alongside Highest/Lowest Month and Trend. Compute the all-time top category, render as a fourth row in the `_MonthHighlightRow` area with the category's colour dot.

### Fee Analytics Screen

**New: `FeeAnalyticsScreen` — dedicated service charges screen** — ≈ Closes gap — *1 day*
Kotlin has a standalone screen from the main nav. Create `lib/features/analytics/presentation/fee_analytics_screen.dart`.
- Add a repository method returning fee data grouped by category for the current calendar month.
- Layout: total fees in large display type, category breakdown bars, list of recent fee transactions.
- Register `/fee-analytics` route; a tap on `AnalyticsFeesCard` navigates here.
- Add `feeAnalyticsRepositoryProvider` + `feeAnalyticsProvider`.

### Weekly Review Screen

**New: Financial Health Score — domain logic** — ≈ Closes gap — *45 min*
Create `lib/features/review/domain/` with the health score algorithm (matches Kotlin): base 50; +20 if spend ≤ prev week, +10 if ≤20% increase, -20 if >50% increase; +20 if 0 uncategorized, +10 if ≤3, -10 if >8; +10 if no fuliza, -10 if >2; +10 if task completion ≥80%, +5 if ≥50%. Clamp [0,100].

**New: `ReviewScreen` — weekly ritual screen** — ≈ Closes gap — *2 days*
The highest-value missing screen. Create `lib/features/review/presentation/review_screen.dart`.
- **Health Score Ring:** `CustomPainter` arc. Tiers: ≥80 success, ≥60 amber, ≥40 warning, else danger. Score centred; label "Excellent"/"Good"/"Fair"/"Needs attention".
- **7-Day Spend Bars:** Mon–Sun; future = faint stub, 0 = stub, ≤avg = success, ≤avg×1.5 = amber, else = danger.
- **What Changed card:** dynamic bullet list — spend up → danger item, down → primary; each overdue task; top category. `ReviewStatRow` with monospace value column.
- **Wins / Risks / Review Ritual cards:** numbered bullet lists with dividers; context-aware review prompt at bottom.
- Register `/weekly-review` route; add entry point from analytics screen or main nav.

### Data Layer

**Convert `MonthlyWrappedScreen` to `StreamProvider`** — ≈ Closes gap — *45 min*
Currently `FutureProvider.family` — single fetch, no auto-refresh. Update `monthly_wrapped_repository_impl.dart` to return a `Stream` via `watchChangeStream()`, change `monthlyWrappedProvider` to `StreamProvider.family`. Data now updates on any transaction change, matching Kotlin.

---

## Phase 2 — Motion & Interaction Uplift (3–4 days)

Kotlin is almost entirely static. This is where Flutter decisively pulls ahead — Kotlin's static canvas draws are a ceiling it can't break without a rewrite. Every animation routes through the `AppMotion` helper from Phase 1.

### Animated charts — every bar fills on entry

| Task | Type | Effort |
|---|---|---|
| **Staggered bar entry on Monthly Trend** — `TweenAnimationBuilder<double>` per bar, staggered by `index * 50ms`, 350ms `easeOutCubic`. | ↑ | 1 h |
| **Animated fill on Spend Anatomy, Payday Pulse, Fee Analytics bars** — replace static `LinearProgressIndicator`s with tween-driven bars, 500ms `easeOut`; stagger anatomy tiers by 80ms. | ↑ | 1.5 h |
| **Health Score ring — animated arc draw 0→score** — wrap the `CustomPainter` sweep in a tween, 600ms `easeOutQuart`. | ↑ | 45 min |
| **7-day Review bars — staggered entry + tap-to-reveal tooltip** — `ValueNotifier<int?>` for selection; `Overlay`-positioned pill with `AnimatedOpacity` + `AnimatedScale` (200ms); stagger bars 40ms. | ↑ | 2 h |

### Interactive charts

| Task | Type | Effort |
|---|---|---|
| **Monthly Trend — tap-to-highlight + floating amount tooltip.** On tap: highlight bar + show KES pill. Navigation to Wrapped moves to second tap / long-press. | ↑ | 1.5 h |
| **Animated expand/collapse** on category cards + monthly breakdown — `AnimatedSize` (300ms `easeInOutCubic`), `AnimatedRotation` chevron, staggered `FadeTransition` on revealed cards. | ↑ | 1 h |

### Navigation & transitions

| Task | Type | Effort |
|---|---|---|
| **Swipe-to-navigate months in Monthly Wrapped** — horizontal `PageView` + `PageController`; arrows become secondary. Hard cap: no future months. | ↑ | 2 h |
| **Custom route transitions** — Monthly Wrapped + Weekly Review slide up (modal); Fee Analytics slides in from right. GoRouter `CustomTransitionPage`. | ↑ | 45 min |

### Micro-interactions

| Task | Type | Effort |
|---|---|---|
| **Animated number countup on Summary Cards** — `TweenAnimationBuilder` keyed on period, 600ms `easeOutExpo`. | ↑ | 1 h |
| **Haptic feedback** — `selectionClick()` on chip/bar/arrow taps; `lightImpact()` on month swipe + card expand. Kotlin has none. | ★ | 30 min |
| **`AnimatedSwitcher` on data cards when period changes** — cross-fade (200ms) keyed on `AnalyticsPeriod`. | ↑ | 45 min |

---

## Phase 3 — Visual System + Accessibility (3–4 days)

Cohesive visual language + the accessibility work that makes "better in every UI aspect" real.

### Accessibility & inclusive design

| Task | Type | Effort |
|---|---|---|
| **Touch-target & contrast audit** — every tappable element ≥48×48dp; WCAG-AA contrast check on every text/background pair in both themes. Muted 45%-opacity labels are the likely failures. | ↑ | 2 h |
| **Screen-reader semantics on every chart** — use `ChartSemantics` from Phase 1. `CustomPainter` charts are invisible to a11y services unless labelled; Kotlin's aren't labelled at all. | ★ | 1.5 h |
| **200% text-scale resilience** — test at `textScaleFactor: 2.0`. Summary values, pills, 2×2 grid are overflow danger zones. Fix with `FittedBox`, flexible layouts, `softWrap`. | ↑ | 1.5 h |

### Shimmer skeletons

**Layout-accurate shimmer** on Analytics tab, Insights tab, and Monthly Wrapped — ↑ — *1.5 h*
- Shared `ShimmerBox` widget (`AnimatedContainer` + gradient sweep, no library).
- Analytics skeleton: two rows of 2 boxes + wide bar + three category rows.
- Insights skeleton: wide box + two squares + three row boxes.
- Monthly Wrapped skeleton: large amount box + three category rows + two side-by-side cards.

### Charts

| Task | Type | Effort |
|---|---|---|
| **Monthly Trend bars — gradient fill** above/below threshold via `CustomPainter` (danger→danger@50% / success→success@50%). | ↑ | 45 min |
| **Financial Health Gauge — wire into Insights tab header** — semi-circular `CustomPainter` arc, `SweepGradient` green→teal→amber→red, `StrokeCap.round`. Kotlin has this composable but it's dead code. | ↑ | 2 h |

### Empty states & typography

| Task | Type | Effort |
|---|---|---|
| **Illustrated empty states** — inline SVG/`CustomPainter` sketches (bar chart + magnifier; calendar + question; clock + check). Theme-aware, 80–100px. | ↑ | 2 h |
| **Enforce consistent type scale** across all analytics screens; document in `lib/core/theme/analytics_text_styles.dart`. | ↑ | 1.5 h |
| **Pull-to-refresh** with custom-coloured `RefreshIndicator` on both Analytics tabs. Kotlin has only an app-bar icon. | ↑ | 20 min |

---

## Phase 4 — Beyond Kotlin: Net-New Features (3–4 days)

Features that do not exist anywhere in the Kotlin app.

**Share Monthly Wrapped as a card image** — ★ — *1 day*
`RepaintBoundary` + `GlobalKey` → `boundary.toImage()` → PNG → `Share.shareXFiles` (share_plus). Branded standalone card: month header, total, top 3 categories, verdict.

**Category drill-down → filtered transaction list** — ★ — *1 day*
Long-press/chevron on `_CategoryCard` → `/analytics/category/:category` scoped to category + current period. Kotlin never lets users drill into transactions from analytics.

**Custom date range selector** — ★ — *1.5 h*
Third chip / "Custom…" → `showDateRangePicker`. Extend `watchSnapshot` with optional `DateTimeRange? custom`. Kotlin only has This Week / This Month.

**Surface top insight inline on Analytics tab header** — ★ — *45 min*
Highest-confidence `InsightCard` as a compact banner with coloured stripe + "→ Insights" tap target. Kotlin's analytics tab has no insight surfacing.

**Dark-mode-specific chart palette** — ★ — *1 h*
Extend the Phase 1 tokens: dark-mode danger = warmer red (`#FF6B6B`), success = more saturated teal-green. Separate tokens, no light-mode impact. Kotlin's hardcoded ARGB longs cause contrast issues on dark backgrounds.

**Inline "vs same period last year" toggle** — ★ — *1.5 h*
Secondary toggle in the comparison card: "vs last period" ↔ "vs same period last year". One extra SQL query (identical window − 12 months). Kotlin only compares vs the prior period.

**Spend velocity micro-chart on summary cards** — ★ — *1.5 h*
Render the currently-unused `weeklySpending` series as a 32px `CustomPainter` sparkline with 10% area fill below the Spend card value — the shape of spending, not just the total.

---

## Why this order works

1. **Phase 0** fixes silent regressions first — nothing else matters if Riverpod serves stale data.
2. **Phase 1** builds the shared foundation (colours, motion-safety, semantics) *before* the features that consume it, then reaches full content parity with Kotlin.
3. **Phase 2** is the decisive differentiator — motion is where Kotlin's static architecture can't follow.
4. **Phase 3** makes the visual language cohesive and, critically, accessible — a dimension Kotlin's Compose charts fail.
5. **Phase 4** adds features with no Kotlin equivalent, putting the Flutter app in a different category.
