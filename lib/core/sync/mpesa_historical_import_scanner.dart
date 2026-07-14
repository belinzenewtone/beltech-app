import 'package:beltech/core/logger/app_logger.dart';
import 'package:beltech/features/auth/domain/repositories/account_repository.dart';
import 'package:beltech/features/expenses/domain/repositories/expenses_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MpesaHistoricalImportScanner {
  MpesaHistoricalImportScanner(
    this._expensesRepository,
    this._accountRepository,
  );

  static const Duration defaultLookbackWindow = Duration(days: 3650);
  static const String _donePrefix = 'mpesa_historical_scan_done';
  static const String _atPrefix = 'mpesa_historical_scan_at';
  static const String _countPrefix = 'mpesa_historical_scan_count';

  final ExpensesRepository _expensesRepository;
  final AccountRepository _accountRepository;

  Future<int> runOnce({Duration lookbackWindow = defaultLookbackWindow}) async {
    final scope = _scopeKey();
    if (await _hasCompleted(scope)) {
      return 0;
    }
    try {
      final from = DateTime.now().subtract(lookbackWindow);
      final imported = await _expensesRepository.importFromDevice(from: from);
      await _markCompleted(scope: scope, importedCount: imported);
      AppLogger.info(
        'Historical MPESA scan finished (scope=$scope, imported=$imported)',
        tag: 'MpesaHistoricalImport',
      );
      return imported;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Historical MPESA scan failed',
        tag: 'MpesaHistoricalImport',
        error: error,
        stackTrace: stackTrace,
      );
      return 0;
    }
  }

  Future<bool> _hasCompleted(String scope) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_donePrefix.$scope') == true;
  }

  Future<void> _markCompleted({
    required String scope,
    required int importedCount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_donePrefix.$scope', true);
    await prefs.setInt('$_countPrefix.$scope', importedCount);
    await prefs.setString(
      '$_atPrefix.$scope',
      DateTime.now().toIso8601String(),
    );
  }

  String _scopeKey() {
    final session = _accountRepository.currentSession();
    final userId = session.userId;
    if (userId != null && userId.isNotEmpty) {
      return userId;
    }
    return 'local';
  }
}
