import 'package:workmanager/workmanager.dart';

/// Schedules a durable one-shot WorkManager task to drain the SMS ingest queue.
///
/// The actual processing logic lives in [BackgroundWorkerRuntime.runSmsIngest]
/// (wired in `background_worker_dispatcher.dart`).  This class is responsible
/// only for scheduling — callers never need to import WorkManager directly.
class SmsIngestionWorker {
  const SmsIngestionWorker._();

  static const String taskName = 'beltech.sms.ingest';
  static const String _uniqueName = 'com.beltech.sms.ingest.oneshot';

  /// Enqueue a one-shot WorkManager task.  [ExistingWorkPolicy.keep] prevents
  /// redundant schedules when the queue already has a pending run.
  static Future<void> scheduleOneShot() async {
    await Workmanager().registerOneOffTask(
      _uniqueName,
      taskName,
      existingWorkPolicy: ExistingWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.notRequired),
    );
  }
}
