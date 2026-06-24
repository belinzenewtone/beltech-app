import 'package:beltech/core/di/expenses_providers.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuarantineQueueScreen extends ConsumerStatefulWidget {
  const QuarantineQueueScreen({super.key});

  @override
  ConsumerState<QuarantineQueueScreen> createState() => _QuarantineQueueScreenState();
}

class _QuarantineQueueScreenState extends ConsumerState<QuarantineQueueScreen> {
  _Confidence? _selectedConfidence;
  _SortOption _sortBy = _SortOption.dateNewest;

  List<_PresentationQuarantineItem> _getFilteredAndSortedItems(
    List<_PresentationQuarantineItem> items,
  ) {
    final filtered = items.where((item) {
      if (_selectedConfidence != null && item.confidence != _selectedConfidence) {
        return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      return switch (_sortBy) {
        _SortOption.dateNewest => b.date.compareTo(a.date),
        _SortOption.dateOldest => a.date.compareTo(b.date),
        _SortOption.amountHighest => b.amount.compareTo(a.amount),
        _SortOption.amountLowest => a.amount.compareTo(b.amount),
        _SortOption.confidenceLowest => a.confidence.index.compareTo(b.confidence.index),
      };
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final quarantineState = ref.watch(quarantineQueueNotifierProvider);
    final notifier = ref.read(quarantineQueueNotifierProvider.notifier);
    return SecondaryPageShell(
      title: 'Review Queue',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Low-confidence SMS imports',
                  style: AppTypography.sectionTitle(context),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review and confirm transactions before they\'re added to your account',
                  style: AppTypography.bodySm(context)
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          _buildFilterAndSortBar(context),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: quarantineState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.danger,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Failed to load transactions',
                      style: AppTypography.cardTitle(context)
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      error.toString(),
                      style: AppTypography.bodySm(context)
                          .copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              data: (items) {
                final presentationItems = items.map(_toPresentationItem).toList();
                final filteredItems = _getFilteredAndSortedItems(presentationItems);

                return filteredItems.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.separated(
                        itemCount: filteredItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.listGap),
                        itemBuilder: (_, index) {
                          final item = filteredItems[index];
                          return _AnimatedQuarantineItemCard(
                            key: ValueKey(item.id),
                            item: item,
                            onApprove: () => _handleApprove(item, notifier),
                            onReject: () => _handleReject(item, notifier),
                            onEdit: () => _handleEdit(item, notifier),
                          );
                        },
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  _PresentationQuarantineItem _toPresentationItem(QuarantineItem item) {
    final confidence = switch (item.analysis.overallScore) {
      >= 0.8 => _Confidence.high,
      >= 0.5 => _Confidence.medium,
      _ => _Confidence.low,
    };

    return _PresentationQuarantineItem(
      id: item.id,
      title: item.candidate.title,
      amount: item.candidate.amountKes,
      date: item.candidate.occurredAt,
      confidence: confidence,
      rawMessage: item.candidate.rawMessage,
      domainItem: item,
    );
  }

  Future<void> _handleApprove(
    _PresentationQuarantineItem item,
    QuarantineQueueNotifier notifier,
  ) async {
    await notifier.approve(item.domainItem);
  }

  Future<void> _handleReject(
    _PresentationQuarantineItem item,
    QuarantineQueueNotifier notifier,
  ) async {
    await notifier.reject(item.domainItem);
  }

  Future<void> _handleEdit(
    _PresentationQuarantineItem item,
    QuarantineQueueNotifier notifier,
  ) async {
    // TODO: Implement edit dialog/sheet
    // For now, just call approve with original values
    await notifier.approveWithEdits(
      item.domainItem,
      item.title,
      item.amount,
      item.domainItem.candidate.category,
    );
  }

  Widget _buildFilterAndSortBar(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: 'All Confidence',
            isSelected: _selectedConfidence == null,
            onSelected: () {
              setState(() {
                _selectedConfidence = null;
              });
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip(
            label: 'Low',
            isSelected: _selectedConfidence == _Confidence.low,
            onSelected: () {
              setState(() {
                _selectedConfidence = _Confidence.low;
              });
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip(
            label: 'Medium',
            isSelected: _selectedConfidence == _Confidence.medium,
            onSelected: () {
              setState(() {
                _selectedConfidence = _Confidence.medium;
              });
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip(
            label: 'High',
            isSelected: _selectedConfidence == _Confidence.high,
            onSelected: () {
              setState(() {
                _selectedConfidence = _Confidence.high;
              });
            },
          ),
          const SizedBox(width: AppSpacing.lg),
          PopupMenuButton<_SortOption>(
            onSelected: (option) {
              setState(() {
                _sortBy = option;
              });
            },
            itemBuilder: (_) => _SortOption.values
                .map((option) => PopupMenuItem(
                      value: option,
                      child: Text(option.label),
                    ))
                .toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: AppRadius.smAll,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sort, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Sort',
                    style: AppTypography.bodySm(context),
                  ),
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
      onSelected: (selected) => onSelected(),
      selectedColor: AppColors.accent.withValues(alpha: 0.1),
      side: BorderSide(
        color: isSelected ? AppColors.accent : AppColors.border,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No transactions to review',
            style: AppTypography.cardTitle(context)
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedConfidence != null
                ? 'No ${_selectedConfidence!.name} confidence transactions'
                : 'All transactions have been reviewed',
            style: AppTypography.bodySm(context)
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

enum _Confidence { high, medium, low }

class _PresentationQuarantineItem {
  const _PresentationQuarantineItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.confidence,
    required this.rawMessage,
    required this.domainItem,
  });

  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final _Confidence confidence;
  final String rawMessage;
  final QuarantineItem domainItem;
}

enum _SortOption {
  dateNewest('Newest First'),
  dateOldest('Oldest First'),
  amountHighest('Highest Amount'),
  amountLowest('Lowest Amount'),
  confidenceLowest('Lowest Confidence');

  const _SortOption(this.label);
  final String label;
}

class _AnimatedQuarantineItemCard extends StatefulWidget {
  const _AnimatedQuarantineItemCard({
    super.key,
    required this.item,
    required this.onApprove,
    required this.onReject,
    required this.onEdit,
  });

  final _PresentationQuarantineItem item;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onEdit;

  @override
  State<_AnimatedQuarantineItemCard> createState() =>
      _AnimatedQuarantineItemCardState();
}

class _AnimatedQuarantineItemCardState extends State<_AnimatedQuarantineItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        );

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
        child: _QuarantineItemCard(
          item: widget.item,
          onApprove: widget.onApprove,
          onReject: widget.onReject,
          onEdit: widget.onEdit,
        ),
      ),
    );
  }
}

class _QuarantineItemCard extends StatelessWidget {
  const _QuarantineItemCard({
    required this.item,
    required this.onApprove,
    required this.onReject,
    required this.onEdit,
  });

  final _PresentationQuarantineItem item;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final confidenceColor = switch (item.confidence) {
      _Confidence.high => AppColors.success,
      _Confidence.medium => AppColors.warning,
      _Confidence.low => AppColors.danger,
    };

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTypography.cardTitle(context),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'at ${item.date.hour.toString().padLeft(2, '0')}:${item.date.minute.toString().padLeft(2, '0')}',
                      style: AppTypography.bodySm(context)
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.money(item.amount),
                    style: AppTypography.amount(context),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: confidenceColor.withValues(alpha: 0.12),
                      borderRadius: AppRadius.smAll,
                      border: Border.all(
                        color: confidenceColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      '${item.confidence.name} confidence',
                      style: AppTypography.bodySm(context).copyWith(
                        color: confidenceColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.5),
              borderRadius: AppRadius.mdAll,
            ),
            child: Text(
              item.rawMessage,
              style: AppTypography.bodySm(context)
                  .copyWith(color: AppColors.textSecondary, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.danger.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    'Reject',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.accent.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onApprove,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
