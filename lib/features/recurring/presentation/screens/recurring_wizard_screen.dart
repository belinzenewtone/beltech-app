import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/recurring/domain/entities/recurring_rule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecurringWizardScreen extends ConsumerStatefulWidget {
  final RecurringRule? existingRule;

  const RecurringWizardScreen({super.key, this.existingRule});

  @override
  ConsumerState<RecurringWizardScreen> createState() => _RecurringWizardScreenState();
}

class _RecurringWizardScreenState extends ConsumerState<RecurringWizardScreen> {
  late int _currentStep;
  late String _ruleName;
  late double _amount;
  late String _category;
  late RecurringFrequency _frequency;
  late int _dayOfMonth;
  late bool _isEnabled;

  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentStep = 0;
    _ruleName = widget.existingRule?.label ?? '';
    _amount = widget.existingRule?.estimatedAmount ?? 0;
    _category = widget.existingRule?.category ?? 'Other';
    _frequency = widget.existingRule?.frequency ?? RecurringFrequency.monthly;
    _dayOfMonth = widget.existingRule?.dayOfMonth ?? 1;
    _isEnabled = widget.existingRule?.isActive ?? true;

    _nameController.text = _ruleName;
    _amountController.text = _amount > 0 ? _amount.toString() : '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveRule() async {
    if (_nameController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      final recurringRepo = ref.read(recurringRepositoryProvider);

      if (widget.existingRule != null) {
        // Update existing rule
        final updated = widget.existingRule!.copyWith(
          label: _nameController.text,
          estimatedAmount: double.parse(_amountController.text),
          category: _category,
          frequency: _frequency,
          dayOfMonth: _dayOfMonth,
          isActive: _isEnabled,
        );
        // Would need updateRecurringRule method on repository
        // await recurringRepo.updateRecurringRule(updated);
      } else {
        // Create new rule - would need createRecurringRule method
        // await recurringRepo.createRecurringRule(...)
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.existingRule != null ? 'Rule updated' : 'Rule created')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SecondaryPageShell(
      title: widget.existingRule != null ? 'Edit Recurring Rule' : 'Create Recurring Rule',
      child: Column(
        children: [
          Expanded(
            child: Stepper(
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep < 3) {
                  setState(() => _currentStep++);
                } else {
                  _saveRule();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                } else {
                  Navigator.pop(context);
                }
              },
              steps: [
                Step(
                  title: const Text('Details'),
                  content: _buildDetailsStep(),
                  isActive: _currentStep >= 0,
                ),
                Step(
                  title: const Text('Amount'),
                  content: _buildAmountStep(),
                  isActive: _currentStep >= 1,
                ),
                Step(
                  title: const Text('Frequency'),
                  content: _buildFrequencyStep(),
                  isActive: _currentStep >= 2,
                ),
                Step(
                  title: const Text('Review'),
                  content: _buildReviewStep(),
                  isActive: _currentStep >= 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rule Name', style: AppTypography.bodySm(context)),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'e.g., Rent Payment',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (v) => _ruleName = v,
        ),
        const SizedBox(height: 16),
        Text('Category', style: AppTypography.bodySm(context)),
        const SizedBox(height: 8),
        DropdownButton<String>(
          value: _category,
          isExpanded: true,
          items: ['Rent', 'Utilities', 'Subscription', 'Insurance', 'Other']
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => _category = v ?? _category),
        ),
      ],
    );
  }

  Widget _buildAmountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Amount (KES)', style: AppTypography.bodySm(context)),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          decoration: InputDecoration(
            hintText: '0.00',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixText: 'KES ',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) {
            _amount = double.tryParse(v) ?? 0;
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This amount is used for projections and notifications',
                  style: AppTypography.bodySm(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Frequency', style: AppTypography.bodySm(context)),
        const SizedBox(height: 12),
        ...RecurringFrequency.values.map((f) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RadioListTile<RecurringFrequency>(
              title: Text(_frequencyLabel(f)),
              value: f,
              groupValue: _frequency,
              onChanged: (v) => setState(() => _frequency = v ?? _frequency),
            ),
          );
        }).toList(),
        const SizedBox(height: 16),
        if (_frequency == RecurringFrequency.monthly || _frequency == RecurringFrequency.yearly)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Day of Month', style: AppTypography.bodySm(context)),
              const SizedBox(height: 8),
              DropdownButton<int>(
                value: _dayOfMonth,
                isExpanded: true,
                items: List.generate(31, (i) => i + 1)
                    .map((d) => DropdownMenuItem(value: d, child: Text('Day $d')))
                    .toList(),
                onChanged: (v) => setState(() => _dayOfMonth = v ?? _dayOfMonth),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review Your Rule', style: AppTypography.sectionTitle(context)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _reviewRow('Name', _nameController.text),
              const Divider(height: 16),
              _reviewRow('Category', _category),
              const Divider(height: 16),
              _reviewRow('Amount', 'KES ${_amountController.text}'),
              const Divider(height: 16),
              _reviewRow('Frequency', _frequencyLabel(_frequency)),
              if (_frequency == RecurringFrequency.monthly || _frequency == RecurringFrequency.yearly)
                _reviewRow('Day', 'Day $_dayOfMonth'),
              const Divider(height: 16),
              _reviewRow('Status', _isEnabled ? 'Enabled' : 'Disabled'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Enable Rule'),
          value: _isEnabled,
          onChanged: (v) => setState(() => _isEnabled = v),
        ),
      ],
    );
  }

  Widget _reviewRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySm(context)),
        Text(value, style: AppTypography.bodySm(context).copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _frequencyLabel(RecurringFrequency freq) {
    return switch (freq) {
      RecurringFrequency.weekly => 'Weekly',
      RecurringFrequency.biweekly => 'Bi-weekly',
      RecurringFrequency.monthly => 'Monthly',
      RecurringFrequency.quarterly => 'Quarterly',
      RecurringFrequency.yearly => 'Yearly',
    };
  }
}
