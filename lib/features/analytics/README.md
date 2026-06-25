# analytics feature

Provides analytics and trend insights for spending, tasks, and events.

## Main classes
- `AnalyticsSnapshot` in `domain/entities/analytics_snapshot.dart`
- `AnalyticsRepository` in `domain/repositories/analytics_repository.dart`
- `AnalyticsScreen` in `presentation/analytics_screen.dart`

## Dependencies
- Repositories are resolved through `core/di/repository_providers.dart`.
- Uses `fl_chart` for bar and trend charts.
- Uses shared glass UI (`GlassCard`) and theme tokens.
