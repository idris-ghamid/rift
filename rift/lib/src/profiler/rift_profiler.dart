/// Performance profiler for Rift database operations.
/// Tracks timing, memory, and throughput metrics.
class RiftProfiler {
  final Map<String, _OperationStats> _stats = {};
  bool _enabled = false;

  /// Whether the profiler is currently enabled.
  bool get isEnabled => _enabled;

  /// Enable the profiler.
  void enable() {
    _enabled = true;
  }

  /// Disable the profiler.
  void disable() {
    _enabled = false;
  }

  /// Record an operation timing.
  void record(String operation, Duration elapsed, {bool success = true}) {
    if (!_enabled) return;
    final stats = _stats.putIfAbsent(
      operation,
      () => _OperationStats(operation),
    );
    stats.record(elapsed, success: success);
  }

  /// Time an async operation.
  Future<T> time<T>(String operation, Future<T> Function() fn) async {
    if (!_enabled) return fn();
    final sw = Stopwatch()..start();
    try {
      final result = await fn();
      sw.stop();
      record(operation, sw.elapsed, success: true);
      return result;
    } catch (e) {
      sw.stop();
      record(operation, sw.elapsed, success: false);
      rethrow;
    }
  }

  /// Time a synchronous operation.
  T timeSync<T>(String operation, T Function() fn) {
    if (!_enabled) return fn();
    final sw = Stopwatch()..start();
    try {
      final result = fn();
      sw.stop();
      record(operation, sw.elapsed, success: true);
      return result;
    } catch (e) {
      sw.stop();
      record(operation, sw.elapsed, success: false);
      rethrow;
    }
  }

  /// Get statistics for an operation.
  _OperationStats? getStats(String operation) => _stats[operation];

  /// Get all operation statistics.
  Map<String, _OperationStats> get allStats => Map.unmodifiable(_stats);

  /// Generate a performance report.
  ProfilerReport generateReport() {
    final operations = <String, Map<String, dynamic>>{};
    int totalOps = 0;
    int totalFailures = 0;
    Duration totalTime = Duration.zero;

    for (final entry in _stats.entries) {
      final stats = entry.value;
      operations[entry.key] = {
        'count': stats._count,
        'failures': stats._failures,
        'totalTimeMs': stats._totalTime.inMicroseconds / 1000,
        'avgTimeMs': stats.averageTime.inMicroseconds / 1000,
        'minTimeMs': stats.minTime.inMicroseconds / 1000,
        'maxTimeMs': stats.maxTime.inMicroseconds / 1000,
        'failureRate': stats.failureRate,
        'throughput': stats.throughput,
        'p50Ms': stats.percentile(50).inMicroseconds / 1000,
        'p95Ms': stats.percentile(95).inMicroseconds / 1000,
        'p99Ms': stats.percentile(99).inMicroseconds / 1000,
      };
      totalOps += stats._count;
      totalFailures += stats._failures;
      totalTime += stats._totalTime;
    }

    final summary = <String, dynamic>{
      'totalOperations': totalOps,
      'totalFailures': totalFailures,
      'totalTimeMs': totalTime.inMicroseconds / 1000,
      'overallFailureRate': totalOps > 0 ? totalFailures / totalOps : 0,
      'operationTypes': _stats.length,
      'enabled': _enabled,
    };

    return ProfilerReport(
      generatedAt: DateTime.now(),
      operations: operations,
      summary: summary,
    );
  }

  /// Reset all statistics.
  void reset() {
    _stats.clear();
  }
}

/// Statistics for a single operation type.
class _OperationStats {
  final String operation;
  int _count = 0;
  int _failures = 0;
  Duration _totalTime = Duration.zero;
  Duration _minTime = const Duration(days: 999);
  Duration _maxTime = Duration.zero;
  final List<Duration> _recentTimes = []; // last 100

  _OperationStats(this.operation);

  void record(Duration elapsed, {bool success = true}) {
    _count++;
    if (!success) _failures++;
    _totalTime += elapsed;
    if (elapsed < _minTime) _minTime = elapsed;
    if (elapsed > _maxTime) _maxTime = elapsed;
    _recentTimes.add(elapsed);
    if (_recentTimes.length > 100) _recentTimes.removeAt(0);
  }

  /// Average time per operation.
  Duration get averageTime => _count > 0
      ? Duration(microseconds: _totalTime.inMicroseconds ~/ _count)
      : Duration.zero;

  /// Minimum recorded time.
  Duration get minTime =>
      _minTime == const Duration(days: 999) ? Duration.zero : _minTime;

  /// Maximum recorded time.
  Duration get maxTime => _maxTime;

  /// Failure rate (0.0 to 1.0).
  double get failureRate => _count > 0 ? _failures / _count : 0;

  /// Operations per second.
  double get throughput =>
      _totalTime.inSeconds > 0 ? _count / _totalTime.inSeconds : 0;

  /// Calculate the percentile time.
  Duration percentile(int p) {
    if (_recentTimes.isEmpty) return Duration.zero;
    final sorted = List<Duration>.from(_recentTimes)..sort();
    final index = (p / 100 * sorted.length).floor().clamp(0, sorted.length - 1);
    return sorted[index];
  }

  /// Total operation count.
  int get count => _count;

  /// Total failure count.
  int get failures => _failures;

  /// Total time spent.
  Duration get totalTime => _totalTime;
}

/// A performance report generated by the profiler.
class ProfilerReport {
  /// When the report was generated.
  final DateTime generatedAt;

  /// Per-operation statistics.
  final Map<String, Map<String, dynamic>> operations;

  /// Summary statistics across all operations.
  final Map<String, dynamic> summary;

  /// Create a profiler report.
  ProfilerReport({
    required this.generatedAt,
    required this.operations,
    required this.summary,
  });

  /// Generate a Markdown representation of the report.
  String toMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('# Rift Performance Report');
    buffer.writeln('Generated: ${generatedAt.toIso8601String()}');
    buffer.writeln();
    buffer.writeln('## Summary');
    buffer.writeln('- Total Operations: ${summary['totalOperations']}');
    buffer.writeln('- Total Failures: ${summary['totalFailures']}');
    buffer.writeln(
      '- Total Time: ${summary['totalTimeMs']?.toStringAsFixed(2)}ms',
    );
    buffer.writeln(
      '- Failure Rate: ${(summary['overallFailureRate'] as double? ?? 0).toStringAsFixed(4)}',
    );
    buffer.writeln('- Operation Types: ${summary['operationTypes']}');
    buffer.writeln();
    buffer.writeln('## Operations');
    buffer.writeln(
      '| Operation | Count | Avg (ms) | Min (ms) | Max (ms) | P95 (ms) | Failure Rate | Throughput |',
    );
    buffer.writeln(
      '|-----------|-------|----------|----------|----------|----------|-------------|------------|',
    );
    for (final entry in operations.entries) {
      final op = entry.value;
      buffer.writeln(
        '| ${entry.key} | ${op['count']} | ${(op['avgTimeMs'] as double).toStringAsFixed(3)} | '
        '${(op['minTimeMs'] as double).toStringAsFixed(3)} | ${(op['maxTimeMs'] as double).toStringAsFixed(3)} | '
        '${(op['p95Ms'] as double).toStringAsFixed(3)} | ${(op['failureRate'] as double).toStringAsFixed(4)} | '
        '${(op['throughput'] as double).toStringAsFixed(2)} |',
      );
    }
    return buffer.toString();
  }

  /// Serialize to JSON.
  Map<String, dynamic> toJson() => {
    'generatedAt': generatedAt.toIso8601String(),
    'operations': operations,
    'summary': summary,
  };
}
