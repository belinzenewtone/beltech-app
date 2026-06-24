import 'package:beltech/features/expenses/domain/entities/expense.dart';
import 'package:beltech/features/recurring/data/services/recurring_materializer_service.dart';
import 'package:beltech/features/recurring/domain/entities/recurring_rule.dart';
import 'package:beltech/features/recurring/domain/repositories/recurring_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRecurringRepository extends Mock implements RecurringRepository {}

void main() {
  late RecurringMaterializerService service;
  late MockRecurringRepository mockRepository;

  setUp(() {
    mockRepository = MockRecurringRepository();
    service = RecurringMaterializerService(mockRepository);
  });

  group('RecurringMaterializerService', () {
    test('materializes due rules', () async {
      when(() => mockRepository.getActiveRecurringRules())
          .thenAnswer((_) async => []);

      final created = await service.materializeDueRecurring();
      expect(created, isNotEmpty);
    });

    test('syncNow handles errors gracefully', () async {
      when(() => mockRepository.getActiveRecurringRules())
          .thenThrow(Exception('Database error'));

      await service.syncNow();
    });
  });
}
