import 'package:beltech/features/recurring/domain/entities/recurring_template.dart';

abstract class RecurringRepository {
  Stream<List<RecurringTemplate>> watchTemplates();

  Future<void> addTemplate({
    required RecurringKind kind,
    required String title,
    String? description,
    String? category,
    double? amountKes,
    String? priority,
    required RecurringCadence cadence,
    required DateTime nextRunAt,
    bool enabled = true,
  });

  Future<void> updateTemplate({
    required int templateId,
    required RecurringKind kind,
    required String title,
    String? description,
    String? category,
    double? amountKes,
    String? priority,
    required RecurringCadence cadence,
    required DateTime nextRunAt,
    required bool enabled,
  });

  Future<void> deleteTemplate(int templateId);

  Future<int> materializeDue({DateTime? now});
}
