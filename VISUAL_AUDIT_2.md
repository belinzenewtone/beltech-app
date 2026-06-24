# 🎨 Flutter Visual Audit — Round 2
> **Scope:** DART-2.0-main UI/Visual Layer
> **Date:** 2026-03-29 | **Focus:** Glass effect correctness, color accuracy, RN parity, 10/10 polish
> **Status of Super Section (task + event unification):** ✅ Already implemented (`super_add_sheet.dart`)

---

## ✅ What Was Successfully Implemented Since Last Audit

Before diving into issues, here is a clear picture of what is already done well:

| Item | File | Status |
|---|---|---|
| Unified Super Add Sheet (tasks + events) | `core/widgets/super_add_sheet.dart` | ✅ Done |
| `SuperEntryKind` toggle (Task / Event) | `super_add_sheet_models.dart` | ✅ Done |
| Progressive disclosure ("More details" expander) | `super_add_sheet.dart` | ✅ Done |
| Reminder toggle + `reminderMinutesBefore` selector | `super_add_sheet_sections.dart` | ✅ Done |
| Event type selector in Super Sheet | `super_add_sheet_sections.dart` | ✅ Done |
| `startAt` / `endAt` / `dueAt` time semantics in model | `super_add_sheet_models.dart` | ✅ Done |
| `balanceAfterKes` field on `ExpenseTransactionRow` | `transaction_row.dart` | ✅ Done |
| AppCapsule chip system with icon support | `app_capsule.dart` | ✅ Done |
| Countdown badges on task cards (overdue / today / tomorrow) | `task_item_card.dart` | ✅ Done |
| AppRadius token system (sm/md/lg/xl/xxl) | `app_radius.dart` | ✅ Done |
| AppMotion + reduce-motion accessibility | `app_motion.dart` | ✅ Done |
| StaggerReveal entrance animations on dashboard | `home_screen.dart` | ✅ Done |
| `CategoryVisual` icon + background system | `category_visual.dart` | ✅ Done |
| Swipe-dismiss on both task cards and transaction rows | `task_item_card.dart`, `transaction_row.dart` | ✅ Done |
| Haptic feedback on all interactive elements | `app_haptics.dart` | ✅ Done |
| Inter (Google Fonts) typography across app | `app_theme_dark.dart` | ✅ Done |
| Full AppColors token system matching RN palette | `app_colors.dart` | ✅ Done |
| GlassStyles class defined with blur sigma + gradients | `glass_styles.dart` | ✅ Defined |

---

## 🔴 CRITICAL — Glass Effect is Not Actually Glass

This is the single biggest visual gap in the entire app and affects every surface.

### The Problem

`GlassCard` has **zero blur**. The word "glass" in the widget name is misleading — looking at the actual `build()` method, it uses a plain `Container` with a `BoxDecoration` filled with a **solid opaque colour** (`surfaceElevated = 0xFF1B2430`). There is no `BackdropFilter`, no `ImageFilter.blur()`, no frosted glass effect whatsoever.

Even worse: `GlassStyles` already defines the correct values (`blurSigma = 16.0`, `glassGradientFor()`, `accentGlassGradientFor()`) but **none of them are ever called inside `GlassCard.build()`**. They are dead code right now.

### Current `GlassCard` render pipeline
```
Container (solid surfaceElevated)
  └─ ClipRRect (clips child, but nothing to blur)
       └─ Padding
            └─ child
```

### What it should be
```
Container (margin only)
  └─ ClipRRect (border radius — must wrap BackdropFilter)
       └─ BackdropFilter (ImageFilter.blur sigmaX=16, sigmaY=16)
            └─ Container (GlassStyles.glassGradientFor() + border + shadow)
                 └─ Padding
                      └─ child
```

### The Fix — `glass_card.dart`

Replace the `innerDecoration` / `inner` widget block with:

```dart
import 'dart:ui'; // add this import at the top

// Inside build():
final gradient = switch (tone) {
  GlassCardTone.accent =>
    GlassStyles.accentGlassGradientFor(brightness, effectiveAccent),
  _ => GlassStyles.glassGradientFor(brightness),
};

Widget inner = Container(
  margin: margin,
  child: ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: GlassStyles.blurSigmaFor(brightness),
        sigmaY: GlassStyles.blurSigmaFor(brightness),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    ),
  ),
);
```

**Important:** `BackdropFilter` only produces a visible blur when there is content behind the widget to blur. The background atmosphere glows (see next section) feed this blur and are what make the effect look premium. Without background glows, BackdropFilter will just blur a solid dark background — still better than nothing, but the combination is what creates the RN look.

**Performance note:** Wrap each `GlassCard` in a `RepaintBoundary` if you see jank, since BackdropFilter triggers a compositor layer. The `ExpenseTransactionRow` already does this correctly.

---

## 🔴 CRITICAL — Background Atmosphere Glows Are Defined But Never Used

### The Problem

`AppColors` defines 4 glow colours:
```dart
static const Color glowBlue   = Color(0x3860A5FA); // 22% opacity blue
static const Color glowTeal   = Color(0x2E4FD1D9); // 18% opacity teal
static const Color glowIndigo = Color(0x298B6DFF); // 16% opacity indigo
static const Color glowAmber  = Color(0x29F59E0B); // 16% opacity amber
```

These are **never referenced anywhere** in the codebase. Not in `PageShell`, not in any screen. `PageShell.build()` renders a plain flat `Container(color: AppColors.background)` — solid `0xFF0B0F14`.

Without atmospheric radial glows behind your glass cards, `BackdropFilter` is just blurring a flat dark wall. The glows are what feed the glass effect with colour and depth.

### The Fix — `page_shell.dart`

Wrap the background in a `Stack` with positioned radial glow containers:

```dart
return Container(
  color: AppColors.background,
  child: Stack(
    children: [
      // ── Teal glow: top-right, matches RN accent atmosphere ────────────
      Positioned(
        top: -80,
        right: -100,
        child: IgnorePointer(
          child: Container(
            width: 320,
            height: 320,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppColors.glowTeal, Colors.transparent],
                stops: [0.0, 1.0],
              ),
            ),
          ),
        ),
      ),
      // ── Blue glow: bottom-left ────────────────────────────────────────
      Positioned(
        bottom: 120,
        left: -80,
        child: IgnorePointer(
          child: Container(
            width: 260,
            height: 260,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppColors.glowBlue, Colors.transparent],
              ),
            ),
          ),
        ),
      ),
      // ── Page content ─────────────────────────────────────────────────
      SafeArea(bottom: false, child: content),
    ],
  ),
);
```

You can vary which glow appears on which screen (e.g. amber glow on the Finance tab, teal glow on Home and Tasks) for a more dynamic feel.

---

## 🟠 HIGH — `HomeHubCard` is a Plain Container, Not a Glass Card

### The Problem

`home_hub_card.dart` renders a plain `Container` with `BoxDecoration(color: surfaceElevated, borderRadius: 16)`. It is the most prominent widget on the dashboard but has no glass treatment.

It also uses `borderRadius: 16` (AppRadius.lg) while all real `GlassCard` instances use 22 (AppRadius.xl). This inconsistency makes the hub card look visually smaller/cheaper than surrounding cards.

### The Fix

Replace the outer `Container` + `ClipRRect` in `HomeHubCard` with a `GlassCard`:

```dart
return GlassCard(
  padding: EdgeInsets.zero,  // rows handle their own padding
  borderRadius: AppRadius.xl,
  child: ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.xl),
    child: Column(children: [...]),
  ),
);
```

Also add a 3px left border accent to each `_HubRow` item — the Tasks row gets `AppColors.success`, the Events row gets `AppColors.accent`, matching the same left-bar pattern used on `TaskItemCard`.

---

## 🟠 HIGH — `HomeSpendSnapshotStrip` Uses Flat Containers

### The Problem

The three spend cells (Today / Week / Month) in `home_spending_cards.dart` use plain `Container` with `BoxDecoration(color: surfaceElevated, borderRadius: 12)`. They should use `AppRadius.xl = 22` and get the `GlassCard` treatment for visual consistency with everything else on screen.

The `borderRadius: 12` is also an inconsistency — it's the only place on the Home screen that uses 12 when everything else is 22.

### The Fix

Wrap each cell in a `GlassCard` or replace `Container` with:
```dart
GlassCard(
  padding: const EdgeInsets.all(12),
  borderRadius: AppRadius.xl,  // 22 — consistent
  child: Column(...),
)
```

---

## 🟠 HIGH — `AppFormSheet` Has No Blur, Gradient Colors Are Fully Opaque

### The Problem

`AppFormSheet` uses a `LinearGradient` from `surfaceFor(brightness).withValues(alpha: 0.98)` to `surfaceMutedFor(brightness).withValues(alpha: 0.98)`. At 0.98 opacity these colours are essentially solid — there's no glass effect. The sheet should blur its background:

```dart
// Wrap the entire Container with:
ClipRRect(
  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl + 4)),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceFor(brightness).withValues(alpha: 0.82),  // drop from 0.98
            AppColors.surfaceMutedFor(brightness).withValues(alpha: 0.78),
          ],
          ...
        ),
      ),
      ...
    ),
  ),
)
```

Dropping the alpha from 0.98 to ~0.82 lets the blur show through and creates the frosted sheet look.

---

## 🟠 HIGH — `AppTabBar` Has No Blur Backdrop

### The Problem

The floating bottom nav container uses `BoxDecoration(color: AppColors.surfaceElevated)` — a solid colour. It should blur the content behind it like the RN tab bar does. Since it floats above the screen content, a `BackdropFilter` with `sigmaX: 18` here has a strong visible effect.

### The Fix

Wrap the outer `Container` in `ClipRRect` + `BackdropFilter`:

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(AppRadius.xxl),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.82), // was solid
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.borderStrong),
        boxShadow: [...],
      ),
      ...
    ),
  ),
)
```

---

## 🟡 MEDIUM — Date Format Inconsistency on Task Cards

### The Problem

`task_item_card.dart` uses this format for dates beyond "Today" / "Tomorrow":
```dart
return '${date.month}/${date.day}/${date.year}';
// Outputs: "3/24/2026" — American slash format
```

The RN app and the rest of the codebase (home screen date label, calendar labels) consistently use `"Mar 24"` or `"Tue, Mar 24"` style. This one format stands out as a rough edge.

### The Fix

```dart
import 'package:intl/intl.dart';

// In _formatDate():
return DateFormat('MMM d').format(date); // → "Mar 24"
```

---

## 🟡 MEDIUM — Profile Avatar Missing Border Ring

### The Problem

The home screen profile avatar circle (`home_screen.dart`) is a plain `Container(decoration: BoxDecoration(color: surfaceElevated, shape: BoxShape.circle))`. The RN reference shows a subtle teal ring around the avatar to tie it to the app's accent.

### The Fix

```dart
decoration: BoxDecoration(
  color: AppColors.surfaceElevated,
  shape: BoxShape.circle,
  border: Border.all(
    color: AppColors.accent.withValues(alpha: 0.45),
    width: 1.5,
  ),
),
```

---

## 🟡 MEDIUM — `AppCapsule` Uses Rounded Rectangle, Not True Pill

### The Problem

`AppCapsule` uses `BorderRadius.circular(8.0)` for all sizes and variants. This produces a slightly rounded rectangle, not a fully rounded pill. The RN app's category labels and status chips use fully rounded pills (`borderRadius: 999`).

This is especially noticeable when the capsule contains only 2–3 characters (e.g. "7d" or "SM" badges) — the corners look squared compared to RN.

### The Fix

```dart
// In AppCapsule.build():
final radius = size == AppCapsuleSize.sm
    ? BorderRadius.circular(AppRadius.full)  // true pill for sm
    : BorderRadius.circular(AppRadius.sm);   // 8px for md/lg

// Replace BorderRadius.circular(8.0) with radius throughout
```

---

## 🟡 MEDIUM — `GlassCard.standard` Tone Should Use Translucent Colour, Not Opaque Surface

### The Problem

When `GlassCard` is used without `BackdropFilter`, using a solid opaque surface colour is correct. But once you add `BackdropFilter` (see Critical section above), the container fill should switch to the semi-transparent gradient defined in `GlassStyles.glassGradientFor()`:

```dart
// Current (opaque — wrong with BackdropFilter):
color: AppColors.surfaceElevated  // 0xFF1B2430 — fully opaque

// Correct (from GlassStyles.glassGradientFor() dark branch):
gradient: LinearGradient(colors: [
  Color(0x0CFFFFFF), // 5% white
  Color(0x07FFFFFF), // 3% white
])
```

Using an opaque fill defeats the purpose of `BackdropFilter` since nothing blurs through. This change **must** accompany the BackdropFilter addition.

---

## 🟡 MEDIUM — `SuperAddSheet` Kind Toggle Could Use Gradient Polish

### The Problem

The Task/Event toggle in `super_add_sheet.dart` uses `AppColors.accent` as a solid fill for the selected state. The RN reference uses a gradient pill for selected states (teal → teal-dark). The current implementation is correct but could be elevated.

### The Fix

```dart
// Selected pill gradient instead of solid accent:
gradient: selected ? const LinearGradient(
  colors: [AppColors.accentLight, AppColors.accent],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
) : null,
color: selected ? null : AppColors.surfaceMutedFor(brightness),
```

---

## 🟡 MEDIUM — Calendar Event Cards Missing Left Accent Bar

### The Problem

`calendar_events_card.dart` renders events without the left-side coloured accent bar that `task_item_card.dart` uses so effectively. Events have an `EventType` (Work, Personal, Health, etc.) that maps to the existing `AppColors.categoryWork`, `categoryPersonal`, etc. colours, but this colour is not applied as a left border accent.

This is a free visual win that makes event cards look as polished as task cards.

### The Fix

Inside the event card row, add the same 4px coloured left bar as tasks:
```dart
Container(
  width: 4,
  margin: const EdgeInsets.symmetric(vertical: 4),
  decoration: BoxDecoration(
    color: AppColors.categoryColorFor(event.type.name),
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
),
```

---

## 🟡 MEDIUM — `GlassCard` Shadow Is Too Subtle for Dark Glassmorphism

### The Problem

```dart
BoxShadow(
  color: Colors.black.withValues(alpha: 0.12), // too subtle
  blurRadius: 4,
  offset: const Offset(0, 2),
)
```

In dark glassmorphism, cards need a stronger shadow to float above the background. The current 12% black, 4px blur makes cards look flat. The RN reference likely uses ~24–28% opacity and a larger blur radius.

### The Fix

```dart
BoxShadow(
  color: Colors.black.withValues(alpha: 0.28),
  blurRadius: 16,
  offset: const Offset(0, 4),
),
// Optional: add a subtle inner top-edge highlight
BoxShadow(
  color: Colors.white.withValues(alpha: 0.04),
  blurRadius: 0,
  offset: const Offset(0, 1),
  spreadRadius: 0,
),
```

---

## 🟡 MEDIUM — `GlassCard` Border on Dark Is Too Strong

### The Problem

```dart
// standard tone:
borderColor = AppColors.borderStrong  // 0xFF5B7086 — quite visible
```

`borderStrong` at `0xFF5B7086` is a fully opaque medium-slate colour. In glassmorphism the border should be a subtle top-edge light refraction, typically `rgba(255,255,255, 0.10–0.14)`. The current border colour makes cards look like standard Material containers rather than glass.

### The Fix

```dart
// standard tone dark:
borderColor = Colors.white.withValues(alpha: 0.10);

// muted tone dark:
borderColor = Colors.white.withValues(alpha: 0.07);

// accent tone dark:
borderColor = effectiveAccent.withValues(alpha: 0.30);
```

---

## 🟢 LOW — `AppFormSheet` Corner Radius Uses Magic Number

```dart
// Current:
top: Radius.circular(AppRadius.xxl + 4),  // = 32, a magic number beyond the token system
```

It should either be `AppRadius.xxl` (28) which is the defined token for sheets, or add a dedicated `sheet` token:
```dart
static const double sheet = 32;
```

---

## 🟢 LOW — `HomeDashboardTransactionTile` Category Circle Has No Border

`home_spending_cards.dart` renders the category icon circle with `BoxDecoration(color: visual.background, shape: BoxShape.circle)` — no border. The full `ExpenseTransactionRow` in `transaction_row.dart` correctly adds `Border.all(color: visual.foreground.withValues(alpha: 0.18))`. These two should be consistent.

---

## 🟢 LOW — `HomeScreen` Greeting Could Use Accent Colour on Name

Currently the greeting is `"Good Morning, Belinze"` fully in `textPrimary`. Applying `AppColors.accentLight` colour just to the name part adds a premium personalisation feel that matches RN apps in this category:

```dart
Text.rich(TextSpan(
  text: salutation,
  style: greetingStyle,
  children: [
    if (firstName.isNotEmpty)
      TextSpan(
        text: ', $firstName',
        style: greetingStyle.copyWith(color: AppColors.accentLight),
      ),
  ],
))
```

---

## 📊 Summary Scorecard

| Area | Current | After Fixes | Priority |
|---|---|---|---|
| Glass blur effect | ❌ None (flat solid) | ✅ BackdropFilter 16px | 🔴 Critical |
| Background atmosphere glows | ❌ None (solid bg) | ✅ Radial teal+blue glows | 🔴 Critical |
| GlassCard fill colours | ❌ Opaque (kills blur) | ✅ 5% translucent white | 🔴 Critical |
| AppFormSheet blur | ❌ None | ✅ BackdropFilter 20px | 🟠 High |
| AppTabBar blur | ❌ None | ✅ BackdropFilter 18px | 🟠 High |
| HomeHubCard glass | ❌ Plain Container | ✅ GlassCard xl radius | 🟠 High |
| SpendSnapshot glass | ❌ Plain Container (r12) | ✅ GlassCard xl radius | 🟠 High |
| GlassCard border | ❌ Opaque slate | ✅ rgba(white, 10%) | 🟡 Medium |
| GlassCard shadow | ❌ Too subtle (12%) | ✅ Deeper (28%) | 🟡 Medium |
| Task date format | ❌ 3/24/2026 | ✅ Mar 24 | 🟡 Medium |
| AppCapsule pill shape | ⚠️ r8 rectangle | ✅ Full pill for sm | 🟡 Medium |
| Event card left bar | ❌ Missing | ✅ Category colour | 🟡 Medium |
| Profile avatar ring | ❌ No border | ✅ Teal ring | 🟡 Medium |
| Super Add toggle gradient | ⚠️ Solid accent | ✅ Gradient pill | 🟡 Medium |
| Greeting name accent | ❌ Plain text | ✅ accentLight name | 🟢 Low |
| Corner radius token for sheets | ⚠️ magic +4 | ✅ Define sheet token | 🟢 Low |

---

## 🏆 What Makes This a 10/10 App

All the architecture work is solid. The colour system, animation system, haptics, motion, capsule system, category visual system, Super Add Sheet, and token radius system are genuinely great and on par with the best in class. The one thing keeping this below a 10 is that **the glass is fake** — solid containers labelled "glass".

Fix in this order:
1. `page_shell.dart` — add background atmosphere glows (feeds the blur)
2. `glass_card.dart` — add `BackdropFilter` + switch to translucent fill gradient
3. `glass_card.dart` — change border to `rgba(white, 0.10)`
4. `glass_card.dart` — deepen shadow to 28% / 16px blur
5. `app_form_sheet.dart` — add `BackdropFilter` + drop alpha to 0.82
6. `app_tab_bar.dart` — add `BackdropFilter`
7. `home_hub_card.dart` — switch to `GlassCard` with radius xl
8. `home_spending_cards.dart` — switch cells to `GlassCard` with radius xl

Steps 1–4 alone will transform the visual quality to match (and likely exceed) the React Native reference because Flutter's `BackdropFilter` + `RadialGradient` is more precise than RN's blur libraries on Android.
