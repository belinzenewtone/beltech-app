import 'dart:async';

import 'package:beltech/core/platform/runtime_env.dart';
import 'package:beltech/features/recurring/domain/repositories/recurring_repository.dart';

class RecurringMaterializerService {
  RecurringMaterializerService(this._repository);

  final RecurringRepository _repository;
  Timer? _timer;
  bool _running = false;
  bool _inFlight = false;

  Future<void> start({Duration interval = const Duration(minutes: 3)}) async {
    if (hasRuntimeEnv('FLUTTER_TEST') || _running) {
      return;
    }
    _running = true;
    await syncNow();
    _timer = Timer.periodic(interval, (_) {
      unawaited(syncNow());
    });
  }

  Future<void> stop() async {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<int> syncNow() async {
    if (hasRuntimeEnv('FLUTTER_TEST') || _inFlight) {
      return 0;
    }
    _inFlight = true;
    try {
      return await _repository.materializeDue();
    } catch (_) {
      return 0;
    } finally {
      _inFlight = false;
    }
  }
}
