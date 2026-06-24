import 'package:beltech/core/sync/mpesa_historical_import_scanner.dart';
import 'package:beltech/features/auth/domain/entities/account_session.dart';
import 'package:beltech/features/auth/domain/repositories/account_repository.dart';
import 'package:beltech/features/expenses/domain/repositories/expenses_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockExpensesRepository extends Mock implements ExpensesRepository {}

class MockAccountRepository extends Mock implements AccountRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026, 1, 1));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('runs historical import once per user scope', () async {
    final expensesRepository = MockExpensesRepository();
    final accountRepository = MockAccountRepository();
    when(
      () => accountRepository.currentSession(),
    ).thenReturn(const AccountSession(isAuthenticated: true, userId: 'user-a'));
    when(
      () => expensesRepository.importFromDevice(from: any(named: 'from')),
    ).thenAnswer((_) async => 7);

    final scanner = MpesaHistoricalImportScanner(
      expensesRepository,
      accountRepository,
    );

    final first = await scanner.runOnce();
    final second = await scanner.runOnce();

    expect(first, 7);
    expect(second, 0);
    verify(
      () => expensesRepository.importFromDevice(from: any(named: 'from')),
    ).called(1);
  });

  test('does not mark scan complete when import fails', () async {
    final expensesRepository = MockExpensesRepository();
    final accountRepository = MockAccountRepository();
    when(
      () => accountRepository.currentSession(),
    ).thenReturn(const AccountSession(isAuthenticated: true, userId: 'user-b'));
    when(
      () => expensesRepository.importFromDevice(from: any(named: 'from')),
    ).thenThrow(Exception('permission denied'));

    final scanner = MpesaHistoricalImportScanner(
      expensesRepository,
      accountRepository,
    );

    final first = await scanner.runOnce();
    final second = await scanner.runOnce();

    expect(first, 0);
    expect(second, 0);
    verify(
      () => expensesRepository.importFromDevice(from: any(named: 'from')),
    ).called(2);
  });
}
