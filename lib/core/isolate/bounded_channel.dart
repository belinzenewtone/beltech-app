import 'dart:async';
import 'dart:collection';

/// A capacity-bounded async queue for back-pressure (Phase P2).
///
/// The SMS reader (producer) can enumerate an inbox far faster than the parser
/// pool + DB writer (consumer) can drain it. Without a bound, a 50k inbox piles
/// up in memory. A [BoundedChannel] makes `send` **await** once `capacity`
/// items are buffered, so the producer is throttled to the consumer's pace and
/// memory stays flat regardless of inbox size.
///
/// Single-producer / single-consumer. Call [close] when the producer is done;
/// [receive] returns `null` once the channel is closed and drained.
class BoundedChannel<T> {
  BoundedChannel({this.capacity = 4})
    : assert(capacity > 0, 'capacity must be > 0');

  final int capacity;

  final Queue<T> _buffer = Queue<T>();
  final Queue<Completer<void>> _sendWaiters = Queue<Completer<void>>();
  Completer<void>? _receiveWaiter;
  bool _closed = false;

  int get length => _buffer.length;
  bool get isClosed => _closed;

  /// Enqueue an item, awaiting if the buffer is full. Throws if closed.
  Future<void> send(T item) async {
    if (_closed) {
      throw StateError('Cannot send on a closed BoundedChannel');
    }
    while (_buffer.length >= capacity) {
      final waiter = Completer<void>();
      _sendWaiters.add(waiter);
      await waiter.future;
      if (_closed) {
        throw StateError('Channel closed while awaiting capacity');
      }
    }
    _buffer.add(item);
    _wakeReceiver();
  }

  /// Dequeue the next item, awaiting if empty. Returns `null` when the channel
  /// is closed and fully drained.
  Future<T?> receive() async {
    while (_buffer.isEmpty) {
      if (_closed) return null;
      final waiter = Completer<void>();
      _receiveWaiter = waiter;
      await waiter.future;
    }
    final item = _buffer.removeFirst();
    _wakeSender();
    return item;
  }

  /// Consume the channel as a stream until closed and drained.
  Stream<T> stream() async* {
    while (true) {
      final item = await receive();
      if (item == null && _closed && _buffer.isEmpty) return;
      if (item != null) yield item;
    }
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _wakeReceiver();
    // Release any producers blocked on capacity so they can observe the close.
    while (_sendWaiters.isNotEmpty) {
      _sendWaiters.removeFirst().complete();
    }
  }

  void _wakeReceiver() {
    final waiter = _receiveWaiter;
    if (waiter != null && !waiter.isCompleted) {
      _receiveWaiter = null;
      waiter.complete();
    }
  }

  void _wakeSender() {
    if (_sendWaiters.isNotEmpty) {
      _sendWaiters.removeFirst().complete();
    }
  }
}
