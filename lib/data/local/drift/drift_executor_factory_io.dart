import 'dart:io';

import 'package:beltech/data/local/db_encryption_key_store.dart';
import 'package:drift/backends.dart';
import 'package:drift/drift.dart' show LazyDatabase;
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor openDriftExecutor({
  required String name,
  bool inMemory = false,
}) {
  if (inMemory) {
    // In-memory databases (used in tests) are never encrypted.
    return NativeDatabase.memory();
  }
  return LazyDatabase(() async {
    final directory = await getApplicationSupportDirectory();
    final path = p.join(directory.path, name);
    final key = await DbEncryptionKeyStore.loadOrGenerate();
    return NativeDatabase(
      File(path),
      setup: (db) {
        // SQLCipher key — must be set before any other statement.
        // With sqlite3_flutter_libs this is a no-op; with
        // sqlcipher_flutter_libs it enables AES-256 encryption.
        db.execute("PRAGMA key = '$key'");
      },
    );
  });
}
