import 'dart:convert';
import 'dart:typed_data';

import 'package:beltech/core/security/password_hasher.dart';
import 'package:beltech/core/security/secure_credentials_store.dart';
import 'package:beltech/data/local/drift/assistant_profile_store.dart';
import 'package:beltech/features/profile/domain/entities/user_profile.dart';
import 'package:beltech/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(
    this._store,
    this._credentialsStore,
    this._passwordHasher,
  );

  final AssistantProfileStore _store;
  final SecureCredentialsStore _credentialsStore;
  final PasswordHasher _passwordHasher;

  bool _passwordBootstrapped = false;

  @override
  Stream<UserProfile> watchProfile() {
    return _store.watchProfile().map(
          (profile) => UserProfile(
            name: profile.name,
            email: profile.email,
            phone: profile.phone,
            memberSinceLabel: profile.memberSinceLabel,
            verified: profile.verified,
            avatarUrl: profile.avatarUrl,
          ),
        );
  }

  @override
  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    await _store.updateProfile(name: name, email: email, phone: phone);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _ensurePasswordBootstrap();
    final currentHash = _passwordHasher.hash(currentPassword);
    final savedHash = await _credentialsStore.readPasswordHash();
    if (savedHash != null && savedHash != currentHash) {
      throw Exception('Current password is incorrect.');
    }
    final newHash = _passwordHasher.hash(newPassword);
    await _credentialsStore.writePasswordHash(newHash);
  }

  @override
  Future<void> updateAvatar({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final ext = _normalizeExtension(fileExtension);
    final encoded = base64Encode(bytes);
    final dataUri = 'data:image/$ext;base64,$encoded';
    await _store.updateAvatarUrl(dataUri);
  }

  Future<void> _ensurePasswordBootstrap() async {
    if (_passwordBootstrapped) {
      return;
    }
    final existing = await _credentialsStore.readPasswordHash();
    if (existing == null) {
      final defaultHash = _passwordHasher.hash('123456');
      await _credentialsStore.writePasswordHash(defaultHash);
    }
    _passwordBootstrapped = true;
  }

  String _normalizeExtension(String extension) {
    final value = extension.toLowerCase().replaceAll('.', '');
    if (value == 'jpg') {
      return 'jpeg';
    }
    return switch (value) {
      'jpeg' || 'png' || 'webp' => value,
      _ => 'jpeg',
    };
  }
}
