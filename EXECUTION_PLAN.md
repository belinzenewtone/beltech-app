# EXECUTION_PLAN.md

## Goal

Build the Flutter Personal Management App end-to-end using clean architecture, Riverpod, Drift, and dark glassmorphism UI consistent with the provided screenshots.

## Product Baseline from Screenshot References

- Global visual style:
  - Dark background.
  - Frosted glass cards with blur and rounded corners.
  - Blue accent for primary actions and selected navigation items.
- Navigation:
  - Persistent bottom tabs: Home, Calendar, Expenses, Tasks, AI, Profile.
- Key screens:
  - Home: greeting, summary cards, productivity, events, weekly spending chart, recent transactions.
  - Calendar: monthly calendar view, selected day summary, add-event action.
  - Expenses: period filters, category spending, transaction list, import/manual add actions.
  - AI: assistant chat, suggested prompts, message composer.
  - Profile: avatar/user details, verification status, personal info, security options.

## Phase Plan

### Phase 1: Project Foundation

- Initialize Flutter project structure and dependencies.
- Create shared app theme under `lib/core/theme/`:
  - `app_colors.dart`
  - `glass_styles.dart`
  - `app_theme.dart`
- Create reusable `GlassCard` component using `BackdropFilter`.
- Configure app routing shell with bottom navigation tabs.

Acceptance:
- App boots to tabbed shell.
- Theme is centralized and used by at least one screen.
- GlassCard renders blur/rounded frosted surfaces.

### Phase 2: Domain and Data Skeleton

- Define feature folders (`data/domain/presentation`) for each tab feature.
- Add domain entities and repository contracts.
- Set up Drift database skeleton with versioning and migration strategy.
- Add Riverpod provider skeletons per feature.

Acceptance:
- All features compile with clear contracts.
- Database layer compiles with schema version and migration entry point.
- No direct data access from presentation layer.

### Phase 3: Home and Expenses MVP

- Implement Home dashboard widgets matching screenshot composition.
- Implement Expenses overview:
  - Summary cards (today/week).
  - Filter chips (all/today/week/month).
  - Category breakdown.
  - Transaction list.
- Wire to repository/provider flows with error states.

Acceptance:
- Home and Expenses tabs are functional with reactive state updates.
- Async error/loading/success states are visible.
- UI matches dark glass style baseline.

### Phase 4: Calendar and Tasks MVP

- Implement Calendar monthly view with selected-date detail card.
- Implement Tasks list with pending/completed tracking.
- Add create/update flows for events and tasks.

Acceptance:
- Events and tasks persist and refresh reactively.
- Date/task updates are reflected without app restart.

### Phase 5: Assistant and Profile MVP

- Implement assistant chat UI and prompt chips.
- Implement profile view with account metadata and editable personal info.
- Implement security actions (change password flow UI and secure storage integration points).

Acceptance:
- Assistant UI interactions function locally (mocked if backend unavailable).
- Profile updates follow provider flow and error handling rules.

### Phase 6: Hardening

- Add repository/use-case/domain tests using `flutter_test` and `mocktail`.
- Profile startup performance and reduce unnecessary rebuilds.
- Enforce file-size and modularity limits.
- Final lint/analyze/test pass.

Acceptance:
- Test coverage exists for core business logic paths.
- No `.dart` file exceeds 300 lines.
- Release profile startup target and large data behavior are measured and documented.

## Implementation Rules During Execution

- Always follow `AGENTS.md` and `CODING_RULES.md`.
- Before each phase, list expected files to be changed.
- Keep changes feature-scoped; avoid unrelated refactors.
- Add a local `README.md` inside each new feature module.

## Validation Checklist Per PR/Task

- Architecture direction preserved (`presentation -> domain -> data`).
- Riverpod patterns used for state handling.
- Drift usage remains reactive and migration-safe.
- No hardcoded style constants in feature widgets.
- Async flows include explicit error handling.
- Tests added/updated for changed domain or repository behavior.
