import 'package:beltech/core/update/domain/version_utils.dart';

enum UpdateState { idle, checking, available, downloading, ready, installed }

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.forceUpdate,
    required this.title,
    required this.message,
    required this.notes,
    this.apkUrl,
    this.websiteUrl,
  });

  final String latestVersion;
  final String minSupportedVersion;
  final bool forceUpdate;
  final String title;
  final String message;
  final List<String> notes;
  final String? apkUrl;
  final String? websiteUrl;

  bool isNewerThan(String currentVersion) =>
      compareVersions(latestVersion, currentVersion) > 0;

  bool isMandatoryFor(String currentVersion) =>
      forceUpdate || compareVersions(minSupportedVersion, currentVersion) > 0;

  bool get hasApkUrl => (apkUrl ?? '').trim().isNotEmpty;
  bool get hasWebsiteUrl => (websiteUrl ?? '').trim().isNotEmpty;

  factory AppUpdateInfo.fromMap(Map<String, dynamic> data) {
    final latest = (data['latest_version'] ?? data['latestVersion'] ?? '')
        .toString()
        .trim();
    final minimum =
        (data['min_supported_version'] ?? data['minSupportedVersion'] ?? latest)
            .toString()
            .trim();
    final rawNotes = data['notes'];
    final notes = switch (rawNotes) {
      List<dynamic>() => rawNotes
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      String() => rawNotes
          .split('||')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      _ => const <String>[],
    };
    return AppUpdateInfo(
      latestVersion: latest,
      minSupportedVersion: minimum,
      forceUpdate: data['force_update'] == true || data['forceUpdate'] == true,
      title: (data['title'] ?? 'Update Available').toString(),
      message: (data['message'] ??
              'A newer version of the app is available. Please update now.')
          .toString(),
      notes: notes,
      apkUrl: (data['apk_url'] ?? data['apkUrl'])?.toString(),
      websiteUrl: (data['website_url'] ?? data['websiteUrl'])?.toString(),
    );
  }
}
