class AppUpdateConfig {
  AppUpdateConfig._();

  static const String latestVersion =
      String.fromEnvironment('APP_UPDATE_LATEST_VERSION');
  static const String minSupportedVersion =
      String.fromEnvironment('APP_UPDATE_MIN_VERSION');
  static const String forceUpdateRaw =
      String.fromEnvironment('APP_UPDATE_FORCE');
  static const String title = String.fromEnvironment('APP_UPDATE_TITLE');
  static const String message = String.fromEnvironment('APP_UPDATE_MESSAGE');
  static const String notesRaw = String.fromEnvironment('APP_UPDATE_NOTES');
  static const String apkUrl = String.fromEnvironment('APP_UPDATE_APK_URL');
  static const String websiteUrl =
      String.fromEnvironment('APP_UPDATE_WEBSITE_URL');
  static const String remoteManifestUrl =
      String.fromEnvironment('APP_UPDATE_REMOTE_MANIFEST_URL');

  static bool get isConfigured => latestVersion.isNotEmpty;
  static bool get forceUpdate => forceUpdateRaw.toLowerCase() == 'true';

  static List<String> get notes => notesRaw
      .split('||')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}
