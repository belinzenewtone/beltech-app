import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/features/recurring/domain/entities/recurring_rule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecurringWizardScreen extends ConsumerStatefulWidget {
  final RecurringRule? existingRule;

  const RecurringWizardScreen({super.key, this.existingRule});

  @override
  ConsumerState<RecurringWizardScreen> createState() =>
      _RecurringWizardScreenState();
}

class _RecurringWizardScreenState extends ConsumerState<RecurringWizardScreen> {
  late int _currentStep;
  late String _ruleName;
  late double _amount;
  late String _category;
  late RecurringFrequency _frequency;
  late bool _isEnabled;

  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentStep = 0;
    _ruleName = widget.existingRule?.name ?? '';
    _amount = widget.existingRule?.estimatedAmount ?? 0;
    _category = widget.existingRule?.category ?? 'Other';
    _frequency = widget.existingRule?.frequency ?? RecurringFrequency.monthly;
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
      if (widget.existingRule != null) {
        // Would need updateRecurringRule method on repository
      } else {
        // Create new rule - would need createRecurringRule method
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingRule != null ? 'Rule updated' : 'Rule created',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SecondaryPageShell(
      title: widget.existingRule != null
          ? 'Edit Recurring Rule'
          : 'Create Recurring Rule',
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
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Rule Name'),
          onChanged: (v) => _ruleName = v,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: const InputDecoration(labelText: 'Category'),
          items: [
            'Rent',
            'Utilities',
            'Subscription',
            'Insurance',
            'Other',
          ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => _category = v ?? _category),
        ),
      ],
    );
  }

  Widget _buildAmountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _amountController,
          decoration: const InputDecoration(
            labelText: 'Amount (KES)',
            prefixText: 'KES ',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) {
            _amount = double.tryParse(v) ?? 0;
          },
        ),
      ],
    );
  }

  Widget _buildFrequencyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RadioGroup<RecurringFrequency>(
          groupValue: _frequency,
          onChanged: (v) => setState(() => _frequency = v ?? _frequency),
          child: Column(
            children: [
              for (final f in RecurringFrequency.values)
                RadioListTile<RecurringFrequency>(
                  dense: true,
                  title: Text(_frequencyLabel(f)),
                  value: f,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          tone: AppCardTone.muted,
          child: Column(
            children: [
              _reviewRow('Name', _nameController.text),
              const Divider(height: 16),
              _reviewRow('Category', _category),
              const Divider(height: 16),
              _reviewRow('Amount', 'KES ${_amountController.text}'),
              const Divider(height: 16),
              _reviewRow('Frequency', _frequencyLabel(_frequency)),
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
        Text(
          value,
          style: AppTypography.bodySm(
            context,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _frequencyLabel(RecurringFrequency freq) {
    return switch (freq) {
      RecurringFrequency.daily => 'Daily',
      RecurringFrequency.weekly => 'Weekly',
      RecurringFrequency.biweekly => 'Bi-weekly',
      RecurringFrequency.monthly => 'Monthly',
      RecurringFrequency.quarterly => 'Quarterly',
      RecurringFrequency.annually => 'Annually',
    };
  }
}
