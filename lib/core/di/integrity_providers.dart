import 'package:beltech/core/di/database_providers.dart';
import 'package:beltech/core/sync/data_integrity_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dataIntegrityServiceProvider = Provider<DataIntegrityService>(
  (ref) => DataIntegrityService(ref.watch(appDriftStoreProvider)),
);

final integrityReportProvider = FutureProvider<IntegrityReport>(
  (ref) => ref.watch(dataIntegrityServiceProvider).runChecks(),
);
