import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/data/services/sms_feature_extractor.dart';

/// Lightweight on-device decision tree that provides a second opinion on the
/// confidence level of a parsed M-Pesa transaction.
///
/// Ported from the Kotlin [TransactionDecisionTree] (depth-4, hand-calibrated
/// on Safaricom SMS templates).
///
/// Tree structure:
///   Root: hasAmount? → NO  → LOW
///         YES →
///           hasMpesaKeyword? → YES →
///             hasTransactionCode? → YES →
///               (hasBothParties OR hasFee OR hasDate)? → YES → HIGH
///                                                        NO  → MEDIUM
///             NO →
///               hasDate? → YES → MEDIUM
///                          NO  → LOW
///           NO →
///             hasFulizaSignal? → YES →
///               hasTransactionCode? → YES → MEDIUM
///                                    NO  → LOW
///             NO → LOW
///
/// Demotion rule: tree=LOW + parser=HIGH → demote to MEDIUM (review queue).
/// Only this case triggers a change; all other combinations leave the parser's
/// result unchanged.
class TransactionDecisionTree {
  const TransactionDecisionTree();

  static const _extractor = SmsFeatureExtractor();

  /// Returns true when the tree verdict disagrees with [parserConfidence]
  /// enough to warrant routing to the review queue.
  ///
  /// Only tree=LOW + parser=HIGH triggers a demotion. tree=HIGH + parser=LOW
  /// does NOT upgrade — the parser wins on its own evidence.
  bool shouldDemote(String sms, MpesaConfidence parserConfidence) {
    if (parserConfidence != MpesaConfidence.high) return false;
    final features = _extractor.extract(sms);
    return _evaluate(features) == _TreeVerdict.low;
  }

  _TreeVerdict _evaluate(SmsFeatureVector f) {
    if (f.hasAmount < 0.5) return _TreeVerdict.low;

    if (f.hasMpesaKeyword >= 0.5) {
      if (f.hasTransactionCode >= 0.5) {
        final corroborated =
            f.hasBothParties >= 0.5 || f.hasFee >= 0.5 || f.hasDate >= 0.5;
        return corroborated ? _TreeVerdict.high : _TreeVerdict.medium;
      } else {
        return f.hasDate >= 0.5 ? _TreeVerdict.medium : _TreeVerdict.low;
      }
    } else {
      if (f.hasFulizaSignal >= 0.5) {
        return f.hasTransactionCode >= 0.5
            ? _TreeVerdict.medium
            : _TreeVerdict.low;
      }
      return _TreeVerdict.low;
    }
  }
}

enum _TreeVerdict { high, medium, low }
