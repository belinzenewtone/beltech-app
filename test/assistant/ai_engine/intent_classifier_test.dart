import 'package:beltech/features/assistant/domain/ai_engine/intent_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const classifier = IntentClassifier();

  group('IntentClassifier', () {
    test('classifies spending queries', () {
      expect(classifier.classify('How much did I spend today?'), Intent.spendingSummary);
      expect(classifier.classify('Show my expenses'), Intent.spendingSummary);
      expect(classifier.classify('Where did my money go?'), Intent.spendingSummary);
    });

    test('classifies income queries', () {
      expect(classifier.classify('What is my income?'), Intent.incomeSummary);
      expect(classifier.classify('How much did I earn?'), Intent.incomeSummary);
    });

    test('classifies balance queries', () {
      expect(classifier.classify('What is my balance?'), Intent.balanceCheck);
      expect(classifier.classify('How much do I have?'), Intent.balanceCheck);
    });

    test('classifies task queries', () {
      expect(classifier.classify('Do I have pending tasks?'), Intent.taskSummary);
      expect(classifier.classify('What should I do today?'), Intent.taskSummary);
    });

    test('classifies health queries', () {
      expect(classifier.classify('How is my financial health?'), Intent.healthCheck);
      expect(classifier.classify('What is my score?'), Intent.healthCheck);
    });

    test('classifies anomaly queries', () {
      expect(classifier.classify('Any anomalies?'), Intent.anomalyAlert);
      expect(classifier.classify('Suspicious transactions'), Intent.anomalyAlert);
    });

    test('classifies cash flow queries', () {
      expect(classifier.classify('Project my cash flow'), Intent.cashFlowProjection);
      expect(classifier.classify('Will I have enough next month?'), Intent.cashFlowProjection);
    });

    test('classifies goal queries', () {
      expect(classifier.classify('How are my goals?'), Intent.goalSummary);
      expect(classifier.classify('Savings progress'), Intent.goalSummary);
    });

    test('classifies loan queries', () {
      expect(classifier.classify('Show my loans'), Intent.loanSummary);
      expect(classifier.classify('Outstanding debt'), Intent.loanSummary);
    });

    test('classifies bill queries', () {
      expect(classifier.classify('Upcoming bills'), Intent.billSummary);
      expect(classifier.classify('What is due?'), Intent.billSummary);
    });

    test('classifies learning queries', () {
      expect(classifier.classify('Learning streak'), Intent.learningSummary);
      expect(classifier.classify('How many study days?'), Intent.learningSummary);
    });

    test('classifies advice queries', () {
      expect(classifier.classify('Give me advice'), Intent.financialAdvice);
      expect(classifier.classify('How can I save more?'), Intent.financialAdvice);
    });

    test('returns unknown for unrecognized queries', () {
      expect(classifier.classify('Tell me a joke'), Intent.unknown);
      expect(classifier.classify('What is the weather?'), Intent.unknown);
    });
  });
}
