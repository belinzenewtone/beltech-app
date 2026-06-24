import 'package:drift/drift.dart';

class DriftSchema {
  DriftSchema._();

  static const int version = 1;

  static MigrationStrategy get migrationStrategy => MigrationStrategy(
        onCreate: (migrator) async {
          // Tables are created via generated Drift database classes in later phases.
        },
        onUpgrade: (migrator, from, to) async {
          if (from < 1) {
            // Placeholder for forward-compatible migration blocks.
          }
        },
        beforeOpen: (details) async {
          // Entry point for PRAGMA and bootstrap logic.
        },
      );
}
