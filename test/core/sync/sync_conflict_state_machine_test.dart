import 'package:flutter_test/flutter_test.dart';
import 'package:beltech_app/core/sync/sync_conflict_state_machine.dart';

void main() {
  group('SyncConflictResolver', () {
    late SyncConflictResolver resolver;

    setUp(() {
      resolver = SyncConflictResolver();
    });

    group('resolve()', () {
      test('both deleted → tombstoned', () {
        final resolution = resolver.resolve(
          localTimestamp: DateTime(2026, 6, 24),
          remoteTimestamp: DateTime(2026, 6, 24),
          isLocalDeleted: true,
          isRemoteDeleted: true,
          localUserScopeKey: 'user123',
          remoteUserScopeKey: 'user123',
        );

        expect(resolution.resultState, SyncConflictState.tombstoned);
        expect(resolution.conflictReason, contains('Both versions deleted'));
      });

      test('local deleted, remote exists → conflict', () {
        final resolution = resolver.resolve(
          localTimestamp: DateTime(2026, 6, 24),
          remoteTimestamp: DateTime(2026, 6, 24),
          isLocalDeleted: true,
          isRemoteDeleted: false,
          localUserScopeKey: 'user123',
          remoteUserScopeKey: 'user123',
        );

        expect(resolution.resultState, SyncConflictState.conflict);
        expect(resolution.localWins, false);
      });

      test('remote deleted, local exists → conflict (local wins)', () {
        final resolution = resolver.resolve(
          localTimestamp: DateTime(2026, 6, 24),
          remoteTimestamp: DateTime(2026, 6, 24),
          isLocalDeleted: false,
          isRemoteDeleted: true,
          localUserScopeKey: 'user123',
          remoteUserScopeKey: 'user123',
        );

        expect(resolution.resultState, SyncConflictState.conflict);
        expect(resolution.localWins, true);
      });

      test('user scope key mismatch → conflict', () {
        final resolution = resolver.resolve(
          localTimestamp: DateTime(2026, 6, 24),
          remoteTimestamp: DateTime(2026, 6, 24),
          isLocalDeleted: false,
          isRemoteDeleted: false,
          localUserScopeKey: 'user123',
          remoteUserScopeKey: 'user456',
        );

        expect(resolution.resultState, SyncConflictState.conflict);
        expect(resolution.conflictReason, contains('User scope key mismatch'));
      });

      test('local newer → local wins', () {
        final resolution = resolver.resolve(
          localTimestamp: DateTime(2026, 6, 25),
          remoteTimestamp: DateTime(2026, 6, 24),
          isLocalDeleted: false,
          isRemoteDeleted: false,
          localUserScopeKey: 'user123',
          remoteUserScopeKey: 'user123',
        );

        expect(resolution.resultState, SyncConflictState.syncing);
        expect(resolution.localWins, true);
      });

      test('remote newer → remote wins', () {
        final resolution = resolver.resolve(
          localTimestamp: DateTime(2026, 6, 24),
          remoteTimestamp: DateTime(2026, 6, 25),
          isLocalDeleted: false,
          isRemoteDeleted: false,
          localUserScopeKey: 'user123',
          remoteUserScopeKey: 'user123',
        );

        expect(resolution.resultState, SyncConflictState.synced);
        expect(resolution.localWins, false);
      });

      test('same timestamp → local wins (tie-breaker)', () {
        final now = DateTime(2026, 6, 24);
        final resolution = resolver.resolve(
          localTimestamp: now,
          remoteTimestamp: now,
          isLocalDeleted: false,
          isRemoteDeleted: false,
          localUserScopeKey: 'user123',
          remoteUserScopeKey: 'user123',
        );

        expect(resolution.resultState, SyncConflictState.queued);
        expect(resolution.localWins, true);
      });
    });

    group('nextState()', () {
      test('localOnly + network available → queued', () {
        final next = resolver.nextState(
          currentState: SyncConflictState.localOnly,
          networkAvailable: true,
          operationSucceeded: false,
          isDeleted: false,
        );
        expect(next, SyncConflictState.queued);
      });

      test('localOnly + no network → stays localOnly', () {
        final next = resolver.nextState(
          currentState: SyncConflictState.localOnly,
          networkAvailable: false,
          operationSucceeded: false,
          isDeleted: false,
        );
        expect(next, SyncConflictState.localOnly);
      });

      test('queued + network → syncing', () {
        final next = resolver.nextState(
          currentState: SyncConflictState.queued,
          networkAvailable: true,
          operationSucceeded: false,
          isDeleted: false,
        );
        expect(next, SyncConflictState.syncing);
      });

      test('syncing + success → synced', () {
        final next = resolver.nextState(
          currentState: SyncConflictState.syncing,
          networkAvailable: true,
          operationSucceeded: true,
          isDeleted: false,
        );
        expect(next, SyncConflictState.synced);
      });

      test('syncing + failure → failed', () {
        final next = resolver.nextState(
          currentState: SyncConflictState.syncing,
          networkAvailable: true,
          operationSucceeded: false,
          isDeleted: false,
        );
        expect(next, SyncConflictState.failed);
      });

      test('failed + network → queued (retry)', () {
        final next = resolver.nextState(
          currentState: SyncConflictState.failed,
          networkAvailable: true,
          operationSucceeded: false,
          isDeleted: false,
        );
        expect(next, SyncConflictState.queued);
      });

      test('any state + deleted → tombstoned', () {
        final states = [
          SyncConflictState.localOnly,
          SyncConflictState.queued,
          SyncConflictState.syncing,
          SyncConflictState.synced,
          SyncConflictState.failed,
          SyncConflictState.conflict,
        ];

        for (final state in states) {
          final next = resolver.nextState(
            currentState: state,
            networkAvailable: false,
            operationSucceeded: false,
            isDeleted: true,
          );
          expect(next, SyncConflictState.tombstoned);
        }
      });
    });
  });
}
