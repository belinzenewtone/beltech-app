import 'package:beltech/features/search/domain/entities/global_search_result.dart';

abstract class GlobalSearchRepository {
  Future<List<GlobalSearchResult>> search(String query);
}
