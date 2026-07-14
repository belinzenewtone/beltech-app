import 'dart:ui' as ui;

import 'package:beltech/core/feature_flags/feature_flag.dart';
import 'package:beltech/core/feature_flags/feature_flag_store.dart';
import 'package:beltech/core/notifications/local_notification_service.dart';
import 'package:beltech/core/notifications/notification_insights_service.dart';
import 'package:beltech/core/sync/bill_reminder_service.dart';
import 'package:beltech/core/sync/learning_reminder_service.dart';
import 'package:beltech/core/telemetry/revamp_telemetry_service.dart';
import 'package:beltech/core/sync/sms_auto_import_service.dart';
import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/data/local/drift/app_drift_store_mutations.dart';
import 'package:beltech/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:beltech/features/auth/data/repositories/local_account_repository_impl.dart';
import 'package:beltech/features/bills/data/repositories/bills_repository_impl.dart';
import 'package:beltech/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:beltech/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:beltech/features/learning/data/repositories/learning_repository_impl.dart';
import 'package:beltech/features/expenses/data/repositories/expenses_repository_impl.dart';
import 'package:beltech/features/expenses/data/services/device_sms_data_source.dart';
import 'package:beltech/features/expenses/data/services/merchant_learning_service.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:beltech/core/sync/sms_receiver_channel.dart';
import 'package:beltech/features/expenses/data/services/sms_ingestion_worker.dart';
import 'package:beltech/features/income/data/repositories/income_repository_impl.dart';
import 'package:beltech/features/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:beltech/features/recurring/data/services/recurring_materializer_service.dart';
import 'package:beltech/features/notifications/data/services/daily_digest_scheduler.dart';
import 'package:beltech/features/review/domain/usecases/build_week_review_data_use_case.dart';
import 'package:beltech/features/review/domain/usecases/build_week_review_ritual_use_case.dart';
import 'package:beltech/features/tasks/data/repositories/tasks_repository_impl.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

const String kBackgroundSyncTaskName = 'beltech.background.sync';
const String kBackgroundSyncPeriodicUniqueName = 'com.beltech.app.sync';
const String kBackgroundSyncOneOffUniqueName = 'beltech.background.oneoff';

@pragma('vm:entry-point')
void backgroundSyncDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    ui.DartPluginRegistrant.ensureInitialized();
    if (task == SmsIngestionWorker.taskName) {
      await BackgroundWorkerRuntime.runSmsIngest();
    } else {
      await BackgroundWorkerRuntime.run();
    }
    return true;
  });
}

class BackgroundWorkerRuntime {
  /// Lightweight entry-point used by [SmsIngestionWorker] one-shot tasks.
  /// Resets stale PROCESSING rows (crash recovery), then drains the queue.
  static Future<void> runSmsIngest() async {
    AppDriftStore? localStore;
    try {
      final store = AppDriftStore();
      localStore = store;
      final parser = const MpesaParserService();
      final merchantLearning = MerchantLearningService();
      final smsSource = DeviceSmsDataSource();
      final expenses = ExpensesRepositoryImpl(
        store,
        parser,
        merchantLearning,
        smsSource,
      );
      // Reset rows left in PROCESSING by a previously crashed worker.
      await store.resetStaleProcessingRows();
      // importSmsMessages([]) with an empty list just drains the existing queue.
      await expenses.importSmsMessages([]);
      store.emitChange();
      // Dismiss the "Processing M-Pesa SMS…" transient notification.
      await SmsReceiverChannel.dismissIngestNotification();
    } catch (error) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'background_worker_last_error',
        '${DateTime.now().toIso8601String()} | sms_ingest | $error',
      );
    } finally {
      await localStore?.dispose();
    }
  }

  static Future<void> run() async {
    AppDriftStore? localStore;
    try {
      final accountRepository = LocalAccountRepositoryImpl();
      final store = AppDriftStore();
      localStore = store;

      final parser = const MpesaParserService();
      final merchantLearning = MerchantLearningService();
      final smsSource = DeviceSmsDataSource();

      final expenses = ExpensesRepositoryImpl(
        store,
        parser,
        merchantLearning,
        smsSource,
      );
      final recurring = RecurringRepositoryImpl(store);
      final budget = BudgetRepositoryImpl(store);
      final income = IncomeRepositoryImpl(store);
      final tasks = TasksRepositoryImpl(store);
      final calendar = CalendarRepositoryImpl(store);
      final analytics = AnalyticsRepositoryImpl(store);
      final bills = BillsRepositoryImpl(store);
      final learning = LearningRepositoryImpl(store);

      final smsService = SmsAutoImportService(expenses, accountRepository);
      final recurringService = RecurringMaterializerService(recurring);
      final notifications = LocalNotificationService();
      final billReminder = BillReminderService(bills, notifications);
      final learningReminder = LearningReminderService(learning, notifications);
      final digestScheduler = DailyDigestScheduler(
        expensesRepository: expenses,
        notificationService: notifications,
      );
      final flagStore = FeatureFlagStore();
      final insights = NotificationInsightsService(
        notifications,
        budget,
        expenses,
        income,
        tasks,
        calendar,
        analytics,
        accountRepository,
        const BuildWeekReviewDataUseCase(),
        const BuildWeekReviewRitualUseCase(),
        RevampTelemetryService(),
        flagStore,
      );
      final rolloutUserId = accountRepository.currentSession().userId;

      if (await flagStore.isEnabledFor(
        FeatureFlag.backgroundSync,
        userId: rolloutUserId,
      )) {
        await smsService.syncNow();
        await recurringService.syncNow();
        await billReminder.checkAndNotify();
        await learningReminder.checkAndNotify();
        await digestScheduler.checkAndScheduleDaily();
      }
      if (await flagStore.isEnabledFor(
        FeatureFlag.smartNotifications,
        userId: rolloutUserId,
      )) {
        await insights.runSweep();
      }
    } catch (error) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'background_worker_last_error',
        '${DateTime.now().toIso8601String()} | $error',
      );
    } finally {
      await localStore?.dispose();
    }
  }
}
