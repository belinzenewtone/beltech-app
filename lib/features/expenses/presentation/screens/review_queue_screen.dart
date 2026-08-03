import 'package:beltech/core/di/expenses_providers.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/loading_indicator.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_review.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ReviewQueueScreen extends ConsumerStatefulWidget {
  const ReviewQueueScreen({super.key});

  @override
  ConsumerState<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends ConsumerState<ReviewQueueScreen> {
  _Confidence? _selectedConfidence;
  _SortOption _sortBy = _SortOption.dateNewest;
  Set<int> _selectedIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reviewQueueNotifierProvider.notifier).load();
    });
  }

  List<ExpenseReviewItem> _getFilteredAndSorted(List<ExpenseReviewItem> items) {
    final filtered = items.where((item) {
      if (_selectedConfidence != null) {
        final band = _confidenceBand(item.confidence);
        if (band != _selectedConfidence) return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) => switch (_sortBy) {
      _SortOption.dateNewest => b.occurredAt.compareTo(a.occurredAt),
      _SortOption.dateOldest => a.occurredAt.compareTo(b.occurredAt),
      _SortOption.amountHighest => b.amountKes.compareTo(a.amountKes),
      _SortOption.amountLowest => a.amountKes.compareTo(b.amountKes),
    });

    return filtered;
  }

  _Confidence _confidenceBand(double confidence) {
    if (confidence >= 0.8) return _Confidence.high;
    if (confidence >= 0.5) return _Confidence.medium;
    return _Confidence.low;
  }

  @override
  Widget build(BuildContext context) {
    final queueState = ref.watch(reviewQueueNotifierProvider);
    final notifier = ref.read(reviewQueueNotifierProvider.notifier);
    return SecondaryPageShell(
      title: 'Review Queue',
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              'Approve or reject pending import matches',
              style: AppTypography.bodySm(
                context,
              ).copyWith(color: AppColors.textSecondary),
            ),
          ),
          _buildFilterAndSortBar(context),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: queueState.when(
              loading: () => const Center(child: LoadingIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.danger,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Failed to load review queue',
                      style: AppTypography.cardTitle(
                        context,
                      ).copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      error.toString(),
                      style: AppTypography.bodySm(
                        context,
                      ).copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              data: (items) {
                final filtered = _getFilteredAndSorted(items);
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _selectedConfidence != null
                          ? 'No ${_selectedConfidence!.name} confidence items'
                          : 'Nothing to review',
                      style: AppTypography.bodyMd(
                        context,
                      ).copyWith(color: AppColors.textSecondary),
                    ),
                  );
                }
                return Stack(
                  children: [
                    ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.listGap),
                      itemBuilder: (_, index) {
                        final item = filtered[index];
                        final isSelected = _selectedIds.contains(item.id);
                        return _AnimatedReviewItemCard(
                          key: ValueKey(item.id),
                          item: item,
                          isSelected: isSelected,
                          confidenceBand: _confidenceBand(item.confidence),
                          onSelect: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedIds.add(item.id);
                                _isSelectionMode = true;
                              } else {
                                _selectedIds.remove(item.id);
                                if (_selectedIds.isEmpty) {
                                  _isSelectionMode = false;
                                }
                              }
                            });
                          },
                          onApprove: () => notifier.approve(item.id),
                          onReject: () => notifier.reject(item.id),
                        );
                      },
                    ),
                    if (_isSelectionMode)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _buildBulkActionBar(context, filtered, notifier),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSortBar(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: 'All',
            isSelected: _selectedConfidence == null,
            onSelected: () => setState(() => _selectedConfidence = null),
          ),
          const SizedBox(width: AppSpacing.sm),
          for (final c in _Confidence.values) ...[
            _buildFilterChip(
              label: c.label,
              isSelected: _selectedConfidence == c,
              onSelected: () => setState(() => _selectedConfidence = c),
            ),
            if (c != _Confidence.values.last) const SizedBox(width: AppSpacing.sm),
          ],
          const SizedBox(width: AppSpacing.lg),
          PopupMenuButton<_SortOption>(
            onSelected: (option) => setState(() => _sortBy = option),
            itemBuilder: (_) => _SortOption.values
                .map(
                  (opt) =>
                      PopupMenuItem(value: opt, child: Text(opt.label)),
                )
                .toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: AppRadius.smAll,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sort, size: 16),
                  const SizedBox(width: AppSpacing.xs),
                  Text('Sort', style: AppTypography.bodySm(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.accent.withValues(alpha: 0.1),
      side: BorderSide(color: isSelected ? AppColors.accent : AppColors.border),
    );
  }

  Widget _buildBulkActionBar(
    BuildContext context,
    List<ExpenseReviewItem> items,
    ReviewQueueNotifier notifier,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_selectedIds.length} selected',
                style: AppTypography.bodySm(context),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_selectedIds.length == items.length) {
                      _selectedIds.clear();
                      _isSelectionMode = false;
                    } else {
                      _selectedIds = items.map((i) => i.id).toSet();
                      _isSelectionMode = true;
                    }
                  });
                },
                child: Text(
                  _selectedIds.length == items.length ? 'Deselect' : 'Select All',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Reject All',
                  variant: AppButtonVariant.secondary,
                  onPressed: () async {
                    final toReject = items
                        .where((i) => _selectedIds.contains(i.id))
                        .toList();
                    for (final item in toReject) {
                      await notifier.reject(item.id);
                    }
                    setState(() {
                      _selectedIds.clear();
                      _isSelectionMode = false;
                    });
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'Approve All',
                  onPressed: () async {
                    final toApprove = items
                        .where((i) => _selectedIds.contains(i.id))
                        .toList();
                    for (final item in toApprove) {
                      await notifier.approve(item.id);
                    }
                    setState(() {
                      _selectedIds.clear();
                      _isSelectionMode = false;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _Confidence {
  high('High'),
  medium('Medium'),
  low('Low');

  const _Confidence(this.label);
  final String label;
}

enum _SortOption {
  dateNewest('Newest First'),
  dateOldest('Oldest First'),
  amountHighest('Highest Amount'),
  amountLowest('Lowest Amount');

  const _SortOption(this.label);
  final String label;
}

class _AnimatedReviewItemCard extends StatefulWidget {
  const _AnimatedReviewItemCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.confidenceBand,
    required this.onSelect,
    required this.onApprove,
    required this.onReject,
  });

  final ExpenseReviewItem item;
  final bool isSelected;
  final _Confidence confidenceBand;
  final ValueChanged<bool> onSelect;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  State<_AnimatedReviewItemCard> createState() =>
      _AnimatedReviewItemCardState();
}

class _AnimatedReviewItemCardState extends State<_AnimatedReviewItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.15, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: _ReviewItemCard(
          item: widget.item,
          isSelected: widget.isSelected,
          confidenceBand: widget.confidenceBand,
          onSelect: widget.onSelect,
          onApprove: widget.onApprove,
          onReject: widget.onReject,
        ),
      ),
    );
  }
}

class _ReviewItemCard extends StatelessWidget {
  const _ReviewItemCard({
    required this.item,
    required this.isSelected,
    required this.confidenceBand,
    required this.onSelect,
    required this.onApprove,
    required this.onReject,
  });

  final ExpenseReviewItem item;
  final bool isSelected;
  final _Confidence confidenceBand;
  final ValueChanged<bool> onSelect;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final confidenceColor = switch (confidenceBand) {
      _Confidence.high => AppColors.success,
      _Confidence.medium => AppColors.warning,
      _Confidence.low => AppColors.danger,
    };
    final dateFormat = DateFormat.MMMd().add_jm();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (v) => onSelect(v ?? false),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTypography.bodyMd(
                        context,
                      ).copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateFormat.format(item.occurredAt),
                      style: AppTypography.bodySm(
                        context,
                      ).copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.money(item.amountKes),
                    style: AppTypography.bodyMd(
                      context,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${confidenceBand.label} confidence',
                    style: AppTypography.bodySm(
                      context,
                    ).copyWith(color: confidenceColor),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            tone: AppCardTone.muted,
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category: ${item.category}',
                  style: AppTypography.bodySm(
                    context,
                  ).copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.rawMessage,
                  style: AppTypography.bodySm(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Reject',
                  variant: AppButtonVariant.secondary,
                  onPressed: onReject,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(label: 'Approve', onPressed: onApprove),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
