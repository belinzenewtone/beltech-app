
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/loading_indicator.dart';
import 'package:beltech/core/utils/category_visual.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_form_sheet.dart';
import 'package:beltech/features/expenses/presentation/providers/expense_categories_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showCategoryManagerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CategoryManagerSheet(),
  );
}

class _CategoryManagerSheet extends ConsumerStatefulWidget {
  const _CategoryManagerSheet();

  @override
  ConsumerState<_CategoryManagerSheet> createState() =>
      _CategoryManagerSheetState();
}

class _CategoryManagerSheetState extends ConsumerState<_CategoryManagerSheet> {
  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(expenseCategoriesProvider);
    final categories = categoriesAsync.value ?? const <String>[];

    // Official categories not yet active — user can tap to restore them.
    final available = expenseCategoryDefaults
        .where((c) => !categories.any(
              (a) => a.toLowerCase() == c.toLowerCase(),
            ))
        .toList();

    return AppFormSheet(
      title: 'Manage categories',
      onClose: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (available.isNotEmpty) ...[
            Text('Add category', style: AppTypography.sectionTitle(context)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: available.map((name) {
                final visual = categoryVisual(name);
                return ActionChip(
                  avatar: CircleAvatar(
                    backgroundColor: visual.background,
                    child: Icon(visual.icon,
                        color: visual.foreground, size: 13),
                  ),
                  label: Text(name),
                  onPressed: categoriesAsync.isLoading
                      ? null
                      : () => ref
                          .read(expenseCategoriesProvider.notifier)
                          .addCategory(name),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
          Text('Your categories', style: AppTypography.sectionTitle(context)),
          const SizedBox(height: 10),
          if (categoriesAsync.isLoading)
            const SizedBox(
              height: 120,
              child: Center(child: LoadingIndicator()),
            )
          else
            ReorderableColumn(
              categories: categories,
              onRename: (oldName) => _showRenameDialog(oldName),
              onDelete: (name) => _delete(name),
              onReorder: (oldIndex, newIndex) => ref
                  .read(expenseCategoriesProvider.notifier)
                  .reorder(oldIndex, newIndex),
            ),
        ],
      ),
    );
  }

  Future<void> _delete(String name) async {
    await ref.read(expenseCategoriesProvider.notifier).deleteCategory(name);
  }

  Future<void> _showRenameDialog(String oldName) async {
    final controller = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename category'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Category name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || newName.isEmpty || newName == oldName) return;
    await ref
        .read(expenseCategoriesProvider.notifier)
        .renameCategory(oldName, newName);
  }
}

class ReorderableColumn extends StatelessWidget {
  const ReorderableColumn({
    super.key,
    required this.categories,
    required this.onRename,
    required this.onDelete,
    required this.onReorder,
  });

  final List<String> categories;
  final ValueChanged<String> onRename;
  final ValueChanged<String> onDelete;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      // ignore: deprecated_member_use
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final category = categories[index];
        final visual = categoryVisual(category);
        return AppCard(
          key: ValueKey(category),
          tone: AppCardTone.muted,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: visual.background,
                child: Icon(visual.icon, color: visual.foreground, size: 14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMd(context),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'rename') onRename(category);
                  if (value == 'delete') onDelete(category);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'rename', child: Text('Rename')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
