import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
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
    final brightness = Theme.of(context).brightness;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
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
              Text('Log Session', style: AppTypography.headlineSm(context)),
              const SizedBox(height: 16),
              TextField(
                controller: _topicCtrl,
                decoration: const InputDecoration(
                  labelText: 'Topic',
                  prefixIcon: Icon(Icons.subject_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _minutesCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  prefixIcon: Icon(Icons.timer_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text('${_date.day}/${_date.month}/${_date.year}'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final topic = _topicCtrl.text.trim();
    final minutes = int.tryParse(_minutesCtrl.text) ?? 0;
    if (topic.isEmpty || minutes <= 0) return;
    await ref.read(learningRepositoryProvider).addSession(
      topic: topic,
      durationMinutes: minutes,
      date: _date,
    );
    if (mounted) Navigator.pop(context);
    AppHaptics.lightImpact();
  }
}
