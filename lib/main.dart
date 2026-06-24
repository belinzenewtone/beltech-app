import 'package:beltech/core/di/feature_flag_providers.dart';
import 'package:beltech/core/platform/runtime_env.dart';
import 'package:beltech/core/routing/app_router.dart';
import 'package:beltech/core/theme/app_theme.dart';
import 'package:beltech/core/theme/theme_mode_controller.dart';
import 'package:beltech/core/update/presentation/global_update_host.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// Sentry DSN is injected at build time via --dart-define=SENTRY_DSN=...
// Leave blank to disable crash reporting (default for local dev).
const _sentryDsn = String.fromEnvironment('SENTRY_DSN');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  void appRunner() {
    runApp(
      const ProviderScope(
        child: PersonalManagementApp(),
      ),
    );
  }

  if (_sentryDsn.isNotEmpty && !hasRuntimeEnv('FLUTTER_TEST')) {
    await SentryFlutter.init(
      (options) {
        options.dsn = _sentryDsn;
        options.tracesSampleRate = 0.1;
        options.environment = kReleaseMode ? 'production' : 'development';
        // Privacy: strip user identity from all events; never include
        // transaction amounts or merchant names in error reports.
        options.beforeSend = (event, hint) {
          event.user = null;
          return event;
        };
      },
      appRunner: appRunner,
    );
  } else {
    appRunner();
  }
}

class PersonalManagementApp extends ConsumerWidget {
  const PersonalManagementApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activate haptics feature flag gate — syncs AppHaptics.setEnabled globally.
    ref.watch(hapticsFeatureFlagProvider);
    final themeMode = ref.watch(currentThemeModeProvider);
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'BELTECH',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => GlobalUpdateHost(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
