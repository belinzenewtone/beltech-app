import 'package:beltech/main.dart';
import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/auth/domain/entities/account_session.dart';
import 'package:beltech/features/auth/domain/repositories/account_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders bottom navigation tabs', (tester) async {
    SharedPreferences.setMockInitialValues(
      <String, Object>{
        'onboarding_done_v1': true,
        'revamp_bootstrap_v2_done': true,
      },
    );
    final fakeAccountRepository = _AuthenticatedAccountRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountRepositoryProvider.overrideWithValue(fakeAccountRepository),
        ],
        child: const PersonalManagementApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);
    expect(find.byIcon(Icons.task_alt_outlined), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
  });
}

class _AuthenticatedAccountRepository implements AccountRepository {
  static const AccountSession _session = AccountSession(
    isAuthenticated: true,
    userId: 'test-local-user',
    email: 'test@local.dev',
    displayName: 'Test User',
  );

  @override
  Stream<AccountSession> watchSession() async* {
    yield _session;
  }

  @override
  AccountSession currentSession() => _session;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}
}
