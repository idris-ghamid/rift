/// Observability and metrics for Rift database operations.
///
/// Collects detailed metrics about database operations for monitoring,
/// including timing, counts, success/failure rates, and latency
/// histograms.
///
/// Usage:
/// ```dart
/// final metrics = RiftMetrics.instance;
/// metrics.enable();
///
/// // Metrics are collected automatically for operations
/// // Generate a report
/// final report = metrics.generateReport();
/// print(report.toJson());
///
/// // Or get Prometheus-style output
/// print(report.toPrometheus());
/// ```
///
library;


/// The type of database operation being measured.
enum OperationType {
  /// A put (create/update) operation.
  put,

  /// A get (read) operation.
  get,

  /// A delete operation.
  delete,

  /// A query operation.
  query,

  /// A batch/bulk operation.
  batch,

  /// A compaction operation.
  compaction,

  /// A transaction operation.
  transaction,

  /// A sync operation.
  sync,
}

/// Metrics for a single operation type.
class OperationMetric {
  /// The operation type being measured.
  final OperationType type;

  /// The box name (empty string for global).
  final String boxName;

  /// Total number of operations.
  int count = 0;

  /// Number of successful operations.
  int successCount = 0;

  /// Number of failed operations.
  int failureCount = 0;

  /// Total duration of all operations (microseconds).
  int totalDurationUs = 0;

  /// Minimum operation duration (microseconds).
  int? minDurationUs;

  /// Maximum operation duration (microseconds).
  int? maxDurationUs;

  /// Duration histogram buckets (in microseconds).
  /// Bucket boundaries: 0, 100, 500, 1000, 5000, 10000, 50000, 100000, 500000, 1000000
  final List<int> histogramBuckets = [
    0,
    100,
    500,
    1000,
    5000,
    10000,
    50000,
    100000,
    500000,
    1000000,
  ];

  /// Count of operations falling into each histogram bucket.
  final List<int> histogramCounts = List.filled(11, 0); // one more than buckets

  /// Creates an [OperationMetric] for the given [type] and [boxName].
  OperationMetric({required this.type, required this.boxName});

  /// Records a successful operation with the given [durationUs].
  void recordSuccess(int durationUs) {
    count++;
    successCount++;
    _recordDuration(durationUs);
  }

  /// Records a failed operation with the given [durationUs].
  void recordFailure(int durationUs) {
    count++;
    failureCount++;
    _recordDuration(durationUs);
  }

  void _recordDuration(int durationUs) {
    totalDurationUs += durationUs;
    minDurationUs = minDurationUs == null
        ? durationUs
        : (durationUs < minDurationUs! ? durationUs : minDurationUs);
    maxDurationUs = maxDurationUs == null
        ? durationUs
        : (durationUs > maxDurationUs! ? durationUs : maxDurationUs);

    // Update histogram
    int bucketIndex = histogramBuckets.length; // Last bucket (overflow)
    for (int i = 0; i < histogramBuckets.length; i++) {
      if (durationUs <= histogramBuckets[i]) {
        bucketIndex = i;
        break;
      }
    }
    histogramCounts[bucketIndex]++;
  }

  /// The average operation duration in microseconds.
  double get avgDurationUs => count > 0 ? totalDurationUs / count : 0;

  /// The success rate (0.0 to 1.0).
  double get successRate => count > 0 ? successCount / count : 0;

  /// The failure rate (0.0 to 1.0).
  double get failureRate => count > 0 ? failureCount / count : 0;

  /// Resets all metrics.
  void reset() {
    count = 0;
    successCount = 0;
    failureCount = 0;
    totalDurationUs = 0;
    minDurationUs = null;
    maxDurationUs = null;
    for (int i = 0; i < histogramCounts.length; i++) {
      histogramCounts[i] = 0;
    }
  }
}

/// A report of all collected metrics.
class MetricsReport {
  /// The metrics included in this report.
  final List<OperationMetric> metrics;

  /// When this report was generated.
  final DateTime generatedAt;

  /// Creates a [MetricsReport].
  MetricsReport({required this.metrics, required this.generatedAt});

  /// Converts the report to a JSON-serializable map.
  Map<String, dynamic> toJson() {
    return {
      'generatedAt': generatedAt.toIso8601String(),
      'metrics': [
        for (final m in metrics)
          {
            'type': m.type.name,
            'boxName': m.boxName,
            'count': m.count,
            'successCount': m.successCount,
            'failureCount': m.failureCount,
            'avgDurationUs': m.avgDurationUs.round(),
            'minDurationUs': m.minDurationUs,
            'maxDurationUs': m.maxDurationUs,
            'successRate': m.successRate.toStringAsFixed(4),
            'histogram': {
              for (int i = 0; i < m.histogramBuckets.length; i++)
                'le_${m.histogramBuckets[i]}': m.histogramCounts[i],
              'overflow': m.histogramCounts[m.histogramBuckets.length],
            },
          },
      ],
    };
  }

  /// Converts the report to Markdown format.
  String toMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('# Rift Metrics Report');
    buffer.writeln('Generated: ${generatedAt.toIso8601String()}');
    buffer.writeln();
    buffer.writeln(
      '| Type | Box | Count | Success | Fail | Avg (μs) | Min (μs) | Max (μs) |',
    );
    buffer.writeln(
      '|------|-----|-------|---------|------|----------|----------|----------|',
    );
    for (final m in metrics) {
      buffer.writeln(
        '| ${m.type.name} | ${m.boxName} | ${m.count} | ${m.successCount} | ${m.failureCount} '
        '| ${m.avgDurationUs.round()} | ${m.minDurationUs ?? "-"} | ${m.maxDurationUs ?? "-"} |',
      );
    }
    return buffer.toString();
  }

  /// Converts the report to Prometheus exposition format.
  String toPrometheus() {
    final buffer = StringBuffer();
    for (final m in metrics) {
      final labels = 'type="${m.type.name}",box="${m.boxName}"';
      buffer.writeln('rift_operations_total{$labels} ${m.count}');
      buffer.writeln(
        'rift_operations_success_total{$labels} ${m.successCount}',
      );
      buffer.writeln(
        'rift_operations_failure_total{$labels} ${m.failureCount}',
      );
      buffer.writeln(
        'rift_operation_duration_avg_us{$labels} ${m.avgDurationUs.round()}',
      );
      buffer.writeln(
        'rift_operation_duration_min_us{$labels} ${m.minDurationUs ?? 0}',
      );
      buffer.writeln(
        'rift_operation_duration_max_us{$labels} ${m.maxDurationUs ?? 0}',
      );

      // Histogram
      var cumulative = 0;
      for (int i = 0; i < m.histogramBuckets.length; i++) {
        cumulative += m.histogramCounts[i];
        buffer.writeln(
          'rift_operation_duration_bucket{$labels,le="${m.histogramBuckets[i]}"} $cumulative',
        );
      }
      cumulative += m.histogramCounts[m.histogramBuckets.length];
      buffer.writeln(
        'rift_operation_duration_bucket{$labels,le="+Inf"} $cumulative',
      );
      buffer.writeln(
        'rift_operation_duration_sum_us{$labels} ${m.totalDurationUs}',
      );
      buffer.writeln('rift_operation_duration_count{$labels} ${m.count}');
    }
    return buffer.toString();
  }
}

/// Singleton metrics collector for Rift operations.
///
/// [RiftMetrics] collects timing and count metrics for database
/// operations. It supports per-box and global metrics, latency
/// histograms, and reporting in multiple formats.
class RiftMetrics {
  /// The singleton instance.
  static final RiftMetrics instance = RiftMetrics._();

  RiftMetrics._();

  /// Whether metrics collection is enabled.
  bool _enabled = false;

  /// Per-operation metrics: '${type.name}:${boxName}' → metric.
  final Map<String, OperationMetric> _metrics = {};

  /// Whether metrics collection is enabled.
  bool get isEnabled => _enabled;

  /// Enables metrics collection.
  void enable() => _enabled = true;

  /// Disables metrics collection.
  void disable() => _enabled = false;

  String _key(OperationType type, String boxName) => '${type.name}:$boxName';

  /// Records a successful operation.
  void recordSuccess(OperationType type, String boxName, int durationUs) {
    if (!_enabled) return;
    final key = _key(type, boxName);
    _metrics.putIfAbsent(
      key,
      () => OperationMetric(type: type, boxName: boxName),
    );
    _metrics[key]!.recordSuccess(durationUs);
  }

  /// Records a failed operation.
  void recordFailure(OperationType type, String boxName, int durationUs) {
    if (!_enabled) return;
    final key = _key(type, boxName);
    _metrics.putIfAbsent(
      key,
      () => OperationMetric(type: type, boxName: boxName),
    );
    _metrics[key]!.recordFailure(durationUs);
  }

  /// Times an async operation and records the result.
  ///
  /// If the operation throws, a failure is recorded.
  Future<T> time<T>(
    OperationType type,
    String boxName,
    Future<T> Function() operation,
  ) async {
    if (!_enabled) return operation();
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      stopwatch.stop();
      recordSuccess(type, boxName, stopwatch.elapsedMicroseconds);
      return result;
    } catch (e) {
      stopwatch.stop();
      recordFailure(type, boxName, stopwatch.elapsedMicroseconds);
      rethrow;
    }
  }

  /// Times a sync operation and records the result.
  T timeSync<T>(OperationType type, String boxName, T Function() operation) {
    if (!_enabled) return operation();
    final stopwatch = Stopwatch()..start();
    try {
      final result = operation();
      stopwatch.stop();
      recordSuccess(type, boxName, stopwatch.elapsedMicroseconds);
      return result;
    } catch (e) {
      stopwatch.stop();
      recordFailure(type, boxName, stopwatch.elapsedMicroseconds);
      rethrow;
    }
  }

  /// Gets the metric for a specific operation type and box.
  OperationMetric? getMetric(OperationType type, String boxName) {
    return _metrics[_key(type, boxName)];
  }

  /// Gets all collected metrics.
  List<OperationMetric> get allMetrics => List.unmodifiable(_metrics.values);

  /// Generates a metrics report.
  MetricsReport generateReport() {
    return MetricsReport(
      metrics: List.from(_metrics.values),
      generatedAt: DateTime.now(),
    );
  }

  /// Resets all collected metrics.
  void reset() {
    for (final metric in _metrics.values) {
      metric.reset();
    }
  }

  /// Clears all metric data.
  void clear() {
    _metrics.clear();
  }
}
