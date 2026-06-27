import 'dart:convert';
import 'dart:typed_data';

import 'package:beltech/data/local/drift/assistant_profile_store.dart';
import 'package:beltech/features/profile/domain/entities/user_profile.dart';
import 'package:beltech/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._store);

  final AssistantProfileStore _store;

  @override
  Stream<UserProfile> watchProfile() {
    return _store.watchProfile().map(
      (profile) => UserProfile(
        name: profile.name,
        username: profile.username,
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
    required String username,
    required String email,
    required String phone,
  }) async {
    await _store.updateProfile(
      name: name,
      username: username,
      email: email,
      phone: phone,
    );
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
