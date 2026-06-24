import 'package:beltech/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences-backed implementation of [OnboardingRepository].
///
/// The onboarding flag is stored under a versioned key so that future feature
/// walkthroughs can be re-triggered on upgrade by simply bumping the key.
class OnboardingRepositoryImpl implements OnboardingRepository {
  static const String _key = 'onboarding_done_v1';

  @override
  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  @override
  Future<void> markOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
