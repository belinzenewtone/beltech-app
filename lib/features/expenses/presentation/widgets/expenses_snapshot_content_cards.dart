part of 'expenses_snapshot_content.dart';

// ── Fuliza Summary Card ───────────────────────────────────────────────────────

class _FulizaSummaryCard extends StatelessWidget {
  const _FulizaSummaryCard({required this.events});
  final List<FulizaLifecycleEvent> events;

  @override
  Widget build(BuildContext context) {
    final outstanding = events.fold<double>(
      0,
      (sum, e) => e.kind == FulizaLifecycleKind.draw
          ? sum + e.amountKes
          : sum - e.amountKes,
    );
    final totalDrawn = events
        .where((e) => e.kind == FulizaLifecycleKind.draw)
        .fold<double>(0, (s, e) => s + e.amountKes);
    final totalRepaid = events
        .where((e) => e.kind == FulizaLifecycleKind.repayment)
        .fold<double>(0, (s, e) => s + e.amountKes);
    final isSettled = outstanding <= 0;

    return AppCard(
      tone: AppCardTone.muted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Fuliza', style: AppTypography.cardTitle(context)),
              const Spacer(),
              AppCapsule(
                label: isSettled ? 'Settled' : 'Outstanding',
                color: isSettled ? AppColors.success : AppColors.warning,
                variant: AppCapsuleVariant.subtle,
                size: AppCapsuleSize.sm,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.money(outstanding.abs()),
              style: AppTypography.amountLg(context),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _FulizaStat(
                  label: 'Drawn',
                  value: CurrencyFormatter.compact(totalDrawn),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _FulizaStat(
                  label: 'Repaid',
                  value: CurrencyFormatter.compact(totalRepaid),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FulizaStat extends StatelessWidget {
  const _FulizaStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.amount(context),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label(context),
          ),
        ],
      ),
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.amount,
    this.tone = AppCardTone.standard,
    this.accentColor,
    this.delta,
    this.deltaIsGood,
  });

  final String title;
  final String amount;
  final AppCardTone tone;
  final Color? accentColor;
  // Optional week-over-week delta string, e.g. '+12%' or '-5%'.
  final String? delta;
  // True means spending went down (green), false means up (red).
  final bool? deltaIsGood;

  @override
  Widget build(BuildContext context) {
    final deltaColor = deltaIsGood == null
        ? AppColors.textMuted
        : (deltaIsGood! ? AppColors.success : AppColors.danger);
    return AppCard(
      tone: tone,
      accentColor: accentColor,
      child: SizedBox(
        height: 72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: AppTypography.bodySm(context)),
                ),
                if (delta != null)
                  Text(
                    delta!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.metaText(
                      context,
                    ).copyWith(fontWeight: FontWeight.w700, color: deltaColor),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amount,
                    style: AppTypography.amount(context),
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Budget Mini Card ──────────────────────────────────────────────────────────

class _BudgetMiniCard extends StatelessWidget {
  const _BudgetMiniCard({
    required this.budgetSnapshot,
    required this.monthTotal,
  });

  final BudgetSnapshot? budgetSnapshot;
  final double monthTotal;

  @override
  Widget build(BuildContext context) {
    final limit = budgetSnapshot?.totalLimitKes ?? 0.0;
    final hasBudget = limit > 0;
    final ratio = hasBudget ? (monthTotal / limit).clamp(0.0, 1.0) : 0.0;
    final isOver = hasBudget && monthTotal > limit;
    final color = isOver
        ? AppColors.danger
        : (hasBudget && ratio >= 0.8)
        ? AppColors.warning
        : AppColors.accent;

    return AppCard(
      tone: AppCardTone.muted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budget', style: AppTypography.bodySm(context)),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.money(monthTotal),
              style: AppTypography.amount(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hasBudget
                ? 'of ${CurrencyFormatter.money(limit)}'
                : 'spent this month',
            style: AppTypography.bodySm(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (hasBudget) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 5,
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: AppColors.textMuted.withValues(alpha: 0.14),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Month-End Forecast Mini Card ──────────────────────────────────────────────

class _ForecastMiniCard extends StatelessWidget {
  const _ForecastMiniCard({required this.monthTotal});

  final double monthTotal;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dayOfMonth = now.day.clamp(1, daysInMonth);
    final forecast = (monthTotal / dayOfMonth) * daysInMonth;

    return AppCard(
      tone: AppCardTone.muted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Month-end forecast', style: AppTypography.bodySm(context)),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.money(forecast),
              style: AppTypography.amount(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'at current pace',
            style: AppTypography.bodySm(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Category budget storage key helper ───────────────────────────────────────

String _budgetKey(String category) => 'category_budget_$category';

// ── _CategoryCard (stateful — manages per-category budget limits) ─────────────

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({required this.categories});

  final List<CategoryExpenseTotal> categories;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  Map<String, double> _budgets = {};
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  @override
  void didUpdateWidget(_CategoryCard old) {
    super.didUpdateWidget(old);
    if (old.categories != widget.categories) _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final budgets = <String, double>{};
    for (final cat in widget.categories) {
      final val = prefs.getDouble(_budgetKey(cat.category));
      if (val != null) budgets[cat.category] = val;
    }
    setState(() {
      _prefs = prefs;
      _budgets = budgets;
    });
  }

  Future<void> _setBudget(String category, double? limit) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    if (limit == null || limit <= 0) {
      await prefs.remove(_budgetKey(category));
      if (mounted) setState(() => _budgets.remove(category));
    } else {
      await prefs.setDouble(_budgetKey(category), limit);
      if (mounted) setState(() => _budgets[category] = limit);
    }
  }

  Future<void> _openBudgetDialog(
    BuildContext context,
    CategoryExpenseTotal entry,
  ) async {
    final current = _budgets[entry.category];
    final controller = TextEditingController(
      text: current != null ? current.toStringAsFixed(0) : '',
    );
    final formKey = GlobalKey<FormState>();
    final visual = categoryVisual(entry.category);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => AppFormSheet(
        title: '${entry.category} budget',
        onClose: () => Navigator.pop(sheetCtx),
        footer: Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Cancel',
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.pop(sheetCtx),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                label: 'Save',
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  final val = double.tryParse(controller.text.trim());
                  Navigator.pop(sheetCtx);
                  _setBudget(entry.category, val);
                },
              ),
            ),
          ],
        ),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: visual.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      visual.icon,
                      color: visual.foreground,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    entry.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.cardTitle(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Monthly limit',
                  hintText: 'e.g. 5000',
                  prefixText: 'KES ',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  final val = double.tryParse(v.trim());
                  if (val == null || val <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              if (current != null) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      _setBudget(entry.category, null);
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Remove limit'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grandTotal = widget.categories.fold<double>(
      0,
      (s, c) => s + c.totalKes,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Categories', style: AppTypography.cardTitle(context)),
          const SizedBox(height: AppSpacing.md),
          for (final entry in widget.categories.take(8)) ...[
            _CategoryRow(
              name: entry.category,
              totalKes: entry.totalKes,
              amount: CurrencyFormatter.money(entry.totalKes),
              budgetLimit: _budgets[entry.category],
              grandTotal: grandTotal,
              onTap: () => _openBudgetDialog(context, entry),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

// ── _CategoryRow ──────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.name,
    required this.totalKes,
    required this.amount,
    required this.grandTotal,
    required this.onTap,
    this.budgetLimit,
  });

  final String name;
  final double totalKes;
  final String amount;
  final double grandTotal;
  final double? budgetLimit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = categoryVisual(name);

    final hasBudget = budgetLimit != null && budgetLimit! > 0;
    final ratio = hasBudget
        ? (totalKes / budgetLimit!).clamp(0.0, 1.0)
        : (grandTotal <= 0 ? 0.0 : (totalKes / grandTotal).clamp(0.0, 1.0));
    final isOverBudget = hasBudget && totalKes > budgetLimit!;
    final barColor = isOverBudget ? AppColors.danger : visual.foreground;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: visual.background,
                shape: BoxShape.circle,
              ),
              child: Icon(visual.icon, color: visual.foreground, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: AppTypography.cardTitle(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: 5,
                      child: LinearProgressIndicator(
                        value: ratio,
                        backgroundColor: AppColors.textMuted.withValues(
                          alpha: 0.14,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              amount,
              style: AppTypography.bodyMd(context).copyWith(
                fontWeight: FontWeight.w600,
                color: isOverBudget ? AppColors.danger : null,
              ),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
            ),
          ],
        ),
      ),
    );
  }
}
