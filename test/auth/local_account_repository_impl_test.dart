import 'package:beltech/features/auth/data/repositories/local_account_repository_impl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('starts unauthenticated by default', () async {
    final repository = LocalAccountRepositoryImpl();
    final first = await repository.watchSession().first;
    expect(first.isAuthenticated, isFalse);
    expect(repository.currentSession().isAuthenticated, isFalse);
  });

  test('sign up authenticates local session', () async {
    final repository = LocalAccountRepositoryImpl();
    await repository.signUp(
      name: 'Jane Local',
      email: 'jane@local.dev',
      phone: '0700000000',
      password: 'password123',
    );
    final current = repository.currentSession();
    expect(current.isAuthenticated, isTrue);
    expect(current.email, 'jane@local.dev');
    expect(current.displayName, 'Jane Local');
  });

  test('session persists across repository instances', () async {
    final storage = const FlutterSecureStorage();
    final repoA = LocalAccountRepositoryImpl(storage: storage);
    await repoA.signIn(email: 'test@local.dev', password: 'test');

    final repoB = LocalAccountRepositoryImpl(storage: storage);
    final restored = await repoB.watchSession().first;
    expect(restored.isAuthenticated, isTrue);
    expect(restored.email, 'test@local.dev');
  });

  test('sign out clears persisted session', () async {
    final storage = const FlutterSecureStorage();
    final repoA = LocalAccountRepositoryImpl(storage: storage);
    await repoA.signIn(email: 'test@local.dev', password: 'test');
    await repoA.signOut();

    final repoB = LocalAccountRepositoryImpl(storage: storage);
    final restored = await repoB.watchSession().first;
    expect(restored.isAuthenticated, isFalse);
  });

  test('expired session is not restored', () async {
    final storage = const FlutterSecureStorage();

    final repoA = LocalAccountRepositoryImpl(storage: storage);
    await repoA.signIn(email: 'old@local.dev', password: 'test');

    final stored = await storage.read(key: 'local_session');
    expect(stored, isNotNull);

    await storage.write(
      key: 'local_session',
      value: stored!.replaceFirstMapped(
        RegExp(r'"signedInAt":\d+'),
        (m) =>
            '"signedInAt":${DateTime.now().subtract(const Duration(days: 31)).millisecondsSinceEpoch}',
      ),
    );

    final repoB = LocalAccountRepositoryImpl(storage: storage);
    final restored = await repoB.watchSession().first;
    expect(restored.isAuthenticated, isFalse);

    final remaining = await storage.read(key: 'local_session');
    expect(remaining, isNull);
  });
}
