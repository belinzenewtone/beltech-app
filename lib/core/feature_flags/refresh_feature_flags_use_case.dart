import 'package:beltech/core/feature_flags/feature_flag_store.dart';

class RefreshFeatureFlagsUseCase {
  RefreshFeatureFlagsUseCase(this._store);

  final FeatureFlagStore _store;

  Future<void> call() async {
    // Local-only: feature flags are managed in-app with no remote refresh.
    await _store.snapshot();
  }
}
