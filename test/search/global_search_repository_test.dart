import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/search/data/repositories/global_search_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDriftStore store;
  late GlobalSearchRepositoryImpl repository;

  setUp(() {
    store = AppDriftStore();
    repository = GlobalSearchRepositoryImpl(store);
  });

  tearDown(() async {
    await store.dispose();
  });

  test('search returns task and expense matches', () async {
    final results = await repository.search('hotel');
    expect(results, isNotEmpty);
    expect(
        results.any((item) => item.primaryText.toLowerCase().contains('hotel')),
        isTrue);
  });
}
