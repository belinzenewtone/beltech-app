import 'package:beltech/core/telemetry/revamp_telemetry_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final revampTelemetryServiceProvider = Provider<RevampTelemetryService>(
  (_) => RevampTelemetryService(),
);
