import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/glass_card.dart';
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
      text: widget.goal != null ? widget.goal!.targetAmount.toStringAsFixed(0) : '');
  late final _currentCtrl = TextEditingController(
      text: widget.goal != null ? widget.goal!.currentAmount.toStringAsFixed(0) : '');
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
    final brightness = Theme.of(context).brightness;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.borderFor(brightness),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(widget.goal == null ? 'Add Goal' : 'Edit Goal',
                  style: AppTypography.headlineSm(context)),
              const SizedBox(height: 16),
              _buildField('Title', _titleCtrl, icon: Icons.flag_outlined),
              const SizedBox(height: 10),
              _buildField('Target Amount', _targetCtrl,
                  icon: Icons.attach_money, type: TextInputType.number),
              const SizedBox(height: 10),
              _buildField('Current Amount', _currentCtrl,
                  icon: Icons.savings_outlined, type: TextInputType.number),
              const SizedBox(height: 10),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _deadline ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) setState(() => _deadline = picked);
                },
                child: GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          _deadline != null
                              ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                              : 'Deadline (optional)',
                          style: AppTypography.bodyMd(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(widget.goal == null ? 'Save' : 'Update'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {IconData? icon, TextInputType? type}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 18) : null,
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
      await repo.addGoal(title: title, targetAmount: target, currentAmount: current, deadline: _deadline);
    } else {
      await repo.updateGoal(id: widget.goal!.id, title: title, targetAmount: target, currentAmount: current, deadline: _deadline);
    }
    if (mounted) Navigator.pop(context);
    AppHaptics.lightImpact();
  }
}
