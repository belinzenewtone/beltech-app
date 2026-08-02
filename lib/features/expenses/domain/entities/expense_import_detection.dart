import 'package:beltech/features/expenses/domain/entities/expense_import_window.dart';

/// Result of a detect-only SMS scan (no import performed).
///
/// Mirrors the Kotlin `SmsDetectionResult`: the app scans the inbox for the
/// requested time window and filter, counts how many financial messages each
/// institution contributes, and shows that to the user *before* they commit to
/// an import.
class ExpenseImportDetection {
  const ExpenseImportDetection({
    required this.institutionCounts,
    required this.totalMessages,
    required this.permissionGranted,
    required this.window,
    required this.filter,
  });

  /// Count of financial messages per institution id (e.g. `mpesa`, `kcb`).
  final Map<String, int> institutionCounts;

  /// Total financial messages found across all institutions.
  final int totalMessages;

  /// Whether SMS read permission was granted for the scan.
  final bool permissionGranted;

  /// The time window the scan covered.
  final ExpenseImportWindow window;

  /// The provider filter the scan used.
  final ImportSourceFilter filter;

  bool get hasMessages => totalMessages > 0;
}

/// Detects the institution that sent a financial SMS, used for grouping the
/// import preview. Mirrors the Kotlin `InstitutionDetector` mapping.
String detectInstitutionId(String sender, String body) {
  final from = sender.toUpperCase();
  final text = body.toLowerCase();

  // Mobile money
  if (from.contains('MPESA') || text.contains('m-pesa') || text.contains('mpesa')) {
    return 'mpesa';
  }
  if (from.contains('AIRTEL')) return 'airtel';
  if (from.contains('T-KASH') || from.contains('TKASH') || from.contains('TELKOM')) {
    return 'tkash';
  }

  // Tier 1 banks
  if (from.contains('KCB') || from.contains('VOOMA')) return 'kcb';
  if (from.contains('EQUITY') || from.contains('EAZZY')) return 'equity';
  if (from.contains('COOP') || from.contains('MCOOP')) return 'coopbank';
  if (from.contains('NCBA') ||
      from.contains('LOOP') ||
      from.contains('LOOPBANK')) {
    return 'ncba';
  }

  // Tier 2 banks
  if (from.contains('ABSA') || from.contains('BARCLAYS')) return 'absa';
  if (from.contains('STANCHART') ||
      from.contains('SCB') ||
      from.contains('STANDARDCHARTERED')) {
    return 'stanchart';
  }
  if (from.contains('DTB') || from.contains('DIAMONDTRUST')) return 'dtb';
  if (from.contains('FAMILY')) return 'family';
  if (from.contains('I&M') ||
      from.contains('IANDM') ||
      from.contains('IMBANK') ||
      from == 'IM') {
    return 'im';
  }
  if (from.contains('STANBIC')) return 'stanbic';

  // Tier 3 / specialist
  if (from.contains('SBM')) return 'sbm';
  if (from.contains('HF') || from.contains('HFCK')) return 'hfgroup';
  if (from.contains('GULF')) return 'gulf';
  if (from.contains('BOA') || from.contains('BANKOFAFRICA')) return 'boa';
  if (from.contains('PRIMEBANK')) return 'primebank';
  if (from.contains('SIDIAN') || from.contains('KREP')) return 'sidian';
  if (from.contains('KINGDOM') || from.contains('JAMII')) return 'kingdom';
  if (from.contains('CONSOLIDATED') || from.contains('CONSO')) {
    return 'consolidated';
  }
  if (from.contains('CREDITBANK')) return 'creditbank';
  if (from.contains('VICTORIA')) return 'victoria';
  if (from.contains('GUARDIAN')) return 'guardian';
  if (from.contains('TRANSNATIONAL') || from.contains('TNB')) {
    return 'transnational';
  }

  // Interbank / payment networks
  if (from.contains('PESALINK') ||
      from.contains('IPSL') ||
      from.contains('KBAPESALINK')) {
    return 'pesalink';
  }

  return 'other';
}

/// Human-readable display name for an institution id.
String institutionDisplayName(String id) {
  return switch (id) {
    'mpesa' => 'M-Pesa',
    'airtel' => 'Airtel Money',
    'tkash' => 'T-Kash',
    'kcb' => 'KCB',
    'equity' => 'Equity Bank',
    'coopbank' => 'Co-op Bank',
    'ncba' => 'NCBA / Loop',
    'absa' => 'Absa',
    'stanchart' => 'StanChart',
    'dtb' => 'DTB',
    'family' => 'Family Bank',
    'im' => 'I&M Bank',
    'stanbic' => 'Stanbic',
    'sbm' => 'SBM Bank',
    'pesalink' => 'PesaLink',
    'hfgroup' => 'HF Group',
    'gulf' => 'Gulf African Bank',
    'boa' => 'Bank of Africa',
    'primebank' => 'Prime Bank',
    'sidian' => 'Sidian Bank',
    'kingdom' => 'Kingdom Bank',
    'consolidated' => 'Consolidated Bank',
    'creditbank' => 'Credit Bank',
    'victoria' => 'Victoria Bank',
    'guardian' => 'Guardian Bank',
    'transnational' => 'Trans-National Bank',
    'other' => 'Other',
    _ => id,
  };
}
