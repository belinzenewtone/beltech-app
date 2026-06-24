import 'package:beltech/core/platform/runtime_env.dart';
import 'package:beltech/core/sync/background_worker_dispatcher.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

class OsBackgroundSyncScheduler {
  OsBackgroundSyncScheduler({Workmanager? workmanager})
      : _workmanager = workmanager ?? Workmanager();

  final Workmanager _workmanager;
  bool _initialized = false;

  Future<void> initializeAndSchedule() async {
    if (kIsWeb || hasRuntimeEnv('FLUTTER_TEST')) {
      return;
    }
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    if (!_initialized) {
      await _workmanager.initialize(
        backgroundSyncDispatcher,
      );
      _initialized = true;
    }
    await _registerPeriodic();
  }

  Future<void> triggerOneOff() async {
    if (!_initialized) {
      return;
    }
    await _workmanager.registerOneOffTask(
      kBackgroundSyncOneOffUniqueName,
      kBackgroundSyncTaskName,
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  Future<void> _registerPeriodic() async {
    final frequency = defaultTargetPlatform == TargetPlatform.android
        ? const Duration(minutes: 15)
        : const Duration(hours: 1);
    await _workmanager.registerPeriodicTask(
      kBackgroundSyncPeriodicUniqueName,
      kBackgroundSyncTaskName,
      frequency: frequency,
      initialDelay: const Duration(minutes: 5),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: true,
      ),
    );
  }
}
