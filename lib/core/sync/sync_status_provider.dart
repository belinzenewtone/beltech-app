import 'package:flutter_riverpod/legacy.dart';

enum SyncStatus { idle, syncing, synced, error, offline }

final syncStatusProvider = StateProvider<SyncStatus>(
  (_) => SyncStatus.idle,
);
