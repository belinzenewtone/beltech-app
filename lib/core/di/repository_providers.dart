import 'package:beltech/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:beltech/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:beltech/core/di/database_providers.dart';
import 'package:beltech/core/di/security_providers.dart';
import 'package:beltech/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:beltech/features/auth/data/repositories/local_account_repository_impl.dart';
import 'package:beltech/features/auth/domain/repositories/account_repository.dart';
import 'package:beltech/features/auth/domain/repositories/auth_repository.dart';
import 'package:beltech/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:beltech/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:beltech/features/assistant/data/repositories/assistant_repository_impl.dart';
import 'package:beltech/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:beltech/features/bills/data/repositories/bills_repository_impl.dart';
import 'package:beltech/features/bills/domain/repositories/bills_repository.dart';
import 'package:beltech/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:beltech/features/budget/domain/repositories/budget_repository.dart';
import 'package:beltech/features/loans/data/repositories/loans_repository_impl.dart';
import 'package:beltech/features/loans/domain/repositories/loans_repository.dart';
import 'package:beltech/features/goals/data/repositories/goals_repository_impl.dart';
import 'package:beltech/features/goals/domain/repositories/goals_repository.dart';
import 'package:beltech/features/learning/data/repositories/learning_repository_impl.dart';
import 'package:beltech/features/learning/domain/repositories/learning_repository.dart';
import 'package:beltech/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:beltech/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:beltech/features/expenses/data/repositories/expenses_repository_impl.dart';
import 'package:beltech/features/expenses/data/services/device_sms_data_source.dart';
import 'package:beltech/features/expenses/data/services/merchant_learning_service.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:beltech/features/expenses/domain/repositories/expenses_repository.dart';
import 'package:beltech/features/export/data/repositories/export_history_repository_impl.dart';
import 'package:beltech/features/export/data/repositories/export_repository_impl.dart';
import 'package:beltech/features/export/domain/repositories/export_history_repository.dart';
import 'package:beltech/features/export/domain/repositories/export_repository.dart';
import 'package:beltech/features/home/data/repositories/home_repository_impl.dart';
import 'package:beltech/features/home/domain/repositories/home_repository.dart';
import 'package:beltech/features/income/data/repositories/income_repository_impl.dart';
import 'package:beltech/features/income/domain/repositories/income_repository.dart';
import 'package:beltech/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:beltech/features/profile/domain/repositories/profile_repository.dart';
import 'package:beltech/features/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:beltech/features/recurring/domain/repositories/recurring_repository.dart';
import 'package:beltech/features/search/data/repositories/global_search_repository_impl.dart';
import 'package:beltech/features/search/domain/repositories/global_search_repository.dart';
import 'package:beltech/features/tasks/data/repositories/tasks_repository_impl.dart';
import 'package:beltech/features/tasks/data/repositories/time_tracking_repository_impl.dart';
import 'package:beltech/features/tasks/domain/repositories/tasks_repository.dart';
import 'package:beltech/features/tasks/domain/repositories/time_tracking_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final deviceSmsDataSourceProvider = Provider<DeviceSmsDataSource>(
  (_) => DeviceSmsDataSource(),
);
final merchantLearningServiceProvider = Provider<MerchantLearningService>(
  (_) => MerchantLearningService(),
);

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepositoryImpl(ref.watch(appDriftStoreProvider)),
);
final calendarRepositoryProvider = Provider<CalendarRepository>(
  (ref) => CalendarRepositoryImpl(ref.watch(appDriftStoreProvider)),
);
final expensesRepositoryProvider = Provider<ExpensesRepository>(
  (ref) => ExpensesRepositoryImpl(
    ref.watch(appDriftStoreProvider),
    const MpesaParserService(),
    ref.watch(merchantLearningServiceProvider),
    ref.watch(deviceSmsDataSourceProvider),
  ),
);
final incomeRepositoryProvider = Provider<IncomeRepository>(
  (ref) => IncomeRepositoryImpl(ref.watch(appDriftStoreProvider)),
);
final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => BudgetRepositoryImpl(ref.watch(appDriftStoreProvider)),
);
final recurringRepositoryProvider = Provider<RecurringRepository>(
  (ref) => RecurringRepositoryImpl(ref.watch(appDriftStoreProvider)),
);
final globalSearchRepositoryProvider = Provider<GlobalSearchRepository>(
  (ref) => GlobalSearchRepositoryImpl(ref.watch(appDriftStoreProvider)),
);
final exportRepositoryProvider = Provider<ExportRepository>(
  (ref) => ExportRepositoryImpl(ref.watch(appDriftStoreProvider)),
);
final exportHistoryRepositoryProvider = Provider<ExportHistoryRepository>(
  (_) => ExportHistoryRepositoryImpl(),
);
final tasksRepositoryProvider = Provider<TasksRepository>(
  (ref) => TasksRepositoryImpl(ref.watch(appDriftStoreProvider)),
);
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(localAuthenticationProvider),
    ref.watch(secureCredentialsStoreProvider),
  ),
);
final accountRepositoryProvider = Provider<AccountRepository>(
  (_) => LocalAccountRepositoryImpl(),
);
final assistantRepositoryProvider = Provider<AssistantRepository>(
  (ref) => AssistantRepositoryImpl(
    ref.watch(assistantProfileStoreProvider),
    ref.watch(appDriftStoreProvider),
    proxyService: null,
    billsRepository: ref.watch(billsRepositoryProvider),
    loansRepository: ref.watch(loansRepositoryProvider),
    goalsRepository: ref.watch(goalsRepositoryProvider),
    learningRepository: ref.watch(learningRepositoryProvider),
  ),
);
final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => AnalyticsRepositoryImpl(ref.watch(appDriftStoreProvider)),
);
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(
    ref.watch(assistantProfileStoreProvider),
    ref.watch(secureCredentialsStoreProvider),
    ref.watch(passwordHasherProvider),
  ),
);

final billsRepositoryProvider = Provider<BillsRepository>(
  (ref) => BillsRepositoryImpl(ref.watch(appDriftStoreProvider)),
);
final loansRepositoryProvider = Provider<LoansRepository>(
  (ref) => LoansRepositoryImpl(ref.watch(appDriftStoreProvider)),
);
final goalsRepositoryProvider = Provider<GoalsRepository>(
  (ref) => GoalsRepositoryImpl(ref.watch(appDriftStoreProvider)),
);
final learningRepositoryProvider = Provider<LearningRepository>(
  (ref) => LearningRepositoryImpl(ref.watch(appDriftStoreProvider)),
);

final timeTrackingRepositoryProvider = Provider<TimeTrackingRepository>(
  (ref) => TimeTrackingRepositoryImpl(ref.watch(appDriftStoreProvider)),
);

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (_) => OnboardingRepositoryImpl(),
);
