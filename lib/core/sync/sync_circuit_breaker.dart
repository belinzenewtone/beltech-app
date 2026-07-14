enum CircuitBreakerState { closed, open, halfOpen }

/// Simple three-state circuit breaker for sync operations.
///
/// CLOSED → normal, attempts allowed.
/// OPEN   → [failureThreshold] consecutive failures seen; attempts blocked for
///           [cooldown] duration.
/// HALF_OPEN → cooldown expired; one probe attempt allowed. Success → CLOSED,
///             failure → OPEN (clock restarted).
class SyncCircuitBreaker {
  SyncCircuitBreaker({
    this.failureThreshold = 5,
    this.cooldown = const Duration(seconds: 60),
  });

  final int failureThreshold;
  final Duration cooldown;

  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  DateTime? _openedAt;

  CircuitBreakerState get state => _state;

  bool get canAttempt {
    switch (_state) {
      case CircuitBreakerState.closed:
        return true;
      case CircuitBreakerState.open:
        final now = DateTime.now();
        if (_openedAt != null && now.difference(_openedAt!) >= cooldown) {
          _state = CircuitBreakerState.halfOpen;
          return true;
        }
        return false;
      case CircuitBreakerState.halfOpen:
        return true;
    }
  }

  void recordSuccess() {
    _failureCount = 0;
    _state = CircuitBreakerState.closed;
    _openedAt = null;
  }

  void recordFailure() {
    _failureCount++;
    if (_state == CircuitBreakerState.halfOpen ||
        _failureCount >= failureThreshold) {
      _state = CircuitBreakerState.open;
      _openedAt = DateTime.now();
      _failureCount = 0;
    }
  }

  void reset() {
    _state = CircuitBreakerState.closed;
    _failureCount = 0;
    _openedAt = null;
  }
}
