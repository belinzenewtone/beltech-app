import 'package:beltech/core/platform/runtime_env.dart';
import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/data/local/drift/assistant_profile_store.dart';
import 'package:beltech/data/local/drift/drift_schema.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appDriftStoreProvider = Provider<AppDriftStore>(
  (ref) {
    final store = hasRuntimeEnv('FLUTTER_TEST')
        ? AppDriftStore()
        : AppDriftStore.persistent();
    ref.onDispose(() {
      store.dispose();
    });
    return store;
  },
);

final assistantProfileStoreProvider = Provider<AssistantProfileStore>(
  (ref) {
    final store = hasRuntimeEnv('FLUTTER_TEST')
        ? AssistantProfileStore()
        : AssistantProfileStore.persistent();
    ref.onDispose(() {
      store.dispose();
    });
    return store;
  },
);

final driftSchemaVersionProvider = Provider<int>((_) => DriftSchema.version);

final driftMigrationStrategyProvider = Provider<MigrationStrategy>(
  (_) => DriftSchema.migrationStrategy,
);
