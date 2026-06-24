import 'dart:async';

import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/auth/domain/entities/account_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final accountSessionProvider = StreamProvider<AccountSession>(
  (ref) => ref.watch(accountRepositoryProvider).watchSession(),
);

class AccountAuthController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(accountRepositoryProvider).signIn(
            email: email,
            password: password,
          );
    });
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(accountRepositoryProvider).signUp(
            name: name,
            email: email,
            phone: phone,
            password: password,
          );
      // Immediately seed the profile store with the sign-up data so the user
      // never has to re-enter their name/phone/email on the profile screen.
      // For Supabase mode this is an early upsert that matches what _loadProfile
      // will do on first visit; for local (Drift) mode this is the only path
      // that populates the profile, since the local account repo only keeps
      // data in-memory and the Drift profile store is otherwise unseeded.
      try {
        await ref.read(profileRepositoryProvider).updateProfile(
              name: name.trim(),
              email: email.trim(),
              phone: phone.trim(),
            );
      } catch (_) {
        // Non-fatal — profile will fall back to lazy creation on first visit.
      }
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(accountRepositoryProvider).signOut();
    });
  }
}

final accountAuthControllerProvider =
    AutoDisposeAsyncNotifierProvider<AccountAuthController, void>(
  AccountAuthController.new,
);
