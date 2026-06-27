import 'package:beltech/data/local/drift/assistant_profile_store.dart';
import 'package:beltech/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AssistantProfileStore store;
  late ProfileRepositoryImpl repository;

  setUp(() {
    store = AssistantProfileStore();
    repository = ProfileRepositoryImpl(store);
  });

  tearDown(() async {
    await store.dispose();
  });

  test('updateProfile writes and publishes updated profile', () async {
    final nextProfile = repository.watchProfile().skip(1).first;
    await repository.updateProfile(
      name: 'New Name',
      username: 'newname',
      email: 'new@example.com',
      phone: '0712345678',
    );

    final updated = await nextProfile.timeout(const Duration(seconds: 2));
    expect(updated.name, 'New Name');
    expect(updated.username, 'newname');
    expect(updated.email, 'new@example.com');
    expect(updated.phone, '0712345678');
  });
}
