// ignore_for_file: deprecated_member_use, experimental_member_use

import 'package:drift/backends.dart';
import 'package:drift/web.dart';

QueryExecutor openDriftExecutor({
  required String name,
  bool inMemory = false,
}) {
  if (inMemory) {
    return WebDatabase(name);
  }
  return WebDatabase.withStorage(DriftWebStorage.indexedDb(name));
}
