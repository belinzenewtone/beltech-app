import 'dart:convert';

import 'package:beltech/core/config/app_update_config.dart';
import 'package:beltech/core/update/data/update_installer.dart';
import 'package:beltech/core/update/domain/app_update_info.dart';
import 'package:beltech/core/update/domain/update_install_progress.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateService {
  AppUpdateService({this.remoteManifestUrl});

  /// Optional remote JSON manifest URL (e.g. GitHub raw file).
  final String? remoteManifestUrl;

  Future<AppUpdateInfo?> fetchAvailableUpdate() async {
    final currentVersion = await _currentVersion();
    final update = await _fetchRemoteManifest() ?? _fetchDefinedUpdate();
    if (update == null) {
      return null;
    }
    if (update.isMandatoryFor(currentVersion) ||
        update.isNewerThan(currentVersion)) {
      return update;
    }
    return null;
  }

  Stream<UpdateInstallProgress> installAndroidUpdate(AppUpdateInfo update) {
    final url = (update.apkUrl ?? '').trim();
    if (url.isEmpty) {
      return Stream.value(
        const UpdateInstallProgress(
          state: UpdateInstallState.unsupported,
          message: 'No APK update URL configured.',
        ),
      );
    }
    return installApkUpdate(url);
  }

  Future<bool> openUpdateWebsite(AppUpdateInfo update) async {
    final rawUrl = (update.websiteUrl ?? update.apkUrl ?? '').trim();
    if (rawUrl.isEmpty) {
      return false;
    }
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      return false;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<String> _currentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return '0.0.0';
    }
  }

  AppUpdateInfo? _fetchDefinedUpdate() {
    if (!AppUpdateConfig.isConfigured) {
      return null;
    }
    return AppUpdateInfo.fromMap({
      'latest_version': AppUpdateConfig.latestVersion,
      'min_supported_version': AppUpdateConfig.minSupportedVersion,
      'force_update': AppUpdateConfig.forceUpdate,
      'title': AppUpdateConfig.title,
      'message': AppUpdateConfig.message,
      'notes': AppUpdateConfig.notes,
      'apk_url': AppUpdateConfig.apkUrl,
      'website_url': AppUpdateConfig.websiteUrl,
    });
  }

  Future<AppUpdateInfo?> _fetchRemoteManifest() async {
    final url = remoteManifestUrl?.trim();
    if (url == null || url.isEmpty) {
      return null;
    }
    try {
      final uri = Uri.parse(url);
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        return null;
      }
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        return null;
      }
      return AppUpdateInfo.fromMap(body);
    } catch (_) {
      return null;
    }
  }
}
