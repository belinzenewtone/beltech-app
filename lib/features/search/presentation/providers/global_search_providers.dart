import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/search/domain/entities/global_search_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final globalSearchQueryProvider = StateProvider<String>((_) => '');

/// Active kind filter. Empty set = show all kinds.
final globalSearchKindFilterProvider =
    StateProvider<Set<GlobalSearchKind>>((_) => const {});

/// Raw results from the repository (unfiltered).
final globalSearchResultsProvider =
    FutureProvider<List<GlobalSearchResult>>((ref) {
  final query = ref.watch(globalSearchQueryProvider);
  return ref.watch(globalSearchRepositoryProvider).search(query);
});

/// Results filtered by the active kind selection.
final filteredSearchResultsProvider =
    Provider<AsyncValue<List<GlobalSearchResult>>>((ref) {
  final resultsAsync = ref.watch(globalSearchResultsProvider);
  final activeFilter = ref.watch(globalSearchKindFilterProvider);
  return resultsAsync.whenData((results) {
    if (activeFilter.isEmpty) return results;
    return results.where((r) => activeFilter.contains(r.kind)).toList();
  });
});

class GlobalSearchDeepLinkTarget {
  const GlobalSearchDeepLinkTarget({
    required this.kind,
    required this.recordId,
    required this.recordDate,
  });

  final GlobalSearchKind kind;
  final int? recordId;
  final DateTime? recordDate;
}

final globalSearchDeepLinkTargetProvider =
    StateProvider<GlobalSearchDeepLinkTarget?>((_) => null);
