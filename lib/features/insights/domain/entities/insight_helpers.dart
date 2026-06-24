import 'package:beltech/features/insights/domain/entities/insight_card.dart';

const _tips = [
  (
    id: 'tip-50-30-20',
    title: 'Try the 50/30/20 rule',
    body:
        'Allocate 50% of income to needs, 30% to wants, '
        'and 20% to savings or debt repayment.',
  ),
  (
    id: 'tip-emergency-fund',
    title: 'Build an emergency fund',
    body:
        'Aim for 3-6 months of essential expenses in an '
        'easily accessible account.',
  ),
  (
    id: 'tip-track-small',
    title: 'Small expenses add up',
    body:
        'Track daily small purchases — they often account for '
        'a surprising share of monthly spending.',
  ),
  (
    id: 'tip-weekly-review',
    title: 'Do a weekly money review',
    body:
        'Spend 10 minutes each week reviewing your transactions. '
        'Awareness alone can reduce unnecessary spending.',
  ),
  (
    id: 'tip-pay-yourself-first',
    title: 'Pay yourself first',
    body:
        'Set up an automatic transfer to savings right after '
        'income arrives. Treat savings like a recurring bill.',
  ),
  (
    id: 'tip-one-category',
    title: 'Focus on one category',
    body:
        'Pick your highest spending category and challenge yourself '
        'to reduce it by 10% next month.',
  ),
];

InsightCard generalTipInsight(DateTime now) {
  final tip = _tips[now.day % _tips.length];
  return InsightCard(
    id: tip.id,
    kind: InsightKind.general,
    title: tip.title,
    body: tip.body,
    tone: InsightTone.info,
    confidence: 0.3,
    generatedAt: now,
  );
}

String fmtDateShort(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$day/$m';
}
