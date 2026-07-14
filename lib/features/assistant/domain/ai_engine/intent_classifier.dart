/// Classifies user queries into actionable intents.
/// Pure Dart, no dependencies. Works offline.
class IntentClassifier {
  const IntentClassifier();

  Intent classify(String query) {
    final lower = query.toLowerCase().trim();

    if (_matches(lower, _spendingPatterns)) return Intent.spendingSummary;
    if (_matches(lower, _incomePatterns)) return Intent.incomeSummary;
    if (_matches(lower, _balancePatterns)) return Intent.balanceCheck;
    if (_matches(lower, _taskPatterns)) return Intent.taskSummary;
    if (_matches(lower, _eventPatterns)) return Intent.eventSummary;
    if (_matches(lower, _healthPatterns)) return Intent.healthCheck;
    if (_matches(lower, _anomalyPatterns)) return Intent.anomalyAlert;
    if (_matches(lower, _cashFlowPatterns)) return Intent.cashFlowProjection;
    if (_matches(lower, _goalPatterns)) return Intent.goalSummary;
    if (_matches(lower, _loanPatterns)) return Intent.loanSummary;
    if (_matches(lower, _billPatterns)) return Intent.billSummary;
    if (_matches(lower, _learningPatterns)) return Intent.learningSummary;
    if (_matches(lower, _advicePatterns)) return Intent.financialAdvice;
    if (_matches(lower, _comparePatterns)) return Intent.spendingComparison;
    if (_matches(lower, _merchantPatterns)) return Intent.merchantSummary;
    if (_matches(lower, _exportPatterns)) return Intent.exportData;
    if (_matches(lower, _categoryPatterns)) return Intent.categoryBreakdown;

    return Intent.unknown;
  }

  bool _matches(String lower, List<String> patterns) {
    for (final p in patterns) {
      if (lower.contains(p)) return true;
    }
    return false;
  }

  static const _spendingPatterns = [
    'spend',
    'spent',
    'spending',
    'how much',
    'expense',
    'expenses',
    'where did my money',
    'where is my money',
    'cost',
    'costs',
    'outflow',
  ];

  static const _incomePatterns = [
    'income',
    'earned',
    'salary',
    'received',
    'inflow',
    'money in',
  ];

  static const _balancePatterns = [
    'balance',
    'net worth',
    'how much do i have',
    'total money',
    'what is my balance',
    'account balance',
  ];

  static const _taskPatterns = [
    'task',
    'tasks',
    'todo',
    'to do',
    'pending',
    'overdue',
    'reminder',
    'what do i need to do',
    'what should i do',
  ];

  static const _eventPatterns = [
    'event',
    'events',
    'calendar',
    'schedule',
    'meeting',
    'appointment',
    'what is happening',
    'what do i have',
    'this week',
  ];

  static const _healthPatterns = [
    'health',
    'financial health',
    'how am i doing',
    'score',
    'am i okay',
    'status',
    'overview',
    'summary',
  ];

  static const _anomalyPatterns = [
    'anomaly',
    'anomalies',
    'strange',
    'weird',
    'suspicious',
    'duplicate',
    'unusual',
    'unexpected',
    'alert',
    'warning',
  ];

  static const _cashFlowPatterns = [
    'cash flow',
    'cashflow',
    'projection',
    'forecast',
    'future',
    'predict',
    'will i have enough',
    'can i afford',
    'next month',
  ];

  static const _goalPatterns = [
    'goal',
    'goals',
    'saving goal',
    'target',
    'savings goal',
    'progress',
  ];

  static const _loanPatterns = [
    'loan',
    'loans',
    'debt',
    'borrowed',
    'lender',
    'outstanding loan',
  ];

  static const _billPatterns = [
    'bill',
    'bills',
    'upcoming bill',
    'due',
    'payment due',
  ];

  static const _learningPatterns = [
    'learning',
    'study',
    'streak',
    'how many days',
    'learning streak',
  ];

  static const _advicePatterns = [
    'advice',
    'tip',
    'tips',
    'recommend',
    'suggestion',
    'how can i save',
    'how to improve',
    'what should i do',
  ];

  static const _comparePatterns = [
    'compare',
    'comparison',
    'vs',
    'versus',
    'last month',
    'previous',
    'more than',
    'less than',
    'than last',
  ];

  static const _merchantPatterns = [
    'merchant',
    'shop',
    'store',
    'vendor',
    'where did i spend',
    'at ',
    'from ',
    'purchased from',
  ];

  static const _exportPatterns = [
    'export',
    'backup',
    'download',
    'csv',
    'pdf',
    'share data',
  ];

  static const _categoryPatterns = [
    'category',
    'categories',
    'breakdown',
    'by type',
    'grouped by',
    'spending by',
    'expenses by',
  ];
}

enum Intent {
  spendingSummary,
  incomeSummary,
  balanceCheck,
  taskSummary,
  eventSummary,
  healthCheck,
  anomalyAlert,
  cashFlowProjection,
  goalSummary,
  loanSummary,
  billSummary,
  learningSummary,
  financialAdvice,
  spendingComparison,
  merchantSummary,
  exportData,
  categoryBreakdown,
  unknown,
}
