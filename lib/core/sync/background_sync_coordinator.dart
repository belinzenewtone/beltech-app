import 'package:beltech/core/feature_flags/feature_flag.dart';
import 'package:beltech/core/feature_flags/feature_flag_store.dart';
import 'package:beltech/features/auth/domain/repositories/account_repository.dart';
import 'package:beltech/core/sync/mpesa_historical_import_scanner.dart';
import 'package:beltech/core/notifications/notification_insights_service.dart';
import 'package:beltech/core/platform/runtime_env.dart';
import 'package:beltech/core/sync/os_background_sync_scheduler.dart';
import 'package:beltech/core/sync/sms_auto_import_service.dart';
import 'package:beltech/core/sync/sync_circuit_breaker.dart';
import 'package:beltech/features/recurring/data/services/recurring_materializer_service.dart';
import 'package:flutter/foundation.dart';

class BackgroundSyncCoordinator {
  BackgroundSyncCoordinator(
    this._smsAutoImportService,
    this._historicalImportScanner,
    this._recurringMaterializerService,
    this._notificationInsightsService,
    this._osBackgroundSyncScheduler,
    this._featureFlagStore,
    this._accountRepository,
  );

  final SmsAutoImportService _smsAutoImportService;
  final MpesaHistoricalImportScanner _historicalImportScanner;
  final RecurringMaterializerService _recurringMaterializerService;
  final NotificationInsightsService _notificationInsightsService;
  final OsBackgroundSyncScheduler _osBackgroundSyncScheduler;
  final FeatureFlagStore _featureFlagStore;
  final AccountRepository _accountRepository;
  final _circuitBreaker = SyncCircuitBreaker();

  BackgroundSyncStrategy get _strategy => BackgroundSyncStrategy.forPlatform();

  Future<void> start() async {
    if (hasRuntimeEnv('FLUTTER_TEST')) {
      return;
    }
    if (!await _isEnabled(FeatureFlag.backgroundSync)) {
      return;
    }
    if (!_circuitBreaker.canAttempt) {
      return;
    }
    try {
      await _historicalImportScanner.runOnce();
      await _osBackgroundSyncScheduler.initializeAndSchedule();
      await _smsAutoImportService.start(interval: _strategy.smsInterval);
      await _recurringMaterializerService.start(
        interval: _strategy.recurringInterval,
      );
      await _notificationInsightsService.runSweep();
      _circuitBreaker.recordSuccess();
    } catch (_) {
      _circuitBreaker.recordFailure();
      rethrow;
    }
  }

  Future<void> stop() async {
    await _smsAutoImportService.stop();
    await _recurringMaterializerService.stop();
  }

  Future<void> syncNow() async {
    if (!await _isEnabled(FeatureFlag.backgroundSync)) {
      return;
    }
    if (!_circuitBreaker.canAttempt) {
      return;
    }
    try {
      await _smsAutoImportService.syncNow();
      _circuitBreaker.recordSuccess();
    } catch (_) {
      _circuitBreaker.recordFailure();
      rethrow;
    }
  }

  Future<void> materializeNow() async {
    if (!await _isEnabled(FeatureFlag.backgroundSync)) {
      return;
    }
    await _recurringMaterializerService.syncNow();
  }

  Future<void> runNotificationSweep() async {
    if (!await _isEnabled(FeatureFlag.smartNotifications)) {
      return;
    }
    await _notificationInsightsService.runSweep();
  }

  Future<bool> _isEnabled(FeatureFlag flag) => _featureFlagStore.isEnabledFor(
    flag,
    userId: _accountRepository.currentSession().userId,
  );
}

class BackgroundSyncStrategy {
  const BackgroundSyncStrategy({
    required this.smsInterval,
    required this.recurringInterval,
    required this.modeLabel,
  });

  final Duration smsInterval;
  final Duration recurringInterval;
  final String modeLabel;

  static BackgroundSyncStrategy forPlatform() {
    return forTargetPlatform(defaultTargetPlatform);
  }

  static BackgroundSyncStrategy forTargetPlatform(TargetPlatform platform) {
    if (platform == TargetPlatform.android) {
      return const BackgroundSyncStrategy(
        smsInterval: Duration(minutes: 2),
        recurringInterval: Duration(minutes: 2),
        modeLabel: 'android-realtime',
      );
    }
    return const BackgroundSyncStrategy(
      smsInterval: Duration(minutes: 10),
      recurringInterval: Duration(minutes: 5),
      modeLabel: 'foreground-fallback',
    );
  }
}
