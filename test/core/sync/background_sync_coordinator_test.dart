import 'package:beltech/core/feature_flags/feature_flag.dart';
import 'package:beltech/core/feature_flags/feature_flag_store.dart';
import 'package:beltech/core/notifications/notification_insights_service.dart';
import 'package:beltech/core/sync/background_sync_coordinator.dart';
import 'package:beltech/core/sync/mpesa_historical_import_scanner.dart';
import 'package:beltech/core/sync/os_background_sync_scheduler.dart';
import 'package:beltech/core/sync/sms_auto_import_service.dart';
import 'package:beltech/features/auth/domain/entities/account_session.dart';
import 'package:beltech/features/auth/domain/repositories/account_repository.dart';
import 'package:beltech/features/recurring/data/services/recurring_materializer_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSmsAutoImportService extends Mock implements SmsAutoImportService {}

class _MockMpesaHistoricalImportScanner extends Mock
    implements MpesaHistoricalImportScanner {}

class _MockRecurringMaterializerService extends Mock
    implements RecurringMaterializerService {}

class _MockNotificationInsightsService extends Mock
    implements NotificationInsightsService {}

class _MockOsBackgroundSyncScheduler extends Mock
    implements OsBackgroundSyncScheduler {}

class _MockFeatureFlagStore extends Mock implements FeatureFlagStore {}

class _MockAccountRepository extends Mock implements AccountRepository {}

void main() {
  late _MockSmsAutoImportService smsService;
  late _MockMpesaHistoricalImportScanner historicalScanner;
  late _MockRecurringMaterializerService recurringService;
  late _MockNotificationInsightsService insightsService;
  late _MockOsBackgroundSyncScheduler scheduler;
  late _MockFeatureFlagStore flagStore;
  late _MockAccountRepository accountRepository;
  late BackgroundSyncCoordinator coordinator;

  setUp(() {
    smsService = _MockSmsAutoImportService();
    historicalScanner = _MockMpesaHistoricalImportScanner();
    recurringService = _MockRecurringMaterializerService();
    insightsService = _MockNotificationInsightsService();
    scheduler = _MockOsBackgroundSyncScheduler();
    flagStore = _MockFeatureFlagStore();
    accountRepository = _MockAccountRepository();

    when(() => accountRepository.currentSession()).thenReturn(
      const AccountSession(isAuthenticated: true, userId: 'user-123'),
    );

    coordinator = BackgroundSyncCoordinator(
      smsService,
      historicalScanner,
      recurringService,
      insightsService,
      scheduler,
      flagStore,
      accountRepository,
    );
  });

  test(
    'syncNow skips when background sync rollout disables this user',
    () async {
      when(
        () => flagStore.isEnabledFor(
          FeatureFlag.backgroundSync,
          userId: 'user-123',
        ),
      ).thenAnswer((_) async => false);

      await coordinator.syncNow();

      verify(
        () => flagStore.isEnabledFor(
          FeatureFlag.backgroundSync,
          userId: 'user-123',
        ),
      ).called(1);
      verifyNever(() => smsService.syncNow());
    },
  );

  test('syncNow runs when background sync rollout enables this user', () async {
    when(
      () => flagStore.isEnabledFor(
        FeatureFlag.backgroundSync,
        userId: 'user-123',
      ),
    ).thenAnswer((_) async => true);
    when(() => smsService.syncNow()).thenAnswer((_) async => 1);

    await coordinator.syncNow();

    verify(() => smsService.syncNow()).called(1);
  });

  test(
    'runNotificationSweep skips when smart notifications rollout disables user',
    () async {
      when(
        () => flagStore.isEnabledFor(
          FeatureFlag.smartNotifications,
          userId: 'user-123',
        ),
      ).thenAnswer((_) async => false);

      await coordinator.runNotificationSweep();

      verifyNever(() => insightsService.runSweep());
    },
  );

  test(
    'runNotificationSweep runs when smart notifications is enabled',
    () async {
      when(
        () => flagStore.isEnabledFor(
          FeatureFlag.smartNotifications,
          userId: 'user-123',
        ),
      ).thenAnswer((_) async => true);
      when(() => insightsService.runSweep()).thenAnswer((_) async {});

      await coordinator.runNotificationSweep();

      verify(() => insightsService.runSweep()).called(1);
    },
  );

  test('android strategy uses near-real-time sms cadence', () {
    final strategy = BackgroundSyncStrategy.forTargetPlatform(
      TargetPlatform.android,
    );
    expect(strategy.smsInterval, const Duration(minutes: 2));
    expect(strategy.recurringInterval, const Duration(minutes: 2));
  });

  test('non-android strategy keeps conservative cadence', () {
    final strategy = BackgroundSyncStrategy.forTargetPlatform(
      TargetPlatform.iOS,
    );
    expect(strategy.smsInterval, const Duration(minutes: 10));
    expect(strategy.recurringInterval, const Duration(minutes: 5));
  });
}
