import 'package:drift/backends.dart';

import 'drift_executor_factory_io.dart'
    if (dart.library.js_interop) 'drift_executor_factory_web.dart'
    as executor_factory;

QueryExecutor openDriftExecutor({
  required String name,
  bool inMemory = false,
}) {
  return executor_factory.openDriftExecutor(name: name, inMemory: inMemory);
}
