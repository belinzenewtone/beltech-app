import 'package:beltech/features/recurring/data/services/recurring_materializer_service.dart';
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
    test('syncNow delegates to repository materializeDue', () async {
      when(() => mockRepository.materializeDue()).thenAnswer((_) async => 1);

      await service.syncNow();

      verify(() => mockRepository.materializeDue()).called(1);
    });

    test('syncNow handles errors gracefully', () async {
      when(
        () => mockRepository.materializeDue(),
      ).thenThrow(Exception('Database error'));

      await expectLater(service.syncNow(), completes);
    });
  });
}
