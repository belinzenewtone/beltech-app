enum FeatureFlag {
  parserV2(key: 'parser_v2', defaultEnabled: true),
  reviewQueue(key: 'review_queue', defaultEnabled: true),
  smartNotifications(key: 'smart_notifications', defaultEnabled: true),
  stretchMotion(key: 'stretch_motion', defaultEnabled: true),
  backgroundSync(key: 'background_sync', defaultEnabled: true),
  weeklyReviewRitual(key: 'weekly_review_ritual', defaultEnabled: true),
  biometricRelock(key: 'biometric_relock', defaultEnabled: true),
  /// Controls haptic feedback globally. Disable to silence all vibrations.
  haptics(key: 'haptics', defaultEnabled: true);

  const FeatureFlag({required this.key, required this.defaultEnabled});

  final String key;
  final bool defaultEnabled;

  static FeatureFlag? fromKey(String key) {
    for (final flag in values) {
      if (flag.key == key) {
        return flag;
      }
    }
    return null;
  }
}
