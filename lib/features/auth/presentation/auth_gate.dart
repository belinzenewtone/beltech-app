import 'package:beltech/core/di/bootstrap_providers.dart';
import 'package:beltech/core/navigation/app_shell.dart';
import 'package:beltech/features/auth/presentation/providers/account_providers.dart';
import 'package:beltech/features/auth/presentation/widgets/auth_loading_screen.dart';
import 'package:beltech/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _checkingOnboarding = true;
  bool _onboardingDone = false;

  @override
  void initState() {
    super.initState();
    _bootstrapAndLoadOnboarding();
  }

  Future<void> _bootstrapAndLoadOnboarding() async {
    await ref.read(revampBootstrapServiceProvider).runIfNeeded();
    final done = await hasSeenOnboarding();
    if (!mounted) {
      return;
    }
    setState(() {
      _onboardingDone = done;
      _checkingOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingOnboarding) {
      return const AuthLoadingScreen();
    }
    if (!_onboardingDone) {
      return OnboardingScreen(
        onDone: () => setState(() => _onboardingDone = true),
      );
    }
    final sessionState = ref.watch(accountSessionProvider);
    return sessionState.when(
      data: (session) {
        if (!session.isAuthenticated) {
          // Silently sign in to the local workspace on first launch.
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await ref
                .read(accountAuthControllerProvider.notifier)
                .signIn(email: '', password: '');
          });
          return const AuthLoadingScreen();
        }
        return const AppShell();
      },
      loading: () => const AuthLoadingScreen(),
      error: (_, __) => const AuthLoadingScreen(),
    );
  }
}
