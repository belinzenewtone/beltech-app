# Onboarding Feature

## Purpose
Presents the first-run onboarding flow and persists whether the user has completed onboarding.

## Main Components
- `presentation/onboarding_screen.dart`:
  - Multi-step onboarding UI.
  - Calls completion callback after final step.
- `domain/repositories/onboarding_repository.dart`:
  - Contract for onboarding completion state.
- `data/repositories/onboarding_repository_impl.dart`:
  - SharedPreferences-backed implementation.

## Dependencies and Integration
- Used by auth entry in `AuthGate` to decide whether to show onboarding or continue to auth/app shell.
- Completion flag is device-local and independent of cloud/local data mode.
