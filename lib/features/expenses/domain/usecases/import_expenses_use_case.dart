import 'package:beltech/features/expenses/domain/repositories/expenses_repository.dart';

class ImportExpensesUseCase {
  const ImportExpensesUseCase(this._repository);

  final ExpensesRepository _repository;

  Future<int> importRawMessages(List<String> rawMessages, {DateTime? from}) {
    return _repository.importSmsMessages(rawMessages, from: from);
  }

  Future<int> importFromDevice({DateTime? from}) {
    return _repository.importFromDevice(from: from);
  }
}
