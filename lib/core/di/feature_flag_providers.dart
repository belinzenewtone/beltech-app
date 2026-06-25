import 'package:beltech/core/feature_flags/feature_flag.dart';
import 'package:beltech/core/feature_flags/feature_flag_store.dart';
import 'package:beltech/core/feature_flags/refresh_feature_flags_use_case.dart';
import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final featureFlagStoreProvider = Provider<FeatureFlagStore>(
  (_) => FeatureFlagStore(),
);

final refreshFeatureFlagsUseCaseProvider = Provider<RefreshFeatureFlagsUseCase>(
  (ref) => RefreshFeatureFlagsUseCase(ref.watch(featureFlagStoreProvider)),
);

final featureFlagSnapshotProvider = FutureProvider<Map<FeatureFlag, bool>>(
  (ref) => ref.watch(featureFlagStoreProvider).snapshot(),
);

final featureFlagProvider = FutureProvider.family<bool, FeatureFlag>((
  ref,
  flag,
) async {
  final snapshot = await ref.watch(featureFlagSnapshotProvider.future);
  return snapshot[flag] ?? flag.defaultEnabled;
});

/// Watches the haptics feature flag and keeps [AppHaptics.setEnabled] in sync.
/// Consume this provider at the root widget to activate the gate app-wide.
final hapticsFeatureFlagProvider = Provider<void>((ref) {
  ref
      .watch(featureFlagProvider(FeatureFlag.haptics))
      .whenData((enabled) => AppHaptics.setEnabled(enabled));
});
