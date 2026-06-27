import 'package:beltech/core/di/expenses_providers.dart';
import 'package:beltech/core/forms/form_schemas.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/utils/category_visual.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/utils/currency_formatter.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_form_sheet.dart';
import 'package:beltech/core/widgets/app_toast.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/expenses/presentation/providers/expense_categories_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuarantineQueueScreen extends ConsumerStatefulWidget {
  const QuarantineQueueScreen({super.key});

  @override
  ConsumerState<QuarantineQueueScreen> createState() =>
      _QuarantineQueueScreenState();
}

class _QuarantineQueueScreenState extends ConsumerState<QuarantineQueueScreen> {
  _Confidence? _selectedConfidence;
  _SortOption _sortBy = _SortOption.dateNewest;
  Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quarantineQueueNotifierProvider.notifier).load();
    });
  }

  List<_PresentationQuarantineItem> _getFilteredAndSortedItems(
    List<_PresentationQuarantineItem> items,
  ) {
    final filtered = items.where((item) {
      if (_selectedConfidence != null &&
          item.confidence != _selectedConfidence) {
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
        _SortOption.confidenceLowest => a.confidence.index.compareTo(
          b.confidence.index,
        ),
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
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              'Review and confirm low-confidence imports',
              style: AppTypography.bodySm(
                context,
              ).copyWith(color: AppColors.textSecondary),
            ),
          ),
          _buildFilterAndSortBar(context),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: quarantineState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
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
                      'Failed to load transactions',
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
                final presentationItems = items
                    .map(_toPresentationItem)
                    .toList();
                final filteredItems = _getFilteredAndSortedItems(
                  presentationItems,
                );

                return filteredItems.isEmpty
                    ? _buildEmptyState(context)
                    : Stack(
                        children: [
                          ListView.separated(
                            itemCount: filteredItems.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.listGap),
                            itemBuilder: (_, index) {
                              final item = filteredItems[index];
                              final isSelected = _selectedIds.contains(item.id);
                              return _AnimatedQuarantineItemCard(
                                key: ValueKey(item.id),
                                item: item,
                                isSelected: isSelected,
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
                                onApprove: () => _handleApprove(item, notifier),
                                onReject: () => _handleReject(item, notifier),
                                onEdit: () => _handleEdit(item, notifier),
                              );
                            },
                          ),
                          if (_isSelectionMode)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: _buildBulkActionBar(
                                context,
                                filteredItems,
                                notifier,
                              ),
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

  _PresentationQuarantineItem _toPresentationItem(QuarantineItem item) {
    final confidence = switch (item.analysis.score) {
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
      reason: item.reason,
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
    final result = await showModalBottomSheet<_QuarantineEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _QuarantineEditSheet(
        title: item.title,
        amount: item.amount,
        category: item.domainItem.candidate.category,
      ),
    );

    if (result == null || !mounted) return;

    await notifier.approveWithEdits(
      item.domainItem,
      result.title,
      result.amount,
      result.category,
    );
  }

  Future<void> _handleBulkApprove(
    List<_PresentationQuarantineItem> allItems,
    QuarantineQueueNotifier notifier,
  ) async {
    final itemsToApprove = allItems
        .where((item) => _selectedIds.contains(item.id))
        .toList();
    for (final item in itemsToApprove) {
      await notifier.approve(item.domainItem);
    }
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _handleBulkReject(
    List<_PresentationQuarantineItem> allItems,
    QuarantineQueueNotifier notifier,
  ) async {
    final itemsToReject = allItems
        .where((item) => _selectedIds.contains(item.id))
        .toList();
    for (final item in itemsToReject) {
      await notifier.reject(item.domainItem);
    }
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  void _toggleSelectAll(List<_PresentationQuarantineItem> items) {
    setState(() {
      if (_selectedIds.length == items.length) {
        _selectedIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedIds = items.map((item) => item.id).toSet();
        _isSelectionMode = true;
      }
    });
  }

  Widget _buildBulkActionBar(
    BuildContext context,
    List<_PresentationQuarantineItem> allItems,
    QuarantineQueueNotifier notifier,
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
                onPressed: () => _toggleSelectAll(allItems),
                child: Text(
                  _selectedIds.length == allItems.length
                      ? 'Deselect'
                      : 'Select All',
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
                  onPressed: () => _handleBulkReject(allItems, notifier),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'Approve All',
                  onPressed: () => _handleBulkApprove(allItems, notifier),
                ),
              ),
            ],
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
                .map(
                  (option) =>
                      PopupMenuItem(value: option, child: Text(option.label)),
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
      onSelected: (selected) => onSelected(),
      selectedColor: AppColors.accent.withValues(alpha: 0.1),
      side: BorderSide(color: isSelected ? AppColors.accent : AppColors.border),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Center(
        child: Text(
          _selectedConfidence != null
              ? 'No ${_selectedConfidence!.name} confidence items'
              : 'Nothing to review',
          style: AppTypography.bodyMd(
            context,
          ).copyWith(color: AppColors.textSecondary),
        ),
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
    required this.reason,
    required this.domainItem,
  });

  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final _Confidence confidence;
  final String rawMessage;
  final String reason;
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
    required this.isSelected,
    required this.onSelect,
    required this.onApprove,
    required this.onReject,
    required this.onEdit,
  });

  final _PresentationQuarantineItem item;
  final bool isSelected;
  final ValueChanged<bool> onSelect;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onEdit;

  @override
  State<_AnimatedQuarantineItemCard> createState() =>
      _AnimatedQuarantineItemCardState();
}

class _AnimatedQuarantineItemCardState
    extends State<_AnimatedQuarantineItemCard>
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

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.2, 0),
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
        child: _QuarantineItemCard(
          item: widget.item,
          isSelected: widget.isSelected,
          onSelect: widget.onSelect,
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
    required this.isSelected,
    required this.onSelect,
    required this.onApprove,
    required this.onReject,
    required this.onEdit,
  });

  final _PresentationQuarantineItem item;
  final bool isSelected;
  final ValueChanged<bool> onSelect;
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

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (value) => onSelect(value ?? false),
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
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.date.hour.toString().padLeft(2, '0')}:${item.date.minute.toString().padLeft(2, '0')}',
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
                    CurrencyFormatter.money(item.amount),
                    style: AppTypography.bodyMd(
                      context,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    item.confidence.name,
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
                  'Quarantined: ${item.reason}',
                  style: AppTypography.bodySm(
                    context,
                  ).copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
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

class _QuarantineEditResult {
  const _QuarantineEditResult({
    required this.title,
    required this.amount,
    required this.category,
  });

  final String title;
  final double amount;
  final String category;
}

class _QuarantineEditSheet extends ConsumerStatefulWidget {
  const _QuarantineEditSheet({
    required this.title,
    required this.amount,
    required this.category,
  });

  final String title;
  final double amount;
  final String category;

  @override
  ConsumerState<_QuarantineEditSheet> createState() =>
      _QuarantineEditSheetState();
}

class _QuarantineEditSheetState extends ConsumerState<_QuarantineEditSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _amountController = TextEditingController(
      text: widget.amount.toStringAsFixed(2),
    );
    _selectedCategory = widget.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(expenseCategoriesProvider);
    final categories = categoriesAsync.value ?? expenseCategoryDefaults;
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = categories.first;
    }

    return AppFormSheet(
      title: 'Edit & Approve',
      onClose: () => Navigator.of(context).pop(),
      footer: Row(
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              label: 'Approve',
              fullWidth: true,
              onPressed: categoriesAsync.isLoading ? null : _submit,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Title'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: 'Amount (KES)'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: const InputDecoration(labelText: 'Category'),
            items: categories.map((c) {
              final visual = categoryVisual(c);
              return DropdownMenuItem<String>(
                value: c,
                child: Row(
                  children: [
                    Icon(visual.icon, size: 16, color: visual.foreground),
                    const SizedBox(width: 10),
                    Text(c),
                  ],
                ),
              );
            }).toList(),
            onChanged: categoriesAsync.isLoading
                ? null
                : (v) { if (v != null) setState(() => _selectedCategory = v); },
          ),
        ],
      ),
    );
  }

  void _submit() {
    final result = FormSchemas.expenseSchema.validate({
      'title': _titleController.text,
      'amount': _amountController.text,
      'category': _selectedCategory,
    });
    if (!result.isValid) {
      final firstError = result.errors.values.first;
      ref.read(toastProvider.notifier).error(firstError);
      return;
    }
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    Navigator.of(context).pop(
      _QuarantineEditResult(
        title: _titleController.text.trim(),
        amount: amount,
        category: _selectedCategory,
      ),
    );
  }
}
