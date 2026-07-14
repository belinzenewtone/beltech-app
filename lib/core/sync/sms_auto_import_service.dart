import 'dart:async';

import 'package:beltech/core/logger/app_logger.dart';
import 'package:beltech/core/platform/runtime_env.dart';
import 'package:beltech/core/sync/sms_receiver_channel.dart';
import 'package:beltech/features/auth/domain/repositories/account_repository.dart';
import 'package:beltech/features/expenses/domain/repositories/expenses_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SmsAutoImportService {
  SmsAutoImportService(this._expensesRepository, this._accountRepository);

  static const Duration defaultInterval = Duration(minutes: 5);
  static const Duration initialWindow = Duration(days: 90);
  static const String _keyPrefix = 'mpesa_auto_sync_last_ms';
  static const String _errorPrefix = 'mpesa_auto_sync_last_error';

  final ExpensesRepository _expensesRepository;
  final AccountRepository _accountRepository;

  Timer? _timer;
  bool _running = false;
  bool _syncInFlight = false;
  StreamSubscription<RawSmsEvent>? _realtimeSub;

  /// Subscribe to the native SMS stream for real-time ingestion.
  ///
  /// Each [RawSmsEvent] is forwarded to [importRealtimeSmsMessage], which
  /// preserves the carrier timestamp in the queue row.  Safe to call multiple
  /// times — subsequent calls are no-ops.
  void registerNativeReceiver() {
    if (_realtimeSub != null) return;
    SmsReceiverChannel.instance.initialize();
    _realtimeSub = SmsReceiverChannel.instance.events.listen((event) {
      unawaited(_expensesRepository.importRealtimeSmsMessage(
        body:       event.body,
        sender:     event.sender,
        receivedAt: event.receivedAt,
      ));
    });
  }

  Future<void> start({Duration interval = defaultInterval}) async {
    if (hasRuntimeEnv('FLUTTER_TEST')) {
      return;
    }
    if (_running) {
      return;
    }
    _running = true;
    registerNativeReceiver();
    await syncNow();
    _timer = Timer.periodic(interval, (_) {
      unawaited(syncNow());
    });
  }

  Future<void> stop() async {
    _running = false;
    _timer?.cancel();
    _timer = null;
    await _realtimeSub?.cancel();
    _realtimeSub = null;
  }

  Future<int> syncNow() async {
    if (hasRuntimeEnv('FLUTTER_TEST')) {
      return 0;
    }
    if (_syncInFlight) {
      return 0;
    }
    _syncInFlight = true;
    try {
      final lastSync = await _loadLastSync();
      final from = lastSync == null
          ? DateTime.now().subtract(initialWindow)
          : lastSync.subtract(const Duration(minutes: 2));
      final imported = await _expensesRepository.importFromDevice(from: from);
      await _saveLastSync(DateTime.now());
      return imported;
    } catch (error, stackTrace) {
      AppLogger.error(
        'SMS auto-import failed',
        error: error,
        stackTrace: stackTrace,
        tag: 'SmsAutoImport',
      );
      await _saveLastError('$error');
      return 0;
    } finally {
      _syncInFlight = false;
    }
  }

  Future<DateTime?> _loadLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final scope = _syncScopeKey();
    final value = prefs.getInt('$_keyPrefix.$scope');
    if (value == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  Future<void> _saveLastSync(DateTime at) async {
    final prefs = await SharedPreferences.getInstance();
    final scope = _syncScopeKey();
    await prefs.setInt('$_keyPrefix.$scope', at.millisecondsSinceEpoch);
  }

  Future<void> _saveLastError(String error) async {
    final prefs = await SharedPreferences.getInstance();
    final scope = _syncScopeKey();
    await prefs.setString(
      '$_errorPrefix.$scope',
      '${DateTime.now().toIso8601String()} | $error',
    );
  }

  String _syncScopeKey() {
    final session = _accountRepository.currentSession();
    if (session.userId != null && session.userId!.isNotEmpty) {
      return session.userId!;
    }
    return 'local';
  }
}
