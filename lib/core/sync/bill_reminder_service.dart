import 'package:beltech/core/notifications/local_notification_service.dart';
import 'package:beltech/features/bills/domain/repositories/bills_repository.dart';

/// Checks for upcoming/overdue bills and sends local notifications.
class BillReminderService {
  const BillReminderService(this._billsRepository, this._notifications);

  final BillsRepository _billsRepository;
  final LocalNotificationService _notifications;

  Future<void> checkAndNotify() async {
    final bills = await _billsRepository.loadBills();
    final now = DateTime.now();
    for (final bill in bills.where((b) => !b.paid)) {
      final daysUntil = bill.dueDate.difference(now).inDays;
      // Notify for bills due within 3 days or overdue
      if (daysUntil <= 3) {
        await _notifications.showBillReminder(
          billId: bill.id,
          billName: bill.name,
          amount: bill.amount,
          daysUntil: daysUntil,
        );
      }
    }
  }
}
