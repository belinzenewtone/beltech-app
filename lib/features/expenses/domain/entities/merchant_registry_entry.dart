/// A learned merchant entry from the unified merchant registry.
class MerchantRegistryEntry {
  const MerchantRegistryEntry({
    required this.merchantKey,
    required this.category,
    required this.usageCount,
    required this.updatedAt,
  });

  /// Normalized merchant key used for matching.
  final String merchantKey;

  /// Learned category for this merchant.
  final String category;

  /// How many times this merchant has been seen/confirmed.
  final int usageCount;

  /// When the entry was last updated.
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MerchantRegistryEntry &&
          runtimeType == other.runtimeType &&
          merchantKey == other.merchantKey &&
          category == other.category &&
          usageCount == other.usageCount &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    merchantKey,
    category,
    usageCount,
    updatedAt,
  );
}
