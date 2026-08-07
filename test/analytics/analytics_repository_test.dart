import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:beltech/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDriftStore store;
  late AnalyticsRepositoryImpl repository;

  setUp(() {
    store = AppDriftStore();
    repository = AnalyticsRepositoryImpl(store);
  });

  tearDown(() async {
    await store.dispose();
  });

  Future<void> addTx({
    required String title,
    required String category,
    required double amount,
    required DateTime occurredAt,
    String type = 'expense',
    double? fee,
  }) async {
    await store.addTransaction(
      title: title,
      category: category,
      amountKes: amount,
      occurredAt: occurredAt,
      source: 'manual',
      sourceHash:
          '$title-${occurredAt.millisecondsSinceEpoch}-$amount-$category',
      transactionType: type,
      feeKes: fee,
    );
  }

  Future<void> addIncome({
    required String title,
    required double amount,
    required DateTime receivedAt,
  }) async {
    await store.insertIncomeBatch([
      [
        title,
        amount,
        receivedAt.millisecondsSinceEpoch,
        'manual',
        'income-${receivedAt.millisecondsSinceEpoch}',
      ],
    ]);
  }

  test('period snapshot sums expense transactions only', () async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    await addTx(
      title: 'Groceries',
      category: 'Food',
      amount: 500,
      occurredAt: monthStart.add(const Duration(days: 2)),
    );
    await addTx(
      title: 'Salary',
      category: 'Salary',
      amount: 100000,
      occurredAt: monthStart.add(const Duration(days: 3)),
      type: 'income',
    );

    final snapshot = await repository.watchSnapshot(AnalyticsPeriod.month).first;
    expect(snapshot.totalSpentThisPeriodKes, 500);
    expect(snapshot.totalIncomeThisPeriodKes, 0);
    expect(snapshot.categoryBreakdown, hasLength(1));
    expect(snapshot.categoryBreakdown.first.category, 'Food');
    expect(snapshot.categoryBreakdown.first.totalKes, 500);
  });

  test('category breakdown includes only categories with spend', () async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    await addTx(
      title: 'A',
      category: 'Transport',
      amount: 300,
      occurredAt: monthStart.add(const Duration(days: 1)),
    );
    await addTx(
      title: 'B',
      category: 'Food',
      amount: 700,
      occurredAt: monthStart.add(const Duration(days: 2)),
    );
    // income-type row in a category must not appear
    await addTx(
      title: 'C',
      category: 'Food',
      amount: 9000,
      occurredAt: monthStart.add(const Duration(days: 3)),
      type: 'income',
    );

    final snapshot = await repository.watchSnapshot(AnalyticsPeriod.month).first;
    expect(snapshot.categoryBreakdown, hasLength(2));
    final food = snapshot.categoryBreakdown.firstWhere((c) => c.category == 'Food');
    expect(food.totalKes, 700);
    final transport =
        snapshot.categoryBreakdown.firstWhere((c) => c.category == 'Transport');
    expect(transport.totalKes, 300);
  });

  test('spend anatomy buckets use 6-month window boundaries', () async {
    final now = DateTime.now();
    // 499 -> micro, 500 -> medium, 1999 -> medium, 2000 -> large
    await addTx(title: 'a', category: 'Food', amount: 499, occurredAt: now.subtract(const Duration(days: 1)));
    await addTx(title: 'b', category: 'Food', amount: 500, occurredAt: now.subtract(const Duration(days: 2)));
    await addTx(title: 'c', category: 'Food', amount: 1999, occurredAt: now.subtract(const Duration(days: 3)));
    await addTx(title: 'd', category: 'Food', amount: 2000, occurredAt: now.subtract(const Duration(days: 4)));

    final snapshot = await repository.watchSnapshot(AnalyticsPeriod.month).first;
    expect(snapshot.microTxCount, 1);
    expect(snapshot.mediumTxCount, 2);
    expect(snapshot.largeTxCount, 1);
  });

  test('6-month history carries expense/income/txCount per month', () async {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 10);
    final prevMonth = DateTime(now.year, now.month - 1, 15);
    await addTx(title: 'a', category: 'Food', amount: 1000, occurredAt: thisMonth);
    await addTx(title: 'b', category: 'Food', amount: 2000, occurredAt: prevMonth);
    await addIncome(title: 'Salary', amount: 50000, receivedAt: prevMonth);

    final snapshot = await repository.watchSnapshot(AnalyticsPeriod.month).first;
    expect(snapshot.monthlyHistory, hasLength(6));
    final current = snapshot.monthlyHistory
        .firstWhere((m) => m.year == now.year && m.month == now.month);
    expect(current.totalKes, 1000);
    expect(current.txCount, 1);
    final previous = snapshot.monthlyHistory
        .firstWhere((m) => m.year == now.year && m.month == now.month - 1);
    expect(previous.totalKes, 2000);
    expect(previous.totalIncomeKes, 50000);
  });

  test('insights aggregates compute avg, total, top category and trend', () async {
    final now = DateTime.now();
    // 3 distinct months: Food 1000+1000 (2 months), Transport 1000 (1 month)
    await addTx(title: 't0', category: 'Food', amount: 1000.0, occurredAt: DateTime(now.year, now.month, 10));
    await addTx(title: 't1', category: 'Food', amount: 1000.0, occurredAt: DateTime(now.year, now.month - 1, 10));
    await addTx(title: 't2', category: 'Transport', amount: 1000.0, occurredAt: DateTime(now.year, now.month - 2, 10));

    final snapshot = await repository.watchSnapshot(AnalyticsPeriod.month).first;
    final expenseMonths = snapshot.monthlyHistory.where((m) => m.totalKes > 0).toList();
    expect(expenseMonths, hasLength(3));
    expect(snapshot.avgMonthlyExpenseKes, closeTo(1000, 0.01));
    expect(snapshot.totalTrackedKes, closeTo(3000, 0.01));
    expect(snapshot.topCategoryAllTime, 'Food');
    expect(snapshot.topCategoryAllTimePct, closeTo(66.67, 0.1));
    expect(['increasing', 'decreasing', 'stable'], contains(snapshot.trend));
  });

  test('monthly breakdown has deltas and top categories per month', () async {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 10);
    final prevMonth = DateTime(now.year, now.month - 1, 15);
    await addTx(title: 'a', category: 'Food', amount: 1000, occurredAt: thisMonth);
    await addTx(title: 'b', category: 'Transport', amount: 2000, occurredAt: prevMonth);

    final snapshot = await repository.watchSnapshot(AnalyticsPeriod.month).first;
    expect(snapshot.monthBreakdown, isNotEmpty);
    final currentBreakdown = snapshot.monthBreakdown
        .firstWhere((m) => m.year == now.year && m.month == now.month);
    expect(currentBreakdown.totalKes, 1000);
    expect(currentBreakdown.txCount, 1);
    expect(currentBreakdown.topCategories, isNotEmpty);
    expect(currentBreakdown.topCategories.first.category, 'Food');
    // previous month total is the delta base
    expect(currentBreakdown.previousMonthTotalKes, 2000);
  });

  test('payday pulse requires at least two incomes and uses days with spend', () async {
    final now = DateTime.now();
    // Two incomes 30 days apart, 8 weeks back (within the 6-month window).
    final income1 = now.subtract(const Duration(days: 40));
    final income2 = now.subtract(const Duration(days: 10));
    await addIncome(title: 'Salary', amount: 100000, receivedAt: income1);
    await addIncome(title: 'Salary', amount: 100000, receivedAt: income2);

    // Spend on day 1 after income1 and day 1 after income2 (post-income days)
    await addTx(title: 'p1', category: 'Food', amount: 500, occurredAt: income1.add(const Duration(days: 1)));
    await addTx(title: 'p2', category: 'Food', amount: 300, occurredAt: income2.add(const Duration(days: 1)));
    // Spend on a day that's not post-income
    await addTx(title: 'o', category: 'Food', amount: 100, occurredAt: now.subtract(const Duration(days: 3)));

    final snapshot = await repository.watchSnapshot(AnalyticsPeriod.month).first;
    expect(snapshot.postIncomeAvgDailySpendKes, isNotNull);
    expect(snapshot.otherDaysAvgDailySpendKes, isNotNull);
    expect(snapshot.postIncomeAvgDailySpendKes!, closeTo(400, 0.01));
    expect(snapshot.otherDaysAvgDailySpendKes!, closeTo(100, 0.01));
    expect(snapshot.incomeEventsCount, greaterThanOrEqualTo(2));
  });

  test('category transactions returns real rows for a category', () async {
    final now = DateTime.now();
    await addTx(title: 'Matatu', category: 'Transport', amount: 200, occurredAt: now.subtract(const Duration(days: 1)));
    await addTx(title: 'Uber', category: 'Transport', amount: 400, occurredAt: now.subtract(const Duration(days: 2)));
    await addTx(title: 'Resto', category: 'Food', amount: 600, occurredAt: now.subtract(const Duration(days: 3)));

    final txns = await repository.getCategoryTransactions('Transport');
    expect(txns, hasLength(2));
    expect(txns.map((t) => t.title), containsAll(['Matatu', 'Uber']));
    expect(txns.map((t) => t.title), isNot(contains('Resto')));
  });
}
