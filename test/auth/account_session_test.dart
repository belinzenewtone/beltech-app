import 'dart:async';

import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/auth/domain/entities/account_session.dart';
import 'package:beltech/features/auth/domain/repositories/account_repository.dart';
import 'package:beltech/features/auth/presentation/providers/account_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accountSessionProvider reflects repository session stream', () async {
    final fake = _FakeAccountRepository();
    final container = ProviderContainer(
      overrides: [accountRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final first = await container.read(accountSessionProvider.future);
    expect(first.isAuthenticated, isFalse);

    await fake.signIn(email: 'user@mail.com', password: '123456');
    await Future<void>.delayed(Duration.zero);
    final second = container.read(accountSessionProvider).valueOrNull;
    expect(second?.isAuthenticated, isTrue);
    expect(second?.email, 'user@mail.com');
  });

  test('account auth controller calls repository signOut', () async {
    final fake = _FakeAccountRepository()
      ..seedAuthenticated(const AccountSession(
        isAuthenticated: true,
        userId: 'uid-1',
        email: 'auth@mail.com',
        displayName: 'Auth User',
      ));
    final container = ProviderContainer(
      overrides: [accountRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    await container.read(accountAuthControllerProvider.notifier).signOut();
    expect(fake.currentSession().isAuthenticated, isFalse);
  });
}

class _FakeAccountRepository implements AccountRepository {
  final StreamController<AccountSession> _controller =
      StreamController<AccountSession>.broadcast();
  AccountSession _session = AccountSession.unauthenticated;

  _FakeAccountRepository() {
    _controller.add(_session);
  }

  @override
  Stream<AccountSession> watchSession() {
    return Stream<AccountSession>.multi((controller) {
      controller.add(_session);
      final sub = _controller.stream.listen(controller.add);
      controller.onCancel = sub.cancel;
    });
  }

  @override
  AccountSession currentSession() => _session;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _session = AccountSession(
      isAuthenticated: true,
      userId: 'uid-1',
      email: email,
      displayName: email.split('@').first,
    );
    _controller.add(_session);
  }

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _session = AccountSession(
      isAuthenticated: true,
      userId: 'uid-2',
      email: email,
      displayName: name,
    );
    _controller.add(_session);
  }

  @override
  Future<void> signOut() async {
    _session = AccountSession.unauthenticated;
    _controller.add(_session);
  }

  void seedAuthenticated(AccountSession session) {
    _session = session;
    _controller.add(_session);
  }
}
