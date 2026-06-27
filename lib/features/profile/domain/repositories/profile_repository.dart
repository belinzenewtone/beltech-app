import 'package:beltech/features/profile/domain/entities/user_profile.dart';
import 'dart:typed_data';

abstract class ProfileRepository {
  Stream<UserProfile> watchProfile();

  Future<void> updateProfile({
    required String name,
    required String username,
    required String email,
    required String phone,
  });

  Future<void> updateAvatar({
    required Uint8List bytes,
    required String fileExtension,
  });
}
