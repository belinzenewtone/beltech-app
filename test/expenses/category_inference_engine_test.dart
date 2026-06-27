import 'package:beltech/features/expenses/data/services/category_inference_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = CategoryInferenceEngine();

  group('keyword-based inference', () {
    test('detects supermarkets as Food & Dining', () {
      final guess = engine.infer(title: 'NAIVAS SUPERMARKET', amountKes: 2500);
      expect(guess, isNotNull);
      expect(guess!.category, 'Food & Dining');
      expect(guess.confidence, greaterThan(0.8));
    });

    test('detects fuel stations as Transport', () {
      final guess = engine.infer(title: 'SHELL KILIMANI', amountKes: 5000);
      expect(guess, isNotNull);
      expect(guess!.category, 'Transport');
    });

    test('detects KPLC as Bills & Utilities', () {
      final guess = engine.infer(title: 'KPLC PREPAID', amountKes: 1000);
      expect(guess, isNotNull);
      expect(guess!.category, 'Bills & Utilities');
    });

    test('detects delivery apps as Food & Dining', () {
      final guess = engine.infer(title: 'GLOVO', amountKes: 1200);
      expect(guess, isNotNull);
      expect(guess!.category, 'Food & Dining');
    });

    test('returns null for unrecognised merchants', () {
      final guess = engine.infer(title: 'RANDOM XYZ', amountKes: 1000);
      expect(guess, isNull);
    });
  });

  group('amount-aware overrides', () {
    test('airtime keyword with small amount → Airtime', () {
      final guess = engine.infer(title: 'AIRTIME TOPUP', amountKes: 100);
      expect(guess, isNotNull);
      expect(guess!.category, 'Airtime');
      expect(guess.confidence, 0.95);
    });

    test('airtime keyword with large amount is not forced to Airtime', () {
      final guess = engine.infer(title: 'AIRTIME PACKAGE', amountKes: 5000);
      expect(guess, isNull);
    });

    test('fuel keyword always → Transport regardless of amount', () {
      final guess = engine.infer(title: 'TOTAL FUEL', amountKes: 15000);
      expect(guess, isNotNull);
      expect(guess!.category, 'Transport');
      expect(guess.confidence, 0.95);
    });

    test('rent keyword with large amount → Rent', () {
      final guess = engine.infer(title: 'HOUSE RENT', amountKes: 25000);
      expect(guess, isNotNull);
      expect(guess!.category, 'Rent');
      expect(guess.confidence, 0.9);
    });

    test('rent keyword with small amount falls through to keyword/null', () {
      final guess = engine.infer(title: 'RENT BOOK', amountKes: 500);
      // 'rent' is also in Bills & Utilities keyword list, so it matches there.
      expect(guess, isNotNull);
      expect(guess!.category, 'Bills & Utilities');
    });

    test('small amount heuristic → Food & Dining', () {
      final guess = engine.infer(title: 'UNKNOWN MERCHANT', amountKes: 200);
      expect(guess, isNotNull);
      expect(guess!.category, 'Food & Dining');
    });

    test('large amount heuristic → Rent', () {
      final guess = engine.infer(title: 'UNKNOWN MERCHANT', amountKes: 75000);
      expect(guess, isNotNull);
      expect(guess!.category, 'Rent');
    });
  });
}
