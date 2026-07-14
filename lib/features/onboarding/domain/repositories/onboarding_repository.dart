/// Contract for persisting the user's onboarding completion state.
abstract interface class OnboardingRepository {
  /// Returns `true` if the user has already completed (or skipped) onboarding.
  Future<bool> hasSeenOnboarding();

  /// Marks onboarding as complete.  Should be idempotent.
  Future<void> markOnboardingDone();
}
