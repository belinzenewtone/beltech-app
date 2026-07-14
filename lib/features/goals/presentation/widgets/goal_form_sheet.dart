import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_form_sheet.dart';
import 'package:beltech/features/goals/domain/entities/goal_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GoalFormSheet extends ConsumerStatefulWidget {
  const GoalFormSheet({this.goal, super.key});
  final GoalItem? goal;

  @override
  ConsumerState<GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends ConsumerState<GoalFormSheet> {
  late final _titleCtrl = TextEditingController(text: widget.goal?.title ?? '');
  late final _targetCtrl = TextEditingController(
    text: widget.goal != null
        ? widget.goal!.targetAmount.toStringAsFixed(0)
        : '',
  );
  late final _currentCtrl = TextEditingController(
    text: widget.goal != null
        ? widget.goal!.currentAmount.toStringAsFixed(0)
        : '',
  );
  late DateTime? _deadline = widget.goal?.deadline;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    _currentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: widget.goal == null ? 'Add Goal' : 'Edit Goal',
      onClose: () => Navigator.pop(context),
      footer: Row(
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              label: widget.goal == null ? 'Save' : 'Update',
              fullWidth: true,
              onPressed: _save,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(hintText: 'Title'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _targetCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Target Amount'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _currentCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Current Amount'),
          ),
          const SizedBox(height: 14),
          AppCard(
            tone: AppCardTone.muted,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _deadline ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) setState(() => _deadline = picked);
            },
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Deadline', style: AppTypography.bodySm(context)),
                      const SizedBox(height: 2),
                      Text(
                        _deadline != null
                            ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                            : 'Optional',
                        style: AppTypography.bodyMd(context),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    final target = double.tryParse(_targetCtrl.text) ?? 0;
    final current = double.tryParse(_currentCtrl.text) ?? 0;
    final repo = ref.read(goalsRepositoryProvider);
    if (widget.goal == null) {
      await repo.addGoal(
        title: title,
        targetAmount: target,
        currentAmount: current,
        deadline: _deadline,
      );
    } else {
      await repo.updateGoal(
        id: widget.goal!.id,
        title: title,
        targetAmount: target,
        currentAmount: current,
        deadline: _deadline,
      );
    }
    if (mounted) Navigator.pop(context);
    AppHaptics.lightImpact();
  }
}
