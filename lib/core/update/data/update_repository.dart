import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/core/update/domain/app_update_info.dart';

class UpdateRepository {
  UpdateRepository(this._store);

  final AppDriftStore _store;

  Future<void> ensureInitialized() => _store.ensureInitialized();

  Future<Map<String, Object?>?> fetchActiveUpdateRow() async {
    await ensureInitialized();
    final rows = await _store.executor.runSelect(
      'SELECT id, platform, current_version, minimum_supported_version, '
      'store_url, changelog, is_force, active, update_channel, created_at '
      'FROM app_updates WHERE active = 1 ORDER BY created_at DESC LIMIT 1',
      const [],
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> saveUpdate({
    required String platform,
    required String currentVersion,
    String? minimumSupportedVersion,
    String? storeUrl,
    String? changelog,
    bool isForce = false,
    bool active = true,
    String updateChannel = 'stable',
    DateTime? createdAt,
  }) async {
    await ensureInitialized();
    final now = (createdAt ?? DateTime.now()).millisecondsSinceEpoch;
    await _store.executor.runInsert(
      'INSERT INTO app_updates(platform, current_version, '
      'minimum_supported_version, store_url, changelog, is_force, '
      'active, update_channel, created_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        platform,
        currentVersion,
        minimumSupportedVersion,
        storeUrl,
        changelog,
        isForce ? 1 : 0,
        active ? 1 : 0,
        updateChannel,
        now,
      ],
    );
  }

  Future<void> deactivateUpdate(int id) async {
    await ensureInitialized();
    await _store.executor.runUpdate(
      'UPDATE app_updates SET active = 0 WHERE id = ?',
      [id],
    );
  }

  Future<void> deleteOldUpdates(int olderThanMs) async {
    await ensureInitialized();
    await _store.executor.runDelete(
      'DELETE FROM app_updates WHERE created_at < ?',
      [olderThanMs],
    );
  }

  AppUpdateInfo rowToAppUpdateInfo(Map<String, Object?> row) {
    final version = _asString(row['current_version']);
    final minVersion = _asString(row['minimum_supported_version']);
    final changelogText = _asString(row['changelog']);
    final storeUrl = _asString(row['store_url']);
    final notes = changelogText
        .split('||')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return AppUpdateInfo(
      latestVersion: version,
      minSupportedVersion: minVersion.isNotEmpty ? minVersion : version,
      forceUpdate: _asInt(row['is_force']) == 1,
      title: 'Update Available',
      message: changelogText.isNotEmpty
          ? changelogText
          : 'A new version is available.',
      notes: notes,
      apkUrl: storeUrl.isNotEmpty ? storeUrl : null,
      websiteUrl: storeUrl.isNotEmpty ? storeUrl : null,
    );
  }

  int _asInt(Object? value) =>
      value == null ? 0 : int.tryParse(value.toString()) ?? 0;

  String _asString(Object? value) => (value ?? '').toString().trim();
}
