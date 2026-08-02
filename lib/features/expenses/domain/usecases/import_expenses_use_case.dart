import 'package:beltech/features/expenses/domain/entities/expense_import_detection.dart';
import 'package:beltech/features/expenses/domain/entities/expense_import_window.dart';
import 'package:beltech/features/expenses/domain/repositories/expenses_repository.dart';

class ImportExpensesUseCase {
  const ImportExpensesUseCase(this._repository);

  final ExpensesRepository _repository;

  Future<int> importRawMessages(
    List<String> rawMessages, {
    DateTime? from,
    void Function(int done, int total)? onProgress,
  }) {
    return _repository.importSmsMessages(
      rawMessages,
      from: from,
      onProgress: onProgress,
    );
  }

  Future<int> importFromDevice({
    DateTime? from,
    ImportSourceFilter filter = ImportSourceFilter.both,
    void Function(int done, int total)? onProgress,
  }) {
    return _repository.importFromDevice(
      from: from,
      filter: filter,
      onProgress: onProgress,
    );
  }

  Future<ExpenseImportDetection> detectFromDevice({
    DateTime? from,
    ImportSourceFilter filter = ImportSourceFilter.both,
  }) {
    return _repository.detectFromDevice(from: from, filter: filter);
  }
}
