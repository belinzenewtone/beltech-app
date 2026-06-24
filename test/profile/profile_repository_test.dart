import 'package:beltech/core/security/password_hasher.dart';
import 'package:beltech/core/security/secure_credentials_store.dart';
import 'package:beltech/data/local/drift/assistant_profile_store.dart';
import 'package:beltech/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureCredentialsStore extends Mock
    implements SecureCredentialsStore {}

void main() {
  late AssistantProfileStore store;
  late MockSecureCredentialsStore credentialsStore;
  late PasswordHasher hasher;
  late ProfileRepositoryImpl repository;

  setUp(() {
    store = AssistantProfileStore();
    credentialsStore = MockSecureCredentialsStore();
    hasher = PasswordHasher();
    repository = ProfileRepositoryImpl(store, credentialsStore, hasher);
  });

  tearDown(() async {
    await store.dispose();
  });

  test('updateProfile writes and publishes updated profile', () async {
    when(() => credentialsStore.readPasswordHash())
        .thenAnswer((_) async => null);
    when(() => credentialsStore.writePasswordHash(any()))
        .thenAnswer((_) async {});

    final nextProfile = repository.watchProfile().skip(1).first;
    await repository.updateProfile(
      name: 'New Name',
      email: 'new@example.com',
      phone: '0712345678',
    );

    final updated = await nextProfile.timeout(const Duration(seconds: 2));
    expect(updated.name, 'New Name');
    expect(updated.email, 'new@example.com');
    expect(updated.phone, '0712345678');
  });

  test('changePassword writes new hashed password when current is valid',
      () async {
    final currentHash = hasher.hash('current-pass');
    final newHash = hasher.hash('new-pass-123');
    when(() => credentialsStore.readPasswordHash())
        .thenAnswer((_) async => currentHash);
    when(() => credentialsStore.writePasswordHash(any()))
        .thenAnswer((_) async {});

    await repository.changePassword(
      currentPassword: 'current-pass',
      newPassword: 'new-pass-123',
    );

    verify(() => credentialsStore.writePasswordHash(newHash)).called(1);
  });

  test('changePassword throws when current password is incorrect', () async {
    when(() => credentialsStore.readPasswordHash())
        .thenAnswer((_) async => hasher.hash('valid-old'));
    when(() => credentialsStore.writePasswordHash(any()))
        .thenAnswer((_) async {});

    expect(
      () => repository.changePassword(
        currentPassword: 'wrong-old',
        newPassword: 'new-pass-123',
      ),
      throwsException,
    );
  });
}
