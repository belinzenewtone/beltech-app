import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/widgets/secondary_page_shell.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/features/loans/domain/entities/loan_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoanFormSheet extends ConsumerStatefulWidget {
  const LoanFormSheet({this.loan, super.key});
  final LoanItem? loan;

  @override
  ConsumerState<LoanFormSheet> createState() => _LoanFormSheetState();
}

class _LoanFormSheetState extends ConsumerState<LoanFormSheet> {
  late final _nameCtrl = TextEditingController(text: widget.loan?.name ?? '');
  late final _lenderCtrl = TextEditingController(text: widget.loan?.lender ?? '');
  late final _totalCtrl = TextEditingController(
      text: widget.loan != null ? widget.loan!.totalAmount.toStringAsFixed(0) : '');
  late final _outstandingCtrl = TextEditingController(
      text: widget.loan != null ? widget.loan!.outstandingAmount.toStringAsFixed(0) : '');
  late final _rateCtrl = TextEditingController(
      text: widget.loan?.interestRate?.toString() ?? '');
  late var _status = widget.loan?.status ?? LoanStatus.active;
  late DateTime? _dueDate = widget.loan?.dueDate;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _lenderCtrl.dispose();
    _totalCtrl.dispose();
    _outstandingCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
              Text(widget.loan == null ? 'Add Loan' : 'Edit Loan',
                  style: AppTypography.headlineSm(context)),
              const SizedBox(height: 16),
              _buildTextField('Name', _nameCtrl, icon: Icons.label_outline),
              const SizedBox(height: 10),
              _buildTextField('Lender', _lenderCtrl, icon: Icons.business_outlined),
              const SizedBox(height: 10),
              _buildTextField('Total Amount', _totalCtrl,
                  icon: Icons.attach_money, keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              _buildTextField('Outstanding', _outstandingCtrl,
                  icon: Icons.account_balance_wallet_outlined,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              _buildTextField('Interest Rate (%)', _rateCtrl,
                  icon: Icons.percent, keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
                child: GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          _dueDate != null
                              ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                              : 'Due date (optional)',
                          style: AppTypography.bodyMd(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: LoanStatus.values.map((s) {
                  final selected = _status == s;
                  return ChoiceChip(
                    label: Text(s.label),
                    selected: selected,
                    onSelected: (_) => setState(() => _status = s),
                    selectedColor: AppColors.accent.withValues(alpha: 0.2),
                    labelStyle: AppTypography.bodySm(context).copyWith(
                      color: selected ? AppColors.accent : null,
                      fontWeight: selected ? FontWeight.w600 : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(widget.loan == null ? 'Save' : 'Update'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {IconData? icon, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 18) : null,
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final total = double.tryParse(_totalCtrl.text) ?? 0;
    final outstanding = double.tryParse(_outstandingCtrl.text) ?? total;
    final rate = _rateCtrl.text.isEmpty ? null : double.tryParse(_rateCtrl.text);
    final repo = ref.read(loansRepositoryProvider);
    if (widget.loan == null) {
      await repo.addLoan(
        name: name,
        lender: _lenderCtrl.text.trim().isEmpty ? null : _lenderCtrl.text.trim(),
        totalAmount: total,
        outstandingAmount: outstanding,
        interestRate: rate,
        dueDate: _dueDate,
        status: _status,
      );
    } else {
      await repo.updateLoan(
        id: widget.loan!.id,
        name: name,
        lender: _lenderCtrl.text.trim().isEmpty ? null : _lenderCtrl.text.trim(),
        totalAmount: total,
        outstandingAmount: outstanding,
        interestRate: rate,
        dueDate: _dueDate,
        status: _status,
      );
    }
    if (mounted) Navigator.pop(context);
    AppHaptics.lightImpact();
  }
}
