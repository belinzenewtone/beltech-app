import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_capsule.dart';
import 'package:beltech/core/widgets/error_message.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/core/widgets/loading_indicator.dart';
import 'package:beltech/features/search/domain/entities/global_search_result.dart';
import 'package:beltech/features/search/presentation/widgets/global_search_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GlobalSearchFilterBar extends StatelessWidget {
  const GlobalSearchFilterBar({
    super.key,
    required this.activeFilter,
    required this.onSelectAll,
    required this.onToggleKind,
  });

  final Set<GlobalSearchKind> activeFilter;
  final VoidCallback onSelectAll;
  final ValueChanged<GlobalSearchKind> onToggleKind;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            isActive: activeFilter.isEmpty,
            color: AppColors.accent,
            onTap: onSelectAll,
          ),
          const SizedBox(width: 6),
          for (final kind in GlobalSearchKind.values) ...[
            _FilterChip(
              label: globalSearchKindLabel(kind),
              isActive: activeFilter.contains(kind),
              color: globalSearchKindColor(kind),
              onTap: () => onToggleKind(kind),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class GlobalSearchResultsView extends StatelessWidget {
  const GlobalSearchResultsView({
    super.key,
    required this.query,
    required this.resultsState,
    required this.recentSearches,
    required this.onRecentTap,
    required this.onClearRecent,
    required this.onShortcutTap,
    required this.onRetry,
    required this.onResultTap,
  });

  final String query;
  final AsyncValue<List<GlobalSearchResult>> resultsState;
  final List<String> recentSearches;
  final ValueChanged<String> onRecentTap;
  final VoidCallback onClearRecent;
  final ValueChanged<String> onShortcutTap;
  final VoidCallback onRetry;
  final ValueChanged<GlobalSearchResult> onResultTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return resultsState.when(
      data: (results) {
        if (query.trim().isEmpty) {
          return GlobalSearchEmptyState(
            recentSearches: recentSearches,
            onRecentTap: onRecentTap,
            onClearRecent: onClearRecent,
            onShortcutTap: onShortcutTap,
          );
        }
        if (results.isEmpty) {
          return ListView(
            children: [
              GlassCard(
                tone: GlassCardTone.muted,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No results for "$query"', style: textTheme.bodyLarge),
                    const SizedBox(height: 6),
                    Text(
                      'Try a different keyword or filter.',
                      style: AppTypography.bodySm(context),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) => GlobalSearchResultTile(
            result: results[index],
            onTap: () => onResultTap(results[index]),
          ),
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (_, __) => ErrorMessage(
        label: 'Search failed',
        onRetry: onRetry,
      ),
    );
  }
}

class GlobalSearchResultTile extends StatelessWidget {
  const GlobalSearchResultTile({
    super.key,
    required this.result,
    required this.onTap,
  });

  final GlobalSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kindColor = globalSearchKindColor(result.kind);
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: kindColor.withValues(alpha: 0.18),
              child: Icon(
                globalSearchKindIcon(result.kind),
                color: kindColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.primaryText,
                    style: textTheme.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    result.secondaryText,
                    style: textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (result.trailingText.isNotEmpty)
                  Text(
                    result.trailingText,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                AppCapsule(
                  label: globalSearchKindLabel(result.kind),
                  color: kindColor,
                  variant: AppCapsuleVariant.subtle,
                  size: AppCapsuleSize.sm,
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}

String globalSearchKindLabel(GlobalSearchKind kind) {
  return switch (kind) {
    GlobalSearchKind.expense => 'Expense',
    GlobalSearchKind.income => 'Income',
    GlobalSearchKind.task => 'Task',
    GlobalSearchKind.event => 'Event',
    GlobalSearchKind.budget => 'Budget',
    GlobalSearchKind.recurring => 'Recurring',
  };
}

Color globalSearchKindColor(GlobalSearchKind kind) {
  return switch (kind) {
    GlobalSearchKind.expense => AppColors.danger,
    GlobalSearchKind.income => AppColors.success,
    GlobalSearchKind.task => AppColors.teal,
    GlobalSearchKind.event => AppColors.violet,
    GlobalSearchKind.budget => AppColors.warning,
    GlobalSearchKind.recurring => AppColors.accent,
  };
}

IconData globalSearchKindIcon(GlobalSearchKind kind) {
  return switch (kind) {
    GlobalSearchKind.expense => Icons.receipt_long_outlined,
    GlobalSearchKind.income => Icons.account_balance_wallet_outlined,
    GlobalSearchKind.task => Icons.check_circle_outline,
    GlobalSearchKind.event => Icons.calendar_month_outlined,
    GlobalSearchKind.budget => Icons.savings_outlined,
    GlobalSearchKind.recurring => Icons.autorenew,
  };
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCapsule(
      label: label,
      color: isActive ? color : AppColors.textMuted,
      variant: isActive ? AppCapsuleVariant.solid : AppCapsuleVariant.subtle,
      size: AppCapsuleSize.md,
      onTap: onTap,
    );
  }
}
