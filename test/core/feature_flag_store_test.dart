import 'package:beltech/core/feature_flags/feature_flag.dart';
import 'package:beltech/core/feature_flags/feature_flag_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  test('returns defaults and applies remote values', () async {
    final store = FeatureFlagStore();

    final defaultParser = await store.isEnabled(FeatureFlag.parserV2);
    expect(defaultParser, isTrue);

    await store.applyRemoteValues({
      FeatureFlag.parserV2.key: false,
      FeatureFlag.smartNotifications.key: false,
    });

    expect(await store.isEnabled(FeatureFlag.parserV2), isFalse);
    expect(await store.isEnabled(FeatureFlag.smartNotifications), isFalse);
  });

  test(
    'supports rollout percentages and deterministic user targeting',
    () async {
      final store = FeatureFlagStore();

      await store.setValue(flag: FeatureFlag.backgroundSync, enabled: true);
      await store.setRolloutPercentage(
        flag: FeatureFlag.backgroundSync,
        percentage: 0,
      );
      expect(
        await store.isEnabledFor(
          FeatureFlag.backgroundSync,
          userId: 'user-alpha',
        ),
        isFalse,
      );

      await store.setRolloutPercentage(
        flag: FeatureFlag.backgroundSync,
        percentage: 100,
      );
      expect(
        await store.isEnabledFor(
          FeatureFlag.backgroundSync,
          userId: 'user-alpha',
        ),
        isTrue,
      );

      await store.setRolloutPercentage(
        flag: FeatureFlag.backgroundSync,
        percentage: 37,
      );
      final first = await store.isEnabledFor(
        FeatureFlag.backgroundSync,
        userId: 'user-alpha',
      );
      final second = await store.isEnabledFor(
        FeatureFlag.backgroundSync,
        userId: 'user-alpha',
      );
      expect(second, first);
    },
  );
}
