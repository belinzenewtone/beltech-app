import 'dart:async';
import 'package:beltech/core/di/notification_providers.dart';
import 'package:beltech/core/routing/deep_link_router.dart';
import 'package:beltech/core/di/sync_providers.dart';
import 'package:beltech/core/di/feature_flag_providers.dart';
import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/di/security_providers.dart';
import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/feature_flags/feature_flag.dart';
import 'package:beltech/core/security/biometric_relock_policy.dart';
import 'package:beltech/core/security/screen_capture_protection_service.dart';
import 'package:beltech/core/navigation/app_shell_helpers.dart';
import 'package:beltech/core/navigation/shell_providers.dart';
import 'package:beltech/core/navigation/widgets/app_tab_bar.dart';
import 'package:beltech/core/navigation/widgets/biometric_lock_overlay.dart';
import 'package:beltech/core/navigation/widgets/shell_body_switcher.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_motion.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/widgets/app_toast.dart';
import 'package:beltech/core/widgets/offline_banner.dart';
import 'package:beltech/features/assistant/presentation/assistant_screen.dart';
import 'package:beltech/features/calendar/presentation/calendar_screen.dart';
import 'package:beltech/features/expenses/presentation/expenses_screen.dart';
import 'package:beltech/features/home/presentation/home_screen.dart';
import 'package:beltech/features/profile/presentation/profile_screen.dart';
import 'package:beltech/core/sync/background_sync_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_shell_biometric.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  static const List<Widget> _screens = [
    HomeScreen(),
    ExpensesScreen(),
    CalendarScreen(),
    AssistantScreen(),
    ProfileScreen(),
  ];

  static const List<AppTabItem> _tabs = [
    AppTabItem(
      label: 'Home',
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
    ),
    AppTabItem(
      label: 'Finance',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet_rounded,
    ),
    AppTabItem(
      label: 'Calendar',
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today_rounded,
    ),
    AppTabItem(
      label: 'AI',
      icon: Icons.auto_awesome_outlined,
      selectedIcon: Icons.auto_awesome_rounded,
    ),
    AppTabItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  late BackgroundSyncCoordinator _backgroundSyncCoordinator;
  StreamSubscription<String>? _notificationTapSub;
  bool _biometricConfigured = false;
  bool _biometricRelockEnabled = true;
  bool _appLocked = false;
  bool _biometricUnlockInProgress = false;
  String? _biometricLockMessage;
  String? _pinError;
  DateTime? _lastPausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(
      ScreenCaptureProtectionService.syncForTab(
        ref.read(shellTabIndexProvider),
      ),
    );
    _backgroundSyncCoordinator = ref.read(backgroundSyncCoordinatorProvider);
    unawaited(_refreshFeatureFlags());
    unawaited(_startBackgroundSync());
    unawaited(_initializeBiometricLock());
    unawaited(cleanupNotificationReminders(ref));
    unawaited(_initNotificationDeepLink());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _backgroundSyncCoordinator.stop();
    _notificationTapSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _lastPausedAt = DateTime.now();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      unawaited(
        ScreenCaptureProtectionService.syncForTab(
          ref.read(shellTabIndexProvider),
        ),
      );
      unawaited(_refreshFeatureFlags());
      unawaited(_syncNow());
      unawaited(_materializeRecurringNow());
      unawaited(_runNotificationSweep());
      unawaited(cleanupNotificationReminders(ref));
      unawaited(_applyBiometricLockOnResume());
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(shellTabIndexProvider, (previous, next) {
      if (previous == next) {
        return;
      }
      unawaited(ScreenCaptureProtectionService.syncForTab(next));
    });

    final currentIndex = ref.watch(shellTabIndexProvider);
    final reduceMotion = AppMotion.reduceMotion(context);
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    final brightness = Theme.of(context).brightness;
    final mediaQuery = MediaQuery.of(context);
    final originalNavBottom = AppSpacing.navBottom(context);
    final textScale = mediaQuery.textScaler.scale(1);
    final tabBarHeight = 72.0 + ((textScale - 1) * 12).clamp(0.0, 10.0);
    final bodyBottomPadding = keyboardVisible
        ? mediaQuery.padding.bottom
        : originalNavBottom + tabBarHeight;

    return Container(
      color: AppColors.backgroundFor(brightness),
      child: Stack(
        children: [
          IgnorePointer(
            ignoring: _appLocked,
            child: MediaQuery(
              data: mediaQuery.copyWith(
                padding: mediaQuery.padding.copyWith(bottom: bodyBottomPadding),
              ),
              child: Scaffold(
                extendBody: true,
                backgroundColor: Colors.transparent,
                body: ShellBodySwitcher(
                  currentIndex: currentIndex,
                  reduceMotion: reduceMotion,
                  children: AppShell._screens,
                ),
                bottomNavigationBar: keyboardVisible
                    ? null
                    : Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.screenHorizontal,
                          0,
                          AppSpacing.screenHorizontal,
                          originalNavBottom,
                        ),
                        child: AppTabBar(
                          selectedIndex: currentIndex,
                          items: AppShell._tabs,
                          onTap: (index) {
                            ref.read(shellTabIndexProvider.notifier).state =
                                index;
                          },
                        ),
                      ),
              ),
            ),
          ),
          const Positioned(top: 0, left: 0, right: 0, child: OfflineBanner()),
          const AppToastOverlay(),
          if (_appLocked)
            BiometricLockOverlay(
              busy: _biometricUnlockInProgress,
              message: _biometricLockMessage,
              onUnlock: _unlockWithBiometrics,
              pinError: _pinError,
              onPinSubmit: _unlockWithPin,
            ),
        ],
      ),
    );
  }

  Future<void> _initNotificationDeepLink() async {
    final svc = ref.read(localNotificationServiceProvider);
    await svc.initialize();

    final launchRoute = await svc.getNotificationLaunchRoute();
    if (launchRoute != null && mounted) {
      final tab = DeepLinkRouter.tabForRoute(launchRoute);
      if (tab != null) {
        ref.read(shellTabIndexProvider.notifier).state = tab.index;
      }
    }

    _notificationTapSub = svc.notificationTapRoutes.listen((route) {
      if (!mounted) return;
      final tab = DeepLinkRouter.tabForRoute(route);
      if (tab != null) {
        ref.read(shellTabIndexProvider.notifier).state = tab.index;
      }
    });
  }

  Future<void> _startBackgroundSync() async =>
      _backgroundSyncCoordinator.start();
  Future<void> _materializeRecurringNow() async =>
      _backgroundSyncCoordinator.materializeNow();
  Future<void> _syncNow() async => _backgroundSyncCoordinator.syncNow();
  Future<void> _runNotificationSweep() async =>
      _backgroundSyncCoordinator.runNotificationSweep();
  Future<void> _refreshFeatureFlags() async {
    try {
      await ref.read(refreshFeatureFlagsUseCaseProvider).call();
      final snapshot = await ref.read(featureFlagStoreProvider).snapshot();
      final motionEnabled = snapshot[FeatureFlag.stretchMotion] ?? true;
      AppMotion.setStretchMotionEnabled(motionEnabled);
      AppHaptics.setEnabled(motionEnabled);
      _biometricRelockEnabled = snapshot[FeatureFlag.biometricRelock] ?? true;
      ref.invalidate(featureFlagSnapshotProvider);
    } catch (_) {
      return;
    }
  }

  Future<void> _refreshBiometricConfiguration({required bool lockNow}) async {
    final authRepository = ref.read(authRepositoryProvider);
    final enabled = await authRepository.isBiometricEnabled();
    final supported = await authRepository.isBiometricSupported();
    final configured = enabled && supported;
    if (!mounted) return;
    setState(() {
      _biometricConfigured = configured;
      if (!configured) {
        _appLocked = false;
        _biometricLockMessage = null;
        return;
      }
      if (lockNow) _appLocked = true;
    });
  }

  Future<void> _unlockWithBiometrics() async {
    if (_biometricUnlockInProgress || !_biometricConfigured) return;
    setState(() {
      _biometricUnlockInProgress = true;
      _biometricLockMessage = null;
      _pinError = null;
    });
    final authenticated = await ref.read(authRepositoryProvider).authenticate();
    if (!mounted) return;
    setState(() {
      _biometricUnlockInProgress = false;
      _appLocked = !authenticated;
      _biometricLockMessage = authenticated
          ? null
          : 'Authentication was not completed.';
      if (authenticated) _lastPausedAt = null;
    });
  }

  Future<void> _unlockWithPin(String pin) async {
    final store = ref.read(secureCredentialsStoreProvider);
    final hasher = ref.read(passwordHasherProvider);
    final hash = await store.readPasswordHash();
    if (hash == null) {
      if (!mounted) return;
      setState(() {
        _pinError = 'No PIN has been set. Use fingerprint instead.';
      });
      return;
    }
    if (!hasher.verify(pin, hash)) {
      if (!mounted) return;
      setState(() {
        _pinError = 'Incorrect PIN. Please try again.';
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _pinError = null;
      _appLocked = false;
      _biometricLockMessage = null;
      _lastPausedAt = null;
    });
  }
}
