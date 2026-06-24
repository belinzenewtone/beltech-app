import 'package:beltech/core/bootstrap/revamp_bootstrap_service.dart';
import 'package:beltech/core/di/database_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final revampBootstrapServiceProvider = Provider<RevampBootstrapService>(
  (ref) => RevampBootstrapService(
    ref.watch(appDriftStoreProvider),
    ref.watch(assistantProfileStoreProvider),
  ),
);
