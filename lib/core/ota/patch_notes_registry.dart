import 'package:beltech/core/ota/patch_ready_info.dart';

PatchReadyInfo patchReadyInfoFor({
  required int? currentPatchNumber,
  required int nextPatchNumber,
}) {
  final (title, message, notes) = switch (nextPatchNumber) {
    1 => (
        'Update Ready',
        'A background update has been downloaded and is ready to install.',
        const [
          'Refined the quick action and tool hub shortcut layout.',
          'Simplified the sign in and sign up intro area.',
        ],
      ),
    2 => (
        'A Better Update Is Ready',
        'This update improves the in-app update experience and makes it available from login too.',
        const [
          'Replaced the thin top banner with a cleaner update prompt.',
          'Added clearer release notes and a larger restart action.',
          'Enabled update prompts on the sign in and sign up screen.',
        ],
      ),
    3 => (
        'Update Ready',
        'A small follow-up update is ready to install.',
        const [
          'Fixed the restart action so it relaunches the app on Android.',
          'Kept the improved update prompt and login-screen visibility.',
        ],
      ),
    _ => (
        'Update Ready',
        'A background update has been downloaded and will apply after a full app restart.',
        [
          'Patch $nextPatchNumber is ready to install.',
          'Restart the app to switch to the latest improvements.',
        ],
      ),
  };

  return PatchReadyInfo(
    currentPatchNumber: currentPatchNumber,
    nextPatchNumber: nextPatchNumber,
    title: title,
    message: message,
    notes: notes,
  );
}
