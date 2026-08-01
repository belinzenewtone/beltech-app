import 'dart:async';

import 'package:beltech/features/recurring/domain/repositories/recurring_repository.dart';

/// Periodic service that materializes due recurring rules into actual expenses.
class RecurringMaterializerService {
  RecurringMaterializerService(this._recurringRepository);

  final RecurringRepository _recurringRepository;
  Timer? _timer;

  Future<void> start({Duration interval = const Duration(minutes: 5)}) async {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => syncNow());
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  /// Called by the background worker. Delegates to the repository which
  /// persists expenses and advances nextRunAt atomically.
  Future<void> syncNow() async {
    try {
      await _recurringRepository.materializeDue();
    } catch (_) {
      // background worker continues on failure
    }
  }
}
