/// Time window for an SMS import scan (matches the Kotlin reference:
/// 24 hours / 1 month / 3 months / 6 months).
enum ExpenseImportWindow { last24Hours, lastMonth, last3Months, last6Months }

/// Which providers to pull from the inbox — mirrors the Kotlin ParserFilter
/// (M-Pesa only / banks only / both).
enum ImportSourceFilter { mpesa, banks, both }

/// Live progress of an in-flight import, surfaced to the UI as a progress bar.
class ImportProgress {
  const ImportProgress({required this.done, required this.total});

  final int done;
  final int total;

  double get fraction => total <= 0 ? 0 : (done / total).clamp(0.0, 1.0);
  bool get isComplete => total > 0 && done >= total;
}
