import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/feedback/app_haptics.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_card.dart';
import 'package:beltech/core/widgets/app_form_sheet.dart';
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
  late final _lenderCtrl = TextEditingController(
    text: widget.loan?.lender ?? '',
  );
  late final _totalCtrl = TextEditingController(
    text: widget.loan != null
        ? widget.loan!.totalAmount.toStringAsFixed(0)
        : '',
  );
  late final _outstandingCtrl = TextEditingController(
    text: widget.loan != null
        ? widget.loan!.outstandingAmount.toStringAsFixed(0)
        : '',
  );
  late final _rateCtrl = TextEditingController(
    text: widget.loan?.interestRate?.toString() ?? '',
  );
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
    return AppFormSheet(
      title: widget.loan == null ? 'Add Loan' : 'Edit Loan',
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
              label: widget.loan == null ? 'Save' : 'Update',
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
            controller: _nameCtrl,
            decoration: const InputDecoration(hintText: 'Name'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _lenderCtrl,
            decoration: const InputDecoration(hintText: 'Lender'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _totalCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Total Amount'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _outstandingCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Outstanding'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _rateCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Interest Rate (%)'),
          ),
          const SizedBox(height: 14),
          AppCard(
            tone: AppCardTone.muted,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dueDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) setState(() => _dueDate = picked);
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
                      Text('Due date', style: AppTypography.bodySm(context)),
                      const SizedBox(height: 2),
                      Text(
                        _dueDate != null
                            ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
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
          const SizedBox(height: 14),
          Text('Status', style: AppTypography.sectionTitle(context)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: LoanStatus.values.map((s) {
              final selected = _status == s;
              return AppButton(
                label: s.label,
                size: AppButtonSize.sm,
                variant: selected
                    ? AppButtonVariant.primary
                    : AppButtonVariant.secondary,
                onPressed: () => setState(() => _status = s),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final total = double.tryParse(_totalCtrl.text) ?? 0;
    final outstanding = double.tryParse(_outstandingCtrl.text) ?? total;
    final rate = _rateCtrl.text.isEmpty
        ? null
        : double.tryParse(_rateCtrl.text);
    final repo = ref.read(loansRepositoryProvider);
    if (widget.loan == null) {
      await repo.addLoan(
        name: name,
        lender: _lenderCtrl.text.trim().isEmpty
            ? null
            : _lenderCtrl.text.trim(),
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
        lender: _lenderCtrl.text.trim().isEmpty
            ? null
            : _lenderCtrl.text.trim(),
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
