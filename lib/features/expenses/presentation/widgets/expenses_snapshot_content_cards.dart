part of 'expenses_snapshot_content.dart';

// ── Fuliza Summary Card ───────────────────────────────────────────────────────

class _FulizaSummaryCard extends StatelessWidget {
  const _FulizaSummaryCard({required this.events});
  final List<FulizaLifecycleEvent> events;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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

    return GlassCard(
      tone: GlassCardTone.muted,
      accentColor: isSettled ? AppColors.success : AppColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: (isSettled ? AppColors.success : AppColors.warning)
                      .withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSettled
                      ? Icons.check_circle_outline
                      : Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: isSettled ? AppColors.success : AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Text('Fuliza', style: textTheme.titleSmall),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isSettled ? AppColors.success : AppColors.warning)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isSettled ? 'Settled' : 'Outstanding',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSettled ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.money(outstanding.abs()),
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isSettled ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isSettled ? 'All Fuliza loans repaid' : 'balance remaining',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _FulizaStat(
                  label: 'Total Drawn',
                  value: CurrencyFormatter.compact(totalDrawn),
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FulizaStat(
                  label: 'Total Repaid',
                  value: CurrencyFormatter.compact(totalRepaid),
                  color: AppColors.success,
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
  const _FulizaStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.amount,
    this.tone = GlassCardTone.standard,
    this.accentColor,
  });

  final String title;
  final String amount;
  final GlassCardTone tone;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      tone: tone,
      accentColor: accentColor,
      child: SizedBox(
        height: 72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.bodyMedium),
            const SizedBox(height: 6),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amount,
                    style: textTheme.titleMedium,
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
    // Reload if category list changes (e.g. filter switch)
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
        title: '${entry.category} Budget',
        subtitle: current != null
            ? 'Currently KES ${CurrencyFormatter.compact(current)} · tap Save to update.'
            : 'Set a monthly spending limit for ${entry.category}.',
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
            const SizedBox(width: 12),
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
              // Category badge
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: visual.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: visual.foreground.withValues(alpha: 0.18),
                      ),
                    ),
                    child:
                        Icon(visual.icon, color: visual.foreground, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    entry.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.cardTitle(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: false),
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      _setBudget(entry.category, null);
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Remove limit'),
                    style:
                        TextButton.styleFrom(foregroundColor: AppColors.danger),
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
    final textTheme = Theme.of(context).textTheme;
    final grandTotal =
        widget.categories.fold<double>(0, (s, c) => s + c.totalKes);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Categories', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final entry in widget.categories.take(8)) ...[
            _CategoryRow(
              name: entry.category,
              totalKes: entry.totalKes,
              amount: CurrencyFormatter.money(entry.totalKes),
              budgetLimit: _budgets[entry.category],
              grandTotal: grandTotal,
              onTap: () => _openBudgetDialog(context, entry),
            ),
            const SizedBox(height: 10),
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

    // Tooltip message shown on long-press
    final tooltipMsg = hasBudget
        ? 'KES ${CurrencyFormatter.compact(totalKes)} / KES ${CurrencyFormatter.compact(budgetLimit!)}'
        : 'KES ${CurrencyFormatter.compact(totalKes)} spent';

    final percentLabel = hasBudget
        ? '${(totalKes / budgetLimit! * 100).clamp(0, 999).round()}%'
        : (grandTotal > 0 ? '${(totalKes / grandTotal * 100).round()}%' : '');
    final percentSuffix = hasBudget ? ' of budget' : ' of spend';

    return Tooltip(
      message: tooltipMsg,
      preferBelow: true,
      triggerMode: TooltipTriggerMode.longPress,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon with tinted background
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: visual.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: visual.foreground.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Icon(visual.icon, color: visual.foreground, size: 18),
              ),
              const SizedBox(width: 12),
              // Name + bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: AppTypography.cardTitle(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasBudget)
                          Icon(
                            Icons.tune_rounded,
                            size: 12,
                            color: isOverBudget
                                ? AppColors.danger
                                : AppColors.textMuted,
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Thicker progress bar with track
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 6,
                        child: LinearProgressIndicator(
                          value: ratio,
                          backgroundColor:
                              AppColors.textMuted.withValues(alpha: 0.14),
                          valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Percent label under bar
                    if (percentLabel.isNotEmpty)
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: percentLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color:
                                    isOverBudget ? AppColors.danger : barColor,
                              ),
                            ),
                            TextSpan(
                              text: percentSuffix,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Amount — right aligned
              Text(
                amount,
                style: AppTypography.cardTitle(context).copyWith(
                  color: isOverBudget ? AppColors.danger : null,
                ),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
