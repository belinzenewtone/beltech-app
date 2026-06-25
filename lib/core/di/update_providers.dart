import 'package:beltech/core/config/app_update_config.dart';
import 'package:beltech/core/di/database_providers.dart';
import 'package:beltech/core/update/data/app_update_service.dart';
import 'package:beltech/core/update/data/update_repository.dart';
import 'package:beltech/core/update/data/update_state_machine.dart';
import 'package:beltech/core/update/domain/app_update_info.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  final manifestUrl = AppUpdateConfig.remoteManifestUrl.isNotEmpty
      ? AppUpdateConfig.remoteManifestUrl
      : null;
  return AppUpdateService(remoteManifestUrl: manifestUrl);
});

final updateRepositoryProvider = Provider<UpdateRepository>(
  (ref) => UpdateRepository(ref.watch(appDriftStoreProvider)),
);

final updateStateMachineProvider = Provider<UpdateStateMachine>(
  (ref) => UpdateStateMachine(),
);

final updateCheckProvider = FutureProvider<AppUpdateInfo?>((ref) async {
  final service = ref.watch(appUpdateServiceProvider);
  final stateMachine = ref.read(updateStateMachineProvider);
  final repository = ref.read(updateRepositoryProvider);

  stateMachine.checkForUpdate();

  try {
    final update = await service.fetchAvailableUpdate();
    if (update == null) {
      stateMachine.reset();
      return null;
    }

    stateMachine.updateAvailable(update);

    final row = await repository.fetchActiveUpdateRow();
    if (row == null || row['current_version'] != update.latestVersion) {
      await repository.saveUpdate(
        platform: 'android',
        currentVersion: update.latestVersion,
        minimumSupportedVersion: update.minSupportedVersion.isNotEmpty
            ? update.minSupportedVersion
            : null,
        storeUrl: update.apkUrl ?? update.websiteUrl,
        changelog: update.notes.join('||'),
        isForce: update.forceUpdate,
      );
    }

    return update;
  } catch (_) {
    stateMachine.reset();
    return null;
  }
});
