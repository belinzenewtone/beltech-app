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
import 'package:beltech/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:beltech/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:beltech/features/auth/data/repositories/local_account_repository_impl.dart';
import 'package:beltech/features/bills/data/repositories/bills_repository_impl.dart';
import 'package:beltech/features/bills/domain/repositories/bills_repository.dart';
import 'package:beltech/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:beltech/features/budget/domain/repositories/budget_repository.dart';
import 'package:beltech/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:beltech/features/goals/data/repositories/goals_repository_impl.dart';
import 'package:beltech/features/goals/domain/repositories/goals_repository.dart';
import 'package:beltech/features/learning/data/repositories/learning_repository_impl.dart';
import 'package:beltech/features/learning/domain/repositories/learning_repository.dart';
import 'package:beltech/features/loans/data/repositories/loans_repository_impl.dart';
import 'package:beltech/features/loans/domain/repositories/loans_repository.dart';
import 'package:beltech/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:beltech/features/expenses/data/repositories/expenses_repository_impl.dart';
import 'package:beltech/features/expenses/data/services/device_sms_data_source.dart';
import 'package:beltech/features/expenses/data/services/merchant_learning_service.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:beltech/features/expenses/domain/repositories/expenses_repository.dart';
import 'package:beltech/features/income/data/repositories/income_repository_impl.dart';
import 'package:beltech/features/income/domain/repositories/income_repository.dart';
import 'package:beltech/features/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:beltech/features/recurring/data/services/recurring_materializer_service.dart';
import 'package:beltech/features/recurring/domain/repositories/recurring_repository.dart';
import 'package:beltech/features/review/domain/usecases/build_week_review_data_use_case.dart';
import 'package:beltech/features/review/domain/usecases/build_week_review_ritual_use_case.dart';
import 'package:beltech/features/tasks/data/repositories/tasks_repository_impl.dart';
import 'package:beltech/features/tasks/domain/repositories/tasks_repository.dart';
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
    await BackgroundWorkerRuntime.run();
    return true;
  });
}

class BackgroundWorkerRuntime {
  static Future<void> run() async {
    AppDriftStore? localStore;
    try {
      final accountRepository = LocalAccountRepositoryImpl();
      final store = AppDriftStore();
      localStore = store;

      final parser = const MpesaParserService();
      final merchantLearning = MerchantLearningService();
      final smsSource = DeviceSmsDataSource();

      final expenses = ExpensesRepositoryImpl(store, parser, merchantLearning, smsSource);
      final recurring = RecurringRepositoryImpl(store);
      final budget = BudgetRepositoryImpl(store);
      final income = IncomeRepositoryImpl(store);
      final tasks = TasksRepositoryImpl(store);
      final calendar = CalendarRepositoryImpl(store);
      final analytics = AnalyticsRepositoryImpl(store);
      final bills = BillsRepositoryImpl(store);
      final loans = LoansRepositoryImpl(store);
      final goals = GoalsRepositoryImpl(store);
      final learning = LearningRepositoryImpl(store);

      final smsService = SmsAutoImportService(expenses, accountRepository);
      final recurringService = RecurringMaterializerService(recurring);
      final notifications = LocalNotificationService();
      final billReminder = BillReminderService(bills, notifications);
      final learningReminder = LearningReminderService(learning, notifications);
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
