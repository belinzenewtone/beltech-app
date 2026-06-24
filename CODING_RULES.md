# CODING_RULES.md

## Global Development Rules for Codex

This document defines non-negotiable engineering rules for the Personal Management App.
All AI agents and contributors must follow these rules when generating or editing code in this repository.

## Precedence and Behavior with AGENTS.md

- `AGENTS.md` defines agent workflow, execution process, and collaboration behavior.
- `CODING_RULES.md` defines architecture, design, quality, and engineering constraints.
- When both files apply, follow both.
- If a conflict exists, the stricter engineering constraint wins unless the task explicitly includes a written exemption.

## CR-01: Architecture Rules (Clean Architecture)

- Required layer layout:
  - `lib/core/`
  - `lib/features/`
  - `lib/data/`
  - `lib/domain/`
  - `lib/presentation/`
- Dependency direction must remain: `presentation -> domain -> data`.
- UI code must not access database or persistence APIs directly.
- Business logic must live in `domain`.
- Data access implementations must live in `data`.

## CR-02: Feature-Based Structure

- Each feature must be isolated under `lib/features/<feature_name>/`.
- Every feature must contain:
  - `data/`
  - `domain/`
  - `presentation/`
- Cross-feature imports are allowed only through domain-level contracts or shared `core` abstractions.

## CR-03: File Size Rules

- No `.dart` file may exceed 300 lines.
- If a file exceeds 300 lines, split it by responsibility before merging.
- Allowed split strategies:
  - Extract widgets.
  - Extract services/repositories.
  - Extract mappers/use cases.

## CR-04: Widget Composition Rules

- Prefer small, reusable widgets over large screen files.
- A screen file must primarily orchestrate composition, not contain all UI detail logic.
- Repeated UI blocks must be extracted into reusable widgets.

## CR-05: State Management Rules

- Riverpod is required for state management.
- Global mutable variables are forbidden for app state.
- State must be managed through providers, `StateNotifier`, `Notifier`, or `AsyncNotifier`.
- Async UI state must expose explicit loading, success, and error states.

## CR-06: UI Design Rules (Glassmorphism)

- The default visual style is dark glassmorphism.
- Card-like surfaces must use a reusable `GlassCard` component.
- Glass surfaces must use `BackdropFilter` (or a shared abstraction that wraps it).
- Glass surfaces must include rounded corners and blur.
- Transitions and major state changes must use smooth animations.

## CR-07: Styling Rules

- Hardcoded color/style constants in feature widgets are forbidden.
- Shared theme and style tokens must be centralized under `core/theme/`.
- Expected shared style files include:
  - `app_colors.dart`
  - `app_theme.dart`
  - `glass_styles.dart`
- Widgets must import shared theme tokens instead of defining local color systems.

## CR-08: Database Rules

- Drift is the required database layer.
- Queries used by UI/business workflows must be reactive where applicable.
- Schema versioning and migrations are mandatory for schema changes.
- Table definitions must remain explicit and feature-aligned.

## CR-09: Security Rules

- Plain-text passwords must never be stored.
- Passwords must be hashed before persistence.
- Credentials and secrets must be stored using Flutter Secure Storage (or a stricter secure store).
- Sensitive logs must be avoided or redacted.

## CR-10: Error Handling Rules

- All async flows must handle failures explicitly (`try/catch`, typed errors, or result wrappers).
- Silent failure paths are forbidden.
- Error handling must return actionable states/messages to caller layers.

## CR-11: Testing Rules

- Tests are required for:
  - repositories
  - use cases
  - domain/business logic
- Standard test tooling:
  - `flutter_test`
  - `mocktail`
- New or changed business logic must include corresponding tests before merge.

## CR-12: Git and Commit Rules

- Commit messages must follow Conventional Commits.
- Required format: `<type>: <short description>`.
- Allowed types include `feat`, `fix`, `refactor`, `test`, `docs`, `chore`.

## CR-13: Performance Rules

- App startup target: under 1.5 seconds on release-profile baseline devices.
- Data handling must support 10,000+ transactions without functional degradation.
- Avoid unnecessary rebuilds in widget trees.
- Use `const` constructors/widgets where possible.

## CR-14: AI Agent Behavior Rules

- Before coding, read `AGENTS.md` and `CODING_RULES.md`.
- Modify only files relevant to the task.
- Avoid unrelated refactors.
- Preserve modular architecture boundaries.
- For large changes, provide a plan and expected file impact before implementation.

## CR-15: Dependency Rules

- Avoid heavy dependencies when platform or existing project utilities are sufficient.
- Before adding a package, verify:
  - Flutter SDK does not already cover the need.
  - Package is actively maintained.
  - Package is widely used and reliable.

## CR-16: Documentation Rules

- Every new feature module must include a local `README.md`.
- The feature README must document:
  - feature purpose
  - main classes/components
  - dependencies and integration points

## CR-17: Toolchain Baseline Rules

- New and modified code must remain compatible with Flutter `3.41.x` and Dart `3.11.x`.
- Do not introduce Dart language features that require a lower-bound SDK higher than `3.11.4`.
- CI/tooling version pins must stay aligned with this baseline unless a deliberate repo-wide upgrade is approved.

## Compliance Checklist (Required Before Finalizing Changes)

- Architecture boundaries are respected (`presentation -> domain -> data`).
- No hardcoded styles were added in feature widgets.
- Async operations include explicit error handling.
- Tests were added or updated for business logic changes.
- No `.dart` file exceeds 300 lines; modularity is preserved.
