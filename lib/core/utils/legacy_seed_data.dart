bool isLegacySeedIncome({
  required String title,
  required String source,
}) {
  return source.trim().toLowerCase() == 'seed' &&
      title.trim().toLowerCase() == 'salary';
}
