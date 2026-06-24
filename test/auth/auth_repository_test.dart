import 'package:beltech/core/security/secure_credentials_store.dart';
import 'package:beltech/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

class MockSecureCredentialsStore extends Mock
    implements SecureCredentialsStore {}

void main() {
  late MockLocalAuthentication localAuth;
  late MockSecureCredentialsStore credentialsStore;
  late AuthRepositoryImpl repository;

  setUp(() {
    localAuth = MockLocalAuthentication();
    credentialsStore = MockSecureCredentialsStore();
    repository = AuthRepositoryImpl(localAuth, credentialsStore);
  });

  test('isBiometricSupported returns true when device supports biometrics',
      () async {
    when(() => localAuth.canCheckBiometrics).thenAnswer((_) async => true);
    when(() => localAuth.isDeviceSupported()).thenAnswer((_) async => true);

    final supported = await repository.isBiometricSupported();

    expect(supported, isTrue);
  });

  test('setBiometricEnabled persists preference', () async {
    when(() => credentialsStore.writeBiometricEnabled(any()))
        .thenAnswer((_) async {});

    await repository.setBiometricEnabled(true);

    verify(() => credentialsStore.writeBiometricEnabled(true)).called(1);
  });

  test('authenticate returns false when biometric lock is disabled', () async {
    when(() => credentialsStore.readBiometricEnabled())
        .thenAnswer((_) async => false);
    when(() => localAuth.canCheckBiometrics).thenAnswer((_) async => true);
    when(() => localAuth.isDeviceSupported()).thenAnswer((_) async => true);

    final authenticated = await repository.authenticate();

    expect(authenticated, isFalse);
    verifyNever(
      () => localAuth.authenticate(
        localizedReason: 'Authenticate to unlock secure actions',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      ),
    );
  });

  test('authenticate calls local auth when enabled and supported', () async {
    when(() => credentialsStore.readBiometricEnabled())
        .thenAnswer((_) async => true);
    when(() => localAuth.canCheckBiometrics).thenAnswer((_) async => true);
    when(() => localAuth.isDeviceSupported()).thenAnswer((_) async => true);
    when(
      () => localAuth.authenticate(
        localizedReason: 'Authenticate to unlock secure actions',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      ),
    ).thenAnswer((_) async => true);

    final authenticated = await repository.authenticate();

    expect(authenticated, isTrue);
  });
}
