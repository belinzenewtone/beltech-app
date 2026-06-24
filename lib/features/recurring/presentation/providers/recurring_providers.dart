import 'dart:async';

import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/recurring/domain/entities/recurring_template.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final recurringTemplatesProvider = StreamProvider<List<RecurringTemplate>>(
  (ref) => ref.watch(recurringRepositoryProvider).watchTemplates(),
);

class RecurringWriteController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> addTemplate({
    required RecurringKind kind,
    required String title,
    String? description,
    String? category,
    double? amountKes,
    String? priority,
    required RecurringCadence cadence,
    required DateTime nextRunAt,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(recurringRepositoryProvider).addTemplate(
            kind: kind,
            title: title,
            description: description,
            category: category,
            amountKes: amountKes,
            priority: priority,
            cadence: cadence,
            nextRunAt: nextRunAt,
          );
    });
  }

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
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(recurringRepositoryProvider).updateTemplate(
            templateId: templateId,
            kind: kind,
            title: title,
            description: description,
            category: category,
            amountKes: amountKes,
            priority: priority,
            cadence: cadence,
            nextRunAt: nextRunAt,
            enabled: enabled,
          );
    });
  }

  Future<void> toggleEnabled(RecurringTemplate template) async {
    await updateTemplate(
      templateId: template.id,
      kind: template.kind,
      title: template.title,
      description: template.description,
      category: template.category,
      amountKes: template.amountKes,
      priority: template.priority,
      cadence: template.cadence,
      nextRunAt: template.nextRunAt,
      enabled: !template.enabled,
    );
  }

  Future<void> deleteTemplate(int templateId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(recurringRepositoryProvider).deleteTemplate(templateId);
    });
  }

  Future<int> materializeNow() async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(recurringRepositoryProvider).materializeDue(),
    );
    if (result.hasError) {
      state =
          AsyncError(result.error!, result.stackTrace ?? StackTrace.current);
      throw result.error!;
    }
    state = const AsyncData(null);
    return result.valueOrNull ?? 0;
  }
}

final recurringWriteControllerProvider =
    AutoDisposeAsyncNotifierProvider<RecurringWriteController, void>(
  RecurringWriteController.new,
);
