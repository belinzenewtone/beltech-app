import 'package:beltech/features/auth/domain/entities/account_session.dart';

abstract class AccountRepository {
  Stream<AccountSession> watchSession();

  AccountSession currentSession();

  Future<void> signIn({
    required String email,
    required String password,
  });

  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  Future<void> signOut();
}
