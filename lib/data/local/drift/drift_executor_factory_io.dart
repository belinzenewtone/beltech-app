import 'dart:io';

import 'package:beltech/data/local/db_encryption_key_store.dart';
import 'package:drift/backends.dart';
import 'package:drift/drift.dart' show LazyDatabase;
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

QueryExecutor openDriftExecutor({required String name, bool inMemory = false}) {
  if (inMemory) {
    // In-memory databases (used in tests) are never encrypted.
    return NativeDatabase.memory();
  }
  return LazyDatabase(() async {
    final directory = await getApplicationSupportDirectory();
    final path = p.join(directory.path, name);
    final key = await DbEncryptionKeyStore.loadOrGenerate();
    // Run SQLite on a background isolate so heavy writes (SMS import batches,
    // rollup recomputation) never block the UI thread. The SQLCipher native
    // library is loaded inside the isolate, and the key is applied in `setup`
    // (also executed in the isolate) before any other statement.
    return NativeDatabase.createInBackground(
      File(path),
      isolateSetup: () {
        if (Platform.isAndroid) {
          openCipherOnAndroid();
        }
      },
      setup: (db) {
        db.execute("PRAGMA key = '$key'");
      },
    );
  });
}
