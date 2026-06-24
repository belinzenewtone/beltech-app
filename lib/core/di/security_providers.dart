import 'package:beltech/core/security/password_hasher.dart';
import 'package:beltech/core/security/session_lock_settings_repository.dart';
import 'package:beltech/core/security/secure_credentials_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

final localAuthenticationProvider = Provider<LocalAuthentication>(
  (_) => LocalAuthentication(),
);

final passwordHasherProvider = Provider<PasswordHasher>(
  (_) => PasswordHasher(),
);

final secureCredentialsStoreProvider = Provider<SecureCredentialsStore>(
  (ref) => SecureCredentialsStore(ref.watch(flutterSecureStorageProvider)),
);

final sessionLockSettingsRepositoryProvider =
    Provider<SessionLockSettingsRepository>(
  (_) => SessionLockSettingsRepository(),
);
