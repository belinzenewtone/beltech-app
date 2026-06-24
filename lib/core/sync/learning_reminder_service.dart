import 'package:beltech/core/notifications/local_notification_service.dart';
import 'package:beltech/features/learning/domain/repositories/learning_repository.dart';

/// Checks learning streak and sends encouragement notifications.
class LearningReminderService {
  const LearningReminderService(this._learningRepository, this._notifications);

  final LearningRepository _learningRepository;
  final LocalNotificationService _notifications;

  Future<void> checkAndNotify() async {
    final streak = await _learningRepository.currentStreak();
    if (streak == 0) {
      await _notifications.showLearningReminder(dayOffset: 0);
    } else if (streak >= 7) {
      // Positive reinforcement for good streaks
      await _notifications.showLearningReminder(dayOffset: streak);
    }
  }
}
