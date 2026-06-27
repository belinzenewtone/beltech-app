import 'dart:async';
import 'dart:typed_data';

import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/profile/domain/entities/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileProvider = StreamProvider<UserProfile>(
  (ref) => ref.watch(profileRepositoryProvider).watchProfile(),
);

class ProfileWriteController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> updateProfile({
    required String name,
    required String username,
    required String email,
    required String phone,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(profileRepositoryProvider).updateProfile(
        name: name,
        username: username,
        email: email,
        phone: phone,
      );
    });
  }

  Future<void> updateAvatar({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(profileRepositoryProvider)
          .updateAvatar(bytes: bytes, fileExtension: fileExtension);
    });
  }
}

final profileWriteControllerProvider =
    AsyncNotifierProvider<ProfileWriteController, void>(
      ProfileWriteController.new,
    );
