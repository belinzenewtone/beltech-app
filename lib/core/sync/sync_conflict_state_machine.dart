/// Sync conflict resolution state machine.
///
/// Implements a 7-state conflict resolution model for data synchronization
/// between local and remote sources. This ensures deterministic handling of
/// concurrent updates, network failures, and delete conflicts.

/// Sync state enum defining the lifecycle of a synced entity.
enum SyncConflictState {
  /// Entity exists only locally, never synced.
  localOnly,

  /// Entity queued for sync, waiting for network availability.
  queued,

  /// Sync in progress; upload to remote in flight.
  syncing,

  /// Successfully synced to remote; local and remote in agreement.
  synced,

  /// Sync failed (network error, validation rejection, conflict); queued for retry.
  failed,

  /// Local and remote versions conflict; manual intervention or resolution rule applied.
  conflict,

  /// Entity deleted locally; marked for deletion on remote (soft delete).
  tombstoned,
}

/// Represents the result of conflict resolution.
class SyncConflictResolution {
  final SyncConflictState resultState;
  final String? conflictReason;
  final bool localWins;
  final DateTime resolvedAt;

  SyncConflictResolution({
    required this.resultState,
    this.conflictReason,
    required this.localWins,
    required this.resolvedAt,
  });
}

/// Sync conflict resolver implementing deterministic resolution rules.
class SyncConflictResolver {
  /// Resolve a conflict between local and remote versions.
  ///
  /// Rules (in order):
  /// 1. If local newer than remote → local wins (remote will re-sync next cycle)
  /// 2. If remote newer than local → remote wins (merge into local, mark for audit)
  /// 3. If both deleted → tombstone (mark for cleanup)
  /// 4. If one deleted, one exists → conflict (manual intervention required)
  /// 5. If user-scoped keys differ → conflict (data ownership mismatch)
  SyncConflictResolution resolve({
    required DateTime localTimestamp,
    required DateTime remoteTimestamp,
    required bool isLocalDeleted,
    required bool isRemoteDeleted,
    required String? localUserScopeKey,
    required String? remoteUserScopeKey,
  }) {
    // Rule 1: Both deleted → tombstone
    if (isLocalDeleted && isRemoteDeleted) {
      return SyncConflictResolution(
        resultState: SyncConflictState.tombstoned,
        conflictReason: 'Both versions deleted; marked for cleanup.',
        localWins: false,
        resolvedAt: DateTime.now(),
      );
    }

    // Rule 2: Delete conflict → conflict (manual intervention)
    if (isLocalDeleted != isRemoteDeleted) {
      return SyncConflictResolution(
        resultState: SyncConflictState.conflict,
        conflictReason: isLocalDeleted
            ? 'Local deleted, remote exists; delete confirmed remotely?'
            : 'Remote deleted, local exists; accept remote deletion?',
        localWins: !isRemoteDeleted,
        resolvedAt: DateTime.now(),
      );
    }

    // Rule 3: User scope mismatch → conflict
    if (localUserScopeKey != remoteUserScopeKey) {
      return SyncConflictResolution(
        resultState: SyncConflictState.conflict,
        conflictReason:
            'User scope key mismatch: local=$localUserScopeKey, remote=$remoteUserScopeKey',
        localWins: false,
        resolvedAt: DateTime.now(),
      );
    }

    // Rule 4: Last-write-wins for non-deleted entities
    final localNewer = localTimestamp.isAfter(remoteTimestamp);
    final remoteNewer = remoteTimestamp.isAfter(localTimestamp);

    if (localNewer) {
      return SyncConflictResolution(
        resultState: SyncConflictState.syncing, // Re-queue for upload
        conflictReason: 'Local version newer; re-syncing to remote.',
        localWins: true,
        resolvedAt: DateTime.now(),
      );
    } else if (remoteNewer) {
      return SyncConflictResolution(
        resultState: SyncConflictState.synced, // Merge remote into local
        conflictReason: 'Remote version newer; merged into local.',
        localWins: false,
        resolvedAt: DateTime.now(),
      );
    } else {
      // Same timestamp → tie-breaker: local wins to preserve user intent
      return SyncConflictResolution(
        resultState: SyncConflictState.queued,
        conflictReason: 'Same timestamp; local version queued for re-sync.',
        localWins: true,
        resolvedAt: DateTime.now(),
      );
    }
  }

  /// Determine next state transition given current state and network condition.
  ///
  /// State machine transitions:
  /// - localOnly + user action → queued
  /// - queued + network → syncing
  /// - syncing + success → synced
  /// - syncing + failure → failed
  /// - failed + retry → queued
  /// - synced + local edit → queued
  /// - any + delete action → tombstoned
  SyncConflictState nextState({
    required SyncConflictState currentState,
    required bool networkAvailable,
    required bool operationSucceeded,
    required bool isDeleted,
  }) {
    if (isDeleted) return SyncConflictState.tombstoned;

    switch (currentState) {
      case SyncConflictState.localOnly:
        return networkAvailable ? SyncConflictState.queued : SyncConflictState.localOnly;
      case SyncConflictState.queued:
        return networkAvailable ? SyncConflictState.syncing : SyncConflictState.queued;
      case SyncConflictState.syncing:
        return operationSucceeded ? SyncConflictState.synced : SyncConflictState.failed;
      case SyncConflictState.synced:
        return SyncConflictState.synced;
      case SyncConflictState.failed:
        return networkAvailable ? SyncConflictState.queued : SyncConflictState.failed;
      case SyncConflictState.conflict:
        return SyncConflictState.conflict; // Awaits manual resolution
      case SyncConflictState.tombstoned:
        return SyncConflictState.tombstoned;
    }
  }
}
