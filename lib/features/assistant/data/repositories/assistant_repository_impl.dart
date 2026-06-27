import 'package:beltech/data/local/drift/assistant_profile_store.dart';
import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/assistant/domain/ai_engine/cash_flow_projector.dart';
import 'package:beltech/features/assistant/domain/ai_engine/models/data_context.dart';
import 'package:beltech/features/assistant/domain/ai_engine/offline_ai_engine.dart';
import 'package:beltech/features/assistant/domain/entities/assistant_message.dart';
import 'package:beltech/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:beltech/features/bills/domain/repositories/bills_repository.dart';
import 'package:beltech/features/goals/domain/repositories/goals_repository.dart';
import 'package:beltech/features/learning/domain/repositories/learning_repository.dart';
import 'package:beltech/features/loans/domain/entities/loan_item.dart';
import 'package:beltech/features/loans/domain/repositories/loans_repository.dart';

class AssistantRepositoryImpl implements AssistantRepository {
  AssistantRepositoryImpl(
    this._store,
    this._appStore, {
    Object? proxyService,
    BillsRepository? billsRepository,
    LoansRepository? loansRepository,
    GoalsRepository? goalsRepository,
    LearningRepository? learningRepository,
  })  : _billsRepository = billsRepository,
        _loansRepository = loansRepository,
        _goalsRepository = goalsRepository,
        _learningRepository = learningRepository;

  final AssistantProfileStore _store;
  final AppDriftStore _appStore;
  final BillsRepository? _billsRepository;
  final LoansRepository? _loansRepository;
  final GoalsRepository? _goalsRepository;
  final LearningRepository? _learningRepository;

  static const _offlineEngine = OfflineAiEngine();

  @override
  Stream<List<AssistantMessage>> watchConversation() {
    return _store.watchMessages().map(
      (rows) => rows
          .map(
            (row) => AssistantMessage(
              id: row.id,
              text: row.text,
              isUser: row.isUser,
              createdAt: row.createdAt,
            ),
          )
          .toList(),
    );
  }

  @override
  List<AssistantSuggestion> suggestions() {
    return const [
      AssistantSuggestion('How much did I spend today?'),
      AssistantSuggestion("What's my financial health score?"),
      AssistantSuggestion('Show my spending by category'),
      AssistantSuggestion('Any anomalies in my spending?'),
      AssistantSuggestion('Project my cash flow for next month'),
      AssistantSuggestion('How are my goals doing?'),
      AssistantSuggestion('What bills are due soon?'),
    ];
  }

  @override
  Future<void> sendMessage(String text) async {
    final normalized = text.trim();
    if (normalized.isEmpty) return;
    await _store.addAssistantMessage(text: normalized, isUser: true);
    await _store.addAssistantMessage(
      text: await _buildReply(normalized),
      isUser: false,
    );
  }

  @override
  Future<void> clearConversation() async {
    await _store.clearAssistantMessages();
  }

  Future<String> _buildReply(String prompt) async {
    return _offlineEngine.reply(
      query: prompt,
      totalBalance: _totalBalance(),
      todaySpending: _todaySpending(),
      weekSpending: _weekSpending(),
      monthSpending: _monthSpending(),
      monthIncome: _monthIncome(),
      pendingTasksCount: _pendingTasks(),
      overdueTasksCount: _overdueTasks(),
      weekEventsCount: _eventsThisWeek(),
      topCategories: _topCategoriesInCurrentMonth(),
      recentTransactions: _recentTransactions(),
      billsUpcoming: _upcomingBills(),
      billsOverdue: _overdueBills(),
      loansOutstanding: _loansOutstanding(),
      loansActiveCount: _loansActiveCount(),
      goals: _goalSummaries(),
      learningStreak: _learningStreak(),
      monthlyLearningMinutes: _monthlyLearningMinutes(),
      avgDailyIncome: _avgDailyIncome(),
      avgDailyExpense: _avgDailyExpense(),
      loanPayments: _loanPayments(),
    );
  }

  // --- Data suppliers for offline engine ---

  Future<double> _totalBalance() async {
    await _appStore.ensureInitialized();
    final rows = await _appStore.executor.runSelect(
      'SELECT COALESCE(SUM(CASE WHEN transaction_type = \'income\' THEN amount ELSE -amount END), 0) AS balance FROM transactions',
      const [],
    );
    final v = rows.firstOrNull?['balance'];
    return _asDouble(v);
  }

  Future<double> _todaySpending() async {
    final now = DateTime.now();
    return _sumTransactions(
      DateTime(now.year, now.month, now.day),
      DateTime(now.year, now.month, now.day).add(const Duration(days: 1)),
    );
  }

  Future<double> _weekSpending() async {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return _sumTransactions(start, start.add(const Duration(days: 7)));
  }

  Future<double> _monthSpending() async {
    final now = DateTime.now();
    return _sumTransactions(
      DateTime(now.year, now.month, 1),
      DateTime(now.year, now.month + 1, 1),
    );
  }

  Future<double> _monthIncome() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    await _appStore.ensureInitialized();
    final rows = await _appStore.executor.runSelect(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM transactions WHERE transaction_type = ? AND occurred_at >= ? AND occurred_at < ?',
      ['income', start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    return _asDouble(rows.firstOrNull?['total']);
  }

  Future<int> _pendingTasks() async {
    await _appStore.ensureInitialized();
    final rows = await _appStore.executor.runSelect(
      "SELECT COUNT(*) AS total FROM tasks WHERE status != 'completed'",
      const [],
    );
    return _asInt(rows.firstOrNull?['total']);
  }

  Future<int> _overdueTasks() async {
    await _appStore.ensureInitialized();
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = await _appStore.executor.runSelect(
      "SELECT COUNT(*) AS total FROM tasks WHERE status != 'completed' AND deadline IS NOT NULL AND deadline < ?",
      [now],
    );
    return _asInt(rows.firstOrNull?['total']);
  }

  Future<int> _eventsThisWeek() async {
    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    var count = 0;
    for (var i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final events = await _appStore.watchEventsForDay(day).first;
      count += events.length;
    }
    return count;
  }

  Future<List<(String, double)>> _topCategoriesInCurrentMonth() async {
    await _appStore.ensureInitialized();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    final rows = await _appStore.executor.runSelect(
      'SELECT category, COALESCE(SUM(amount), 0) AS total FROM transactions '
      'WHERE occurred_at >= ? AND occurred_at < ? GROUP BY category ORDER BY total DESC LIMIT 5',
      [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    return rows.map((r) {
      final cat = '${r['category'] ?? 'Other'}';
      return (cat, _asDouble(r['total']));
    }).toList();
  }

  Future<List<RecentTransaction>> _recentTransactions() async {
    await _appStore.ensureInitialized();
    final rows = await _appStore.executor.runSelect(
      'SELECT title, category, amount, occurred_at, transaction_type FROM transactions ORDER BY occurred_at DESC LIMIT 30',
      const [],
    );
    return rows
        .map(
          (r) => RecentTransaction(
            title: '${r['title'] ?? ''}',
            category: '${r['category'] ?? ''}',
            amount: _asDouble(r['amount']),
            date: DateTime.fromMillisecondsSinceEpoch(_asInt(r['occurred_at'])),
            type: '${r['transaction_type'] ?? 'expense'}',
          ),
        )
        .toList();
  }

  Future<List<UpcomingBill>> _upcomingBills() async {
    if (_billsRepository == null) return [];
    final bills = await _billsRepository.loadBills();
    final now = DateTime.now();
    return bills
        .where((b) => !b.paid && b.dueDate.isAfter(now))
        .map(
          (b) => UpcomingBill(
            name: b.name,
            amount: b.amount,
            dueDate: b.dueDate,
            daysUntil: b.dueDate.difference(now).inDays,
          ),
        )
        .toList()
      ..sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
  }

  Future<List<UpcomingBill>> _overdueBills() async {
    if (_billsRepository == null) return [];
    final bills = await _billsRepository.loadBills();
    final now = DateTime.now();
    return bills
        .where((b) => !b.paid && b.dueDate.isBefore(now))
        .map(
          (b) => UpcomingBill(
            name: b.name,
            amount: b.amount,
            dueDate: b.dueDate,
            daysUntil: b.dueDate.difference(now).inDays,
          ),
        )
        .toList();
  }

  Future<double> _loansOutstanding() async {
    if (_loansRepository == null) return 0;
    return _loansRepository.totalOutstanding();
  }

  Future<int> _loansActiveCount() async {
    if (_loansRepository == null) return 0;
    final loans = await _loansRepository.loadLoans();
    return loans.where((l) => l.status == LoanStatus.active).length;
  }

  Future<List<GoalSummary>> _goalSummaries() async {
    if (_goalsRepository == null) return [];
    final goals = await _goalsRepository.loadGoals();
    return goals
        .map(
          (g) => GoalSummary(
            title: g.title,
            target: g.targetAmount,
            current: g.currentAmount,
            progressPercent: g.progressPercent,
            atRisk: g.isAtRisk,
          ),
        )
        .toList();
  }

  Future<int> _learningStreak() async {
    if (_learningRepository == null) return 0;
    return _learningRepository.currentStreak();
  }

  Future<int> _monthlyLearningMinutes() async {
    if (_learningRepository == null) return 0;
    return _learningRepository.monthlyMinutes(DateTime.now());
  }

  Future<double> _avgDailyIncome() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final days = max(1, now.difference(monthStart).inDays + 1);
    final income = await _monthIncome();
    return income / days;
  }

  Future<double> _avgDailyExpense() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final days = max(1, now.difference(monthStart).inDays + 1);
    final spending = await _monthSpending();
    return spending / days;
  }

  Future<List<LoanPayment>> _loanPayments() async {
    if (_loansRepository == null) return [];
    final loans = await _loansRepository.loadLoans();
    return loans
        .where((l) => l.status == LoanStatus.active && l.dueDate != null)
        .map(
          (l) => LoanPayment(
            loanName: l.name,
            amount: l.outstandingAmount,
            dueDate: l.dueDate!,
          ),
        )
        .toList();
  }

  Future<double> _sumTransactions(DateTime start, DateTime end) async {
    await _appStore.ensureInitialized();
    final rows = await _appStore.executor.runSelect(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM transactions WHERE occurred_at >= ? AND occurred_at < ?',
      [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    return _asDouble(rows.firstOrNull?['total']);
  }

  double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  int max(int a, int b) => a > b ? a : b;
}
