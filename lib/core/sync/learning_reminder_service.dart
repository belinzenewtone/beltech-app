import 'package:beltech/core/notifications/local_notification_service.dart';
import 'package:beltech/features/learning/domain/repositories/learning_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Checks learning streak and sends encouragement notifications.
class LearningReminderService {
  const LearningReminderService(this._learningRepository, this._notifications);

  final LearningRepository _learningRepository;
  final LocalNotificationService _notifications;

  static const String _lastShownKey = 'learning_reminder_last_shown_date';

  Future<void> checkAndNotify() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    if (prefs.getString(_lastShownKey) == today) {
      return; // already shown a learning reminder today
    }

    final streak = await _learningRepository.currentStreak();
    if (streak == 0) {
      await _notifications.showLearningReminder(dayOffset: 0);
      await prefs.setString(_lastShownKey, today);
    } else if (streak >= 7) {
      await _notifications.showLearningReminder(dayOffset: streak);
      await prefs.setString(_lastShownKey, today);
    }
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
