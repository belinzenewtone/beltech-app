import 'dart:async';
import 'dart:collection';
import 'dart:io' show Platform;
import 'dart:isolate';

import 'package:beltech/features/expenses/data/services/mpesa_parser_models.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';

/// A pool of long-lived worker isolates for parsing SMS batches (Phase P2).
///
/// The old path spawned a fresh isolate per 100-row chunk via `Isolate.run`,
/// paying spawn/teardown cost hundreds of times during a large import. This
/// pool spawns `min(cores, 8)` workers **once**, then streams chunks through
/// them, so a 50k import reuses the same isolates end to end. Parsing is pure
/// and CPU-bound, so throughput scales with cores while the UI thread is free.
///
/// Results are always returned **1:1 aligned** with the input: `parseAll(jobs)`
/// preserves order regardless of which worker finishes first, so callers can
/// keep mapping results back to their source rows positionally.
class ParseIsolatePool {
  ParseIsolatePool({int? workers})
    : _targetWorkers = _resolveWorkerCount(workers);

  final int _targetWorkers;

  final ReceivePort _fromWorkers = ReceivePort();
  StreamSubscription<dynamic>? _sub;
  final List<Isolate> _isolates = [];
  final Map<int, SendPort> _command = {};
  final Queue<int> _idle = Queue<int>();
  final Queue<_Task> _pending = Queue<_Task>();
  final Map<int, Completer<List<ParsedMpesaCandidate?>>> _inflight = {};

  bool _started = false;
  bool _disposed = false;
  int _seq = 0;

  static int _resolveWorkerCount(int? requested) {
    if (requested != null && requested > 0) return requested;
    var cores = 4;
    try {
      cores = Platform.numberOfProcessors;
    } catch (_) {
      // Web / restricted platforms: fall back to a sensible default.
    }
    // Leave headroom for the UI + DB-writer threads; cap the fan-out.
    return (cores - 2).clamp(1, 8);
  }

  int get workerCount => _targetWorkers;
  bool get isStarted => _started;

  Future<void> _ensureStarted() async {
    // Check disposed FIRST — a disposed pool that had started would otherwise
    // pass the `_started` early-return and later strand tasks (dead workers).
    if (_disposed) {
      throw StateError('ParseIsolatePool has been disposed');
    }
    if (_started) return;
    _started = true;
    _sub = _fromWorkers.listen(_onMessage);

    final ready = List.generate(_targetWorkers, (_) => Completer<void>());
    _readyCompleters = ready;
    try {
      for (var i = 0; i < _targetWorkers; i++) {
        _isolates.add(
          await Isolate.spawn(
            _workerMain,
            _WorkerInit(_fromWorkers.sendPort, i),
            debugName: 'parse-worker-$i',
          ),
        );
      }
      await Future.wait(ready.map((c) => c.future));
    } catch (_) {
      // Mid-spawn failure: tear down whatever started so the pool doesn't wedge
      // in a half-initialized state, then surface the error.
      await dispose();
      rethrow;
    }
  }

  late List<Completer<void>> _readyCompleters;

  void _onMessage(dynamic message) {
    if (message is _WorkerReady) {
      _command[message.workerId] = message.commandPort;
      _idle.add(message.workerId);
      _readyCompleters[message.workerId].complete();
      _pump(); // dispatch anything queued before this worker came online
      return;
    }
    if (message is _ParseResponse) {
      final completer = _inflight.remove(message.taskId);
      _idle.add(message.workerId);
      completer?.complete(message.results);
      _pump();
    }
  }

  void _pump() {
    while (_idle.isNotEmpty && _pending.isNotEmpty) {
      final task = _pending.removeFirst();
      final workerId = _idle.removeFirst();
      _command[workerId]!.send(
        _ParseRequest(workerId, task.id, task.jobs),
      );
    }
  }

  /// Parse a single chunk on the next free worker. Aligned 1:1 with [jobs].
  Future<List<ParsedMpesaCandidate?>> parseChunk(List<SmsParseJob> jobs) async {
    if (_disposed) throw StateError('ParseIsolatePool has been disposed');
    if (jobs.isEmpty) return const [];
    await _ensureStarted();
    final id = _seq++;
    final completer = Completer<List<ParsedMpesaCandidate?>>();
    _inflight[id] = completer;
    _pending.add(_Task(id, jobs));
    _pump();
    return completer.future;
  }

  /// Parse an entire batch, chunked across the pool. The returned list is
  /// aligned 1:1 with [jobs] in the original order (chunk order is preserved by
  /// [Future.wait] regardless of completion order).
  Future<List<ParsedMpesaCandidate?>> parseAll(
    List<SmsParseJob> jobs, {
    int chunkSize = 200,
  }) async {
    if (jobs.isEmpty) return const [];
    await _ensureStarted();
    final chunks = <List<SmsParseJob>>[];
    for (var i = 0; i < jobs.length; i += chunkSize) {
      final end = (i + chunkSize) < jobs.length ? i + chunkSize : jobs.length;
      chunks.add(jobs.sublist(i, end));
    }
    final parsed = await Future.wait(chunks.map(parseChunk));
    return parsed.expand((chunk) => chunk).toList(growable: false);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final port in _command.values) {
      port.send(null); // shutdown sentinel — worker calls Isolate.exit()
    }
    // Fail any tasks still in flight so awaiters don't hang forever.
    for (final completer in _inflight.values) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('ParseIsolatePool disposed'));
      }
    }
    _inflight.clear();
    _pending.clear();
    await _sub?.cancel();
    _fromWorkers.close();
    for (final isolate in _isolates) {
      isolate.kill(priority: Isolate.immediate);
    }
    _isolates.clear();
    _command.clear();
    _idle.clear();
  }
}

// ── Isolate worker ───────────────────────────────────────────────────────────

void _workerMain(_WorkerInit init) {
  final commands = ReceivePort();
  init.toPool.send(_WorkerReady(init.workerId, commands.sendPort));
  commands.listen((message) {
    if (message == null) {
      commands.close();
      Isolate.exit();
    }
    final request = message as _ParseRequest;
    final results = MpesaParserService.parseJobsAlignedSync(request.jobs);
    init.toPool.send(
      _ParseResponse(request.workerId, request.taskId, results),
    );
  });
}

// ── Messages (must be top-level & sendable across isolates) ──────────────────

class _WorkerInit {
  const _WorkerInit(this.toPool, this.workerId);
  final SendPort toPool;
  final int workerId;
}

class _WorkerReady {
  const _WorkerReady(this.workerId, this.commandPort);
  final int workerId;
  final SendPort commandPort;
}

class _ParseRequest {
  const _ParseRequest(this.workerId, this.taskId, this.jobs);
  final int workerId;
  final int taskId;
  final List<SmsParseJob> jobs;
}

class _ParseResponse {
  const _ParseResponse(this.workerId, this.taskId, this.results);
  final int workerId;
  final int taskId;
  final List<ParsedMpesaCandidate?> results;
}

class _Task {
  const _Task(this.id, this.jobs);
  final int id;
  final List<SmsParseJob> jobs;
}
