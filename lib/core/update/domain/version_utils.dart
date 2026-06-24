int compareVersions(String left, String right) {
  final a = _parseVersionParts(left);
  final b = _parseVersionParts(right);
  final length = a.length > b.length ? a.length : b.length;

  for (var index = 0; index < length; index += 1) {
    final leftPart = index < a.length ? a[index] : 0;
    final rightPart = index < b.length ? b[index] : 0;
    if (leftPart > rightPart) {
      return 1;
    }
    if (leftPart < rightPart) {
      return -1;
    }
  }
  return 0;
}

List<int> _parseVersionParts(String value) {
  final normalized = value.trim().toLowerCase();
  final core = normalized.split('-').first;
  return core
      .split('.')
      .map((segment) => int.tryParse(segment.replaceAll(RegExp(r'[^0-9]'), '')))
      .map((part) => part ?? 0)
      .toList();
}
