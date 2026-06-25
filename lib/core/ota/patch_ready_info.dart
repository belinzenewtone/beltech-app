class PatchReadyInfo {
  const PatchReadyInfo({
    required this.currentPatchNumber,
    required this.nextPatchNumber,
    required this.title,
    required this.message,
    required this.notes,
  });

  final int? currentPatchNumber;
  final int nextPatchNumber;
  final String title;
  final String message;
  final List<String> notes;

  String get patchLabel => 'Patch $nextPatchNumber';
}
