import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:flutter/material.dart';

class QuarantineQueueScreen extends StatefulWidget {
  const QuarantineQueueScreen({super.key});

  @override
  State<QuarantineQueueScreen> createState() => _QuarantineQueueScreenState();
}

class _QuarantineQueueScreenState extends State<QuarantineQueueScreen> {
  late List<_QuarantineItem> _allItems;
  late List<_QuarantineItem> _filteredItems;
  MpesaConfidence? _selectedConfidence;
  _SortOption _sortBy = _SortOption.dateNewest;

  @override
  void initState() {
    super.initState();
    _allItems = [
      _QuarantineItem(
        title: 'M-Pesa Transfer',
        amount: 1500.0,
        date: DateTime.now().subtract(const Duration(days: 1)),
        confidence: MpesaConfidence.medium,
        rawMessage: 'M-Pesa confirmed. You have received KES1,500.00...',
      ),
      _QuarantineItem(
        title: 'Paybill Payment',
        amount: 2000.0,
        date: DateTime.now().subtract(const Duration(days: 2)),
        confidence: MpesaConfidence.low,
        rawMessage: 'You have paid KES2,000.00 to Paybill 123456...',
      ),
      _QuarantineItem(
        title: 'Buy Goods',
        amount: 750.0,
        date: DateTime.now().subtract(const Duration(days: 3)),
        confidence: MpesaConfidence.high,
        rawMessage: 'You have paid KES750.00 to Merchant ABC...',
      ),
      _QuarantineItem(
        title: 'ATM Withdrawal',
        amount: 5000.0,
        date: DateTime.now().subtract(const Duration(days: 4)),
        confidence: MpesaConfidence.medium,
        rawMessage: 'ATM withdrawal of KES5,000.00 successful...',
      ),
    ];
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    _filteredItems = _allItems.where((item) {
      if (_selectedConfidence != null && item.confidence != _selectedConfidence) {
        return false;
      }
      return true;
    }).toList();

    _filteredItems.sort((a, b) {
      return switch (_sortBy) {
        _SortOption.dateNewest => b.date.compareTo(a.date),
        _SortOption.dateOldest => a.date.compareTo(b.date),
        _SortOption.amountHighest => b.amount.compareTo(a.amount),
        _SortOption.amountLowest => a.amount.compareTo(b.amount),
        _SortOption.confidenceLowest => a.confidence.index.compareTo(b.confidence.index),
      };
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
            child: _filteredItems.isEmpty
                ? _buildEmptyState(context)
                : ListView.separated(
                    itemCount: _filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.listGap),
                    itemBuilder: (_, index) {
                      final item = _filteredItems[index];
                      return _AnimatedQuarantineItemCard(
                        key: ValueKey(item.title),
                        item: item,
                        onApprove: () {},
                        onReject: () {},
                        onEdit: () {},
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
            label: 'All Confidence',
            isSelected: _selectedConfidence == null,
            onSelected: (_) {
              _selectedConfidence = null;
              _applyFiltersAndSort();
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip(
            label: 'Low',
            isSelected: _selectedConfidence == MpesaConfidence.low,
            onSelected: (_) {
              _selectedConfidence = MpesaConfidence.low;
              _applyFiltersAndSort();
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip(
            label: 'Medium',
            isSelected: _selectedConfidence == MpesaConfidence.medium,
            onSelected: (_) {
              _selectedConfidence = MpesaConfidence.medium;
              _applyFiltersAndSort();
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip(
            label: 'High',
            isSelected: _selectedConfidence == MpesaConfidence.high,
            onSelected: (_) {
              _selectedConfidence = MpesaConfidence.high;
              _applyFiltersAndSort();
            },
          ),
          const SizedBox(width: AppSpacing.lg),
          PopupMenuButton<_SortOption>(
            onSelected: (option) {
              _sortBy = option;
              _applyFiltersAndSort();
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
      onSelected: (_) => onSelected(),
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

class _QuarantineItem {
  const _QuarantineItem({
    required this.title,
    required this.amount,
    required this.date,
    required this.confidence,
    required this.rawMessage,
  });

  final String title;
  final double amount;
  final DateTime date;
  final MpesaConfidence confidence;
  final String rawMessage;
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

  final _QuarantineItem item;
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

  final _QuarantineItem item;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final confidenceColor = switch (item.confidence) {
      MpesaConfidence.high => AppColors.success,
      MpesaConfidence.medium => AppColors.warning,
      MpesaConfidence.low => AppColors.danger,
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
