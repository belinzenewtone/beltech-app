import 'dart:async';
import 'dart:convert';

import 'package:beltech/features/auth/domain/entities/account_session.dart';
import 'package:beltech/features/auth/domain/repositories/account_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalAccountRepositoryImpl implements AccountRepository {
  LocalAccountRepositoryImpl({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'local_session';
  static const _sessionDuration = Duration(days: 30);

  final FlutterSecureStorage _storage;
  final StreamController<AccountSession> _sessionController =
      StreamController<AccountSession>.broadcast();
  AccountSession _session = AccountSession.unauthenticated;

  Future<AccountSession?> _restoreSession() async {
    final json = await _storage.read(key: _sessionKey);
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final signedInAt = DateTime.fromMillisecondsSinceEpoch(
        map['signedInAt'] as int,
      );
      if (DateTime.now().difference(signedInAt) > _sessionDuration) {
        await _storage.delete(key: _sessionKey);
        return null;
      }
      return AccountSession(
        isAuthenticated: true,
        userId: map['userId'] as String?,
        email: map['email'] as String?,
        displayName: map['displayName'] as String?,
      );
    } catch (_) {
      await _storage.delete(key: _sessionKey);
      return null;
    }
  }

  Future<void> _persistSession(Map<String, dynamic> data) async {
    await _storage.write(key: _sessionKey, value: jsonEncode(data));
  }

  @override
  Stream<AccountSession> watchSession() async* {
    final restored = await _restoreSession();
    _session = restored ?? _session;
    yield _session;
    yield* _sessionController.stream;
  }

  @override
  AccountSession currentSession() {
    return _session;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    final fallbackName = email.trim().isEmpty ? 'Local User' : email.trim();
    _session = AccountSession(
      isAuthenticated: true,
      userId: 'local-user',
      email: email.trim().isEmpty ? 'local@device' : email.trim(),
      displayName: fallbackName,
    );
    await _persistSession({
      'userId': _session.userId,
      'email': _session.email,
      'displayName': _session.displayName,
      'signedInAt': DateTime.now().millisecondsSinceEpoch,
    });
    _sessionController.add(_session);
  }

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _session = AccountSession(
      isAuthenticated: true,
      userId: 'local-user',
      email: email.trim().isEmpty ? 'local@device' : email.trim(),
      displayName: name.trim().isEmpty ? 'Local User' : name.trim(),
    );
    await _persistSession({
      'userId': _session.userId,
      'email': _session.email,
      'displayName': _session.displayName,
      'signedInAt': DateTime.now().millisecondsSinceEpoch,
    });
    _sessionController.add(_session);
  }

  @override
  Future<void> signOut() async {
    _session = AccountSession.unauthenticated;
    await _storage.delete(key: _sessionKey);
    _sessionController.add(_session);
  }
}
