import 'dart:async';

import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/navigation/shell_providers.dart';
import 'package:beltech/core/widgets/app_search_bar.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/search/domain/entities/global_search_result.dart';
import 'package:beltech/features/search/presentation/providers/global_search_providers.dart';
import 'package:beltech/features/search/presentation/widgets/global_search_results.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _controller = TextEditingController();
  List<String> _recentSearches = [];
  Timer? _debounce;

  static const _kDebounceMs = 300;

  static const _kRecentKey = 'global_search_recent';
  static const _kMaxRecent = 8;

  @override
  void initState() {
    super.initState();
    Future<void>(() {
      if (!mounted) {
        return;
      }
      _controller.clear();
      ref.read(globalSearchQueryProvider.notifier).state = '';
      ref.read(globalSearchKindFilterProvider.notifier).state = const {};
    });
    _loadRecent();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kRecentKey) ?? [];
    if (mounted) setState(() => _recentSearches = list);
  }

  Future<void> _saveRecent(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final updated = [
      q,
      ..._recentSearches.where((s) => s != q),
    ].take(_kMaxRecent).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kRecentKey, updated);
    if (mounted) setState(() => _recentSearches = updated);
  }

  Future<void> _clearRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRecentKey);
    if (mounted) setState(() => _recentSearches = []);
  }

  void _applyQuery(String q) {
    _controller.text = q;
    _controller.selection = TextSelection.collapsed(offset: q.length);
    ref.read(globalSearchQueryProvider.notifier).state = q;
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(globalSearchQueryProvider);
    final activeFilter = ref.watch(globalSearchKindFilterProvider);
    final resultsState = ref.watch(filteredSearchResultsProvider);

    return SecondaryPageShell(
      title: 'Global Search',

      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search bar ──────────────────────────────────────────────────────
          AppSearchBar(
            controller: _controller,
            hint: 'Search transactions, tasks, events...',
            onChanged: (value) {
              _debounce?.cancel();
              _debounce = Timer(
                const Duration(milliseconds: _kDebounceMs),
                () =>
                    ref.read(globalSearchQueryProvider.notifier).state = value,
              );
            },
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) _saveRecent(value);
            },
          ),
          const SizedBox(height: 10),
          GlobalSearchFilterBar(
            activeFilter: activeFilter,
            onSelectAll: () =>
                ref.read(globalSearchKindFilterProvider.notifier).state =
                    const {},
            onToggleKind: (kind) {
              final current = Set<GlobalSearchKind>.from(
                ref.read(globalSearchKindFilterProvider),
              );
              if (current.contains(kind)) {
                current.remove(kind);
              } else {
                current.add(kind);
              }
              ref.read(globalSearchKindFilterProvider.notifier).state = current;
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GlobalSearchResultsView(
              query: query,
              resultsState: resultsState,
              recentSearches: _recentSearches,
              onRecentTap: _applyQuery,
              onClearRecent: _clearRecent,
              onShortcutTap: _applyQuery,
              onRetry: () => ref.invalidate(globalSearchResultsProvider),
              onResultTap: (result) => _navigateTo(context, ref, result),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(
    BuildContext context,
    WidgetRef ref,
    GlobalSearchResult result,
  ) {
    final currentQuery = ref.read(globalSearchQueryProvider).trim();
    if (currentQuery.isNotEmpty) _saveRecent(currentQuery);
    AppHaptics.lightImpact();

    ref
        .read(globalSearchDeepLinkTargetProvider.notifier)
        .state = GlobalSearchDeepLinkTarget(
      kind: result.kind,
      recordId: result.recordId,
      recordDate: result.recordDate,
    );

    switch (result.kind) {
      case GlobalSearchKind.expense:
        ref.read(shellTabIndexProvider.notifier).state = ShellTab.finance.index;
        context.pop();
        return;
      case GlobalSearchKind.income:
        context.pushNamed('income');
        return;
      case GlobalSearchKind.task:
        context.pop();
        context.pushNamed('tasks');
        return;
      case GlobalSearchKind.event:
        ref.read(shellTabIndexProvider.notifier).state =
            ShellTab.calendar.index;
        context.pop();
        return;
      case GlobalSearchKind.budget:
        context.pushNamed('budget');
        return;
      case GlobalSearchKind.recurring:
        context.pushNamed('recurring');
        return;
    }
  }
}
