import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/data/services/sms_feature_extractor.dart';
import 'package:beltech/features/expenses/data/services/transaction_decision_tree.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tree = TransactionDecisionTree();
  const extractor = SmsFeatureExtractor();

  group('SmsFeatureExtractor', () {
    test('extracts amount from Ksh message', () {
      const sms =
          'QW12AB34CD Confirmed. Ksh1,250.00 sent to SKY CAFE on 7/3/26 at 6:24 PM. New M-PESA balance is Ksh0.00.';
      final f = extractor.extract(sms);
      expect(f.hasAmount, 1.0);
      expect(f.hasMpesaKeyword, 1.0);
      expect(f.hasTransactionCode, 1.0);
      expect(f.hasDate, 1.0);
    });

    test('detects Fuliza keyword', () {
      const sms =
          'AA12BB34CC Confirmed. Ksh500.00 Fuliza M-PESA amount credited on 8/3/26 at 10:00 AM.';
      final f = extractor.extract(sms);
      expect(f.hasFulizaSignal, 1.0);
      expect(f.hasMpesaKeyword, 1.0);
    });

    test('zero amount gives hasAmount=0', () {
      final f = extractor.extract('No amounts here, hello world');
      expect(f.hasAmount, 0.0);
    });

    test('normBodyLength is 0 for empty string', () {
      final f = extractor.extract('');
      expect(f.normBodyLength, 0.0);
    });

    test('hasBothParties detects sent-to pattern', () {
      const sms = 'Ksh200.00 sent to JOHN DOE on 1/1/26 at 9:00 AM.';
      final f = extractor.extract(sms);
      expect(f.hasBothParties, 1.0);
    });
  });

  group('TransactionDecisionTree.shouldDemote', () {
    const highConfidenceMpesa =
        'QW12AB34CD Confirmed. Ksh1,250.00 sent to SKY CAFE on 7/3/26 at 6:24 PM. New M-PESA balance is Ksh0.00.';

    test('does not demote when parser says medium', () {
      expect(
        tree.shouldDemote(highConfidenceMpesa, MpesaConfidence.medium),
        isFalse,
      );
    });

    test('does not demote when parser says low', () {
      expect(
        tree.shouldDemote(highConfidenceMpesa, MpesaConfidence.low),
        isFalse,
      );
    });

    test('does not demote a high-confidence M-PESA message', () {
      expect(
        tree.shouldDemote(highConfidenceMpesa, MpesaConfidence.high),
        isFalse,
      );
    });

    test('demotes when message has no financial signals (parser=high)', () {
      const suspicious = 'Win a prize! Call now.';
      // The suspicious message has no amount so tree returns LOW.
      // Parser is claimed to be high → shouldDemote returns true.
      expect(
        tree.shouldDemote(suspicious, MpesaConfidence.high),
        isTrue,
      );
    });

    test('does NOT demote Fuliza message (no M-PESA keyword) with code+amount', () {
      const fulizaDraw =
          'AA12BB34CC Confirmed. Ksh500.00 Fuliza M-PESA amount credited on 8/3/26 at 10:00 AM.';
      // Has M-PESA keyword, amount, date → tree says HIGH or MEDIUM, not LOW.
      expect(
        tree.shouldDemote(fulizaDraw, MpesaConfidence.high),
        isFalse,
      );
    });
  });
}
