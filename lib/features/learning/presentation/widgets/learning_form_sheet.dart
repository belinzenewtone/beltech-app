import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LearningFormSheet extends ConsumerStatefulWidget {
  const LearningFormSheet({super.key});

  @override
  ConsumerState<LearningFormSheet> createState() => _LearningFormSheetState();
}

class _LearningFormSheetState extends ConsumerState<LearningFormSheet> {
  final _topicCtrl = TextEditingController();
  final _minutesCtrl = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _topicCtrl.dispose();
    _minutesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: 'Log Session',
      onClose: () => Navigator.pop(context),
      footer: Row(
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(label: 'Save', fullWidth: true, onPressed: _save),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _topicCtrl,
            decoration: const InputDecoration(hintText: 'Topic'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _minutesCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Duration (minutes)'),
          ),
          const SizedBox(height: 14),
          AppCard(
            tone: AppCardTone.muted,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) setState(() => _date = picked);
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
                      Text('Date', style: AppTypography.bodySm(context)),
                      const SizedBox(height: 2),
                      Text(
                        '${_date.day}/${_date.month}/${_date.year}',
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
    final topic = _topicCtrl.text.trim();
    final minutes = int.tryParse(_minutesCtrl.text) ?? 0;
    if (topic.isEmpty || minutes <= 0) return;
    await ref
        .read(learningRepositoryProvider)
        .addSession(topic: topic, durationMinutes: minutes, date: _date);
    if (mounted) Navigator.pop(context);
    AppHaptics.lightImpact();
  }
}
