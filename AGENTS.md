# AGENTS.md

## Purpose

This file defines how AI coding agents must execute work in this repository.
It is complementary to `CODING_RULES.md`.

## Precedence

- Read `AGENTS.md` first for workflow and execution behavior.
- Read `CODING_RULES.md` next for architecture and quality constraints.
- Follow both files on every task.
- If guidance conflicts, apply the stricter engineering constraint unless the task includes a written exemption.

## Required Workflow for Every Task

1. Confirm the user goal and success criteria.
2. Inspect relevant files before editing.
3. Propose the minimal set of file changes.
4. Implement only task-relevant edits.
5. Run validation checks (tests/lint/analyze where available).
6. Summarize what changed, what was verified, and any remaining risks.

## Architecture and Scope Discipline

- Preserve clean architecture boundaries and feature isolation defined in `CODING_RULES.md`.
- Avoid unrelated refactors.
- Do not rename/move files unless required by the task.
- Keep pull requests/task changes small and reviewable.

## UI Direction (Screenshot Reference)

Use the attached app screenshots as visual product reference:

- Dark theme baseline.
- Glassmorphism surfaces (blurred/frosted cards, rounded corners).
- Bottom tab navigation for: Home, Finance (Expenses), Calendar, AI, Profile.
- Tasks screen is accessed via pushed route (not bottom tab).
- Calendar has internal sub-tabs: Month, Tasks, Events.
- Blue accent highlights for active controls and key actions.

When implementing UI, preserve this design language unless explicitly changed by the user.

## Planning Requirement for Large Changes

Before large changes, provide:

- Intended approach.
- Files expected to change.
- Risks and validation strategy.

## Safety and Data Handling

- Never include secrets, API keys, or credentials in code or docs.
- Prefer environment-based configuration.
- Do not log sensitive personal data.

## Project Progress Log

### Phase 1 — Navigation Redesign & Super Add Expansion (COMPLETE)
- 5-tab bottom navigation; Tasks moved to pushed route.
- Super Add sheet expanded to 5 types (Task, Event, Birthday, Anniversary, Countdown).
- Calendar Month view now renders events; FAB is "Add".

### Phase 2 — Missing Feature Modules (COMPLETE)
- Added Bills, Loans, Goals, Learning modules with full entity → repository → screen → widget stacks.
- New tables in Drift schema: `bills`, `loans`, `goals`, `learning_sessions`.
- Tool shortcuts grid updated with new features.

### Phase 3 — Offline AI Engine Port (COMPLETE)
- Created full offline rule-based AI engine: DataContextBuilder, FinancialHealthCalculator, AnomalyDetector, CashFlowProjector, IntentClassifier, OfflineAiEngine.
- 18 intents supported offline; integrated into AssistantRepositoryImpl as primary fallback.
- 5 new test suites covering intent classification, health scoring, anomaly detection, cash flow projection, and end-to-end replies.

### Phase 4 — Merchant Detail, Fee Analytics, Encrypted Export, Background Workers (COMPLETE)
- **Merchant Detail**: tap any transaction to see merchant history, total spent, average, first/last seen, monthly average.
- **Fee Analytics**: detects fee/charge/cost keywords in transactions and shows total fees, monthly trends, top fee categories.
- **Encrypted Export**: AES-256 password-protected export toggle in ExportScreen; securely deletes plaintext after encryption.
- **Background Workers**: extended existing WorkManager dispatcher with BillReminderService (upcoming/overdue bills) and LearningReminderService (streak encouragement).

### Phase 5 — Shorebird Build Scripts, Final Tests, Parity Verification (COMPLETE)
- **Shorebird scripts**: `scripts/build_shorebird.sh` and `scripts/build_shorebird.ps1` for cross-platform release and patch builds.
- **New repository tests**: `test/bills/`, `test/loans/`, `test/goals/`, `test/learning/` with full CRUD and business-logic tests.
- **Encrypted export tests**: `test/export/encrypted_export_service_test.dart` covering round-trip, wrong-password rejection, uniqueness, empty, and large payloads.
- **Parity verdict**: Dart app is definitively superior. See `PARITY.md` for full comparison.

## Done Criteria

A task is done only when:

- Changes satisfy the requested outcome.
- Relevant checks pass or failures are clearly reported.
- Architecture/style rules were respected.
- Final response includes concise change and verification summary.
