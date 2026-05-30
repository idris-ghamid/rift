import 'dart:math';

import 'package:rift/src/box/box.dart';

/// Time-series data storage and querying for Rift.
/// Optimized for timestamped data with downsampling and aggregation.
///
/// The [TimeSeries] class provides efficient storage and retrieval of
/// timestamped data points. It supports:
///
/// - **Insert**: Add timestamped data points
/// - **Range queries**: Retrieve data within a time range
/// - **Latest**: Get the most recent N data points
/// - **Downsampling**: Reduce data granularity using aggregation
/// - **Moving average**: Calculate rolling averages over a window
///
/// Data is stored in a standard Rift [Box] with keys prefixed by `ts_`
/// and the timestamp in milliseconds. This allows efficient range scans
/// since keys are sorted alphabetically.
///
/// Usage:
/// ```dart
/// final box = await Rift.openBox('sensor_data');
/// final ts = TimeSeries(box, timestampField: 'ts');
///
/// await ts.insert(DateTime.now(), {'temperature': 23.5, 'humidity': 65});
/// await ts.insert(DateTime.now().subtract(Duration(minutes: 5)), {'temperature': 22.1});
///
/// final recent = await ts.latest(count: 10);
/// final range = await ts.queryRange(from, to);
/// final downsampled = await ts.downsample(Duration(hours: 1), 'temperature');
/// ```
class TimeSeries {
  final Box _box;
  final String _timestampField;

  /// Create a [TimeSeries] backed by [box].
  ///
  /// The [timestampField] parameter specifies which field in the data map
  /// stores the timestamp as an ISO 8601 string. Defaults to `'timestamp'`.
  TimeSeries(this._box, {String timestampField = 'timestamp'})
    : _timestampField = timestampField;

  /// Insert a time-series data point.
  ///
  /// The [timestamp] is stored in the data map under the configured
  /// [timestampField]. The key is generated as `ts_{milliseconds}_{boxLength}`
  /// to ensure uniqueness and chronological ordering.
  Future<void> insert(DateTime timestamp, Map<String, dynamic> data) async {
    final key = 'ts_${timestamp.millisecondsSinceEpoch}_${_box.length}';
    await _box.put(key, {
      ...data,
      _timestampField: timestamp.toIso8601String(),
    });
  }

  /// Query data in a time range [from] to [to] (inclusive).
  ///
  /// Returns all data points whose timestamps fall within the specified
  /// range, sorted chronologically.
  Future<List<TimeSeriesPoint>> queryRange(DateTime from, DateTime to) async {
    final fromMs = from.millisecondsSinceEpoch;
    final toMs = to.millisecondsSinceEpoch;
    final startKey = 'ts_$fromMs';
    final endKey = 'ts_${toMs + 1}'; // +1 to make inclusive

    final results = <TimeSeriesPoint>[];
    final allKeys = _box.keys.toList();

    for (final key in allKeys) {
      if (key is! String || !key.startsWith('ts_')) continue;

      // Extract timestamp from key
      final keyParts = key.substring(3).split('_');
      if (keyParts.isEmpty) continue;

      final keyMs = int.tryParse(keyParts[0]);
      if (keyMs == null) continue;

      if (keyMs >= fromMs && keyMs <= toMs) {
        final value = _box.get(key);
        if (value is Map) {
          final data = Map<String, dynamic>.from(value);
          final ts =
              _extractTimestamp(data) ??
              DateTime.fromMillisecondsSinceEpoch(keyMs);
          results.add(TimeSeriesPoint(ts, data));
        }
      }
    }

    // Sort by timestamp
    results.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return results;
  }

  /// Get the latest [count] data points.
  ///
  /// Returns data points sorted chronologically (oldest first).
  Future<List<TimeSeriesPoint>> latest({int count = 10}) async {
    final allPoints = await _getAllPoints();
    if (allPoints.length <= count) return allPoints;
    return allPoints.sublist(allPoints.length - count);
  }

  /// Downsample data using aggregation within time windows.
  ///
  /// Groups data points into windows of [window] duration and applies
  /// the specified [method] to the [valueField] in each window.
  ///
  /// Supported methods:
  /// - [AggregationMethod.average]: Mean of values in the window
  /// - [AggregationMethod.minimum]: Smallest value in the window
  /// - [AggregationMethod.maximum]: Largest value in the window
  /// - [AggregationMethod.sum]: Sum of values in the window
  /// - [AggregationMethod.count]: Number of values in the window
  /// - [AggregationMethod.first]: First value in the window
  /// - [AggregationMethod.last]: Last value in the window
  ///
  /// Returns one data point per window with the aggregated value
  /// stored under [valueField] and the window start timestamp.
  Future<List<TimeSeriesPoint>> downsample(
    Duration window,
    String valueField, {
    AggregationMethod method = AggregationMethod.average,
  }) async {
    final allPoints = await _getAllPoints();
    if (allPoints.isEmpty) return [];

    final windowMs = window.inMilliseconds;
    final windows = <int, List<TimeSeriesPoint>>{};

    // Group points into windows
    for (final point in allPoints) {
      final windowStart =
          (point.timestamp.millisecondsSinceEpoch ~/ windowMs) * windowMs;
      windows.putIfAbsent(windowStart, () => []).add(point);
    }

    final results = <TimeSeriesPoint>[];
    final sortedWindows = windows.keys.toList()..sort();

    for (final windowStart in sortedWindows) {
      final windowPoints = windows[windowStart]!;
      final values = <num>[];

      for (final point in windowPoints) {
        final v = point.data[valueField];
        if (v is num) values.add(v);
      }

      if (values.isEmpty) continue;

      final aggregatedValue = _aggregate(values, method, windowPoints);
      results.add(
        TimeSeriesPoint(DateTime.fromMillisecondsSinceEpoch(windowStart), {
          valueField: aggregatedValue,
          'count': values.length,
        }),
      );
    }

    return results;
  }

  /// Calculate moving average over a window of [windowSize] data points.
  ///
  /// For each data point, calculates the average of [valueField] over
  /// the current point and the previous ([windowSize] - 1) points.
  ///
  /// Returns data points with the moving average stored under [valueField]
  /// and the original value under `raw_$valueField`.
  Future<List<TimeSeriesPoint>> movingAverage(
    String valueField, {
    int windowSize = 5,
  }) async {
    final allPoints = await _getAllPoints();
    if (allPoints.isEmpty) return [];

    final results = <TimeSeriesPoint>[];

    for (int i = 0; i < allPoints.length; i++) {
      final start = max(0, i - windowSize + 1);
      final window = allPoints.sublist(start, i + 1);

      final values = <num>[];
      for (final p in window) {
        final v = p.data[valueField];
        if (v is num) values.add(v);
      }

      if (values.isEmpty) continue;

      final avg = values.reduce((a, b) => a + b) / values.length;
      final data = Map<String, dynamic>.from(allPoints[i].data);
      data['raw_$valueField'] = data[valueField];
      data[valueField] = avg;

      results.add(TimeSeriesPoint(allPoints[i].timestamp, data));
    }

    return results;
  }

  /// Get all time-series points, sorted chronologically.
  Future<List<TimeSeriesPoint>> _getAllPoints() async {
    final results = <TimeSeriesPoint>[];
    final allKeys = _box.keys.toList();

    for (final key in allKeys) {
      if (key is! String || !key.startsWith('ts_')) continue;

      final value = _box.get(key);
      if (value is Map) {
        final data = Map<String, dynamic>.from(value);
        final ts = _extractTimestamp(data);
        if (ts != null) {
          results.add(TimeSeriesPoint(ts, data));
        }
      }
    }

    results.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return results;
  }

  /// Extract a DateTime from the data map's timestamp field.
  DateTime? _extractTimestamp(Map<String, dynamic> data) {
    final tsValue = data[_timestampField];
    if (tsValue is String) {
      return DateTime.tryParse(tsValue);
    } else if (tsValue is int) {
      return DateTime.fromMillisecondsSinceEpoch(tsValue);
    } else if (tsValue is DateTime) {
      return tsValue;
    }
    return null;
  }

  /// Apply an aggregation method to a list of numeric values.
  num _aggregate(
    List<num> values,
    AggregationMethod method,
    List<TimeSeriesPoint> windowPoints,
  ) {
    switch (method) {
      case AggregationMethod.average:
        return values.reduce((a, b) => a + b) / values.length;
      case AggregationMethod.minimum:
        return values.reduce(min);
      case AggregationMethod.maximum:
        return values.reduce(max);
      case AggregationMethod.sum:
        return values.reduce((a, b) => a + b);
      case AggregationMethod.count:
        return values.length;
      case AggregationMethod.first:
        return values.first;
      case AggregationMethod.last:
        return values.last;
    }
  }

  /// Delete all time-series data points from the box.
  Future<void> deleteAll() async {
    final keysToDelete = <dynamic>[];
    for (final key in _box.keys) {
      if (key is String && key.startsWith('ts_')) {
        keysToDelete.add(key);
      }
    }
    await _box.deleteAll(keysToDelete);
  }

  /// Get the total number of time-series data points.
  int get count {
    int c = 0;
    for (final key in _box.keys) {
      if (key is String && key.startsWith('ts_')) c++;
    }
    return c;
  }
}

/// Aggregation methods for downsampling time-series data.
enum AggregationMethod {
  /// Mean of values in the window.
  average,

  /// Smallest value in the window.
  minimum,

  /// Largest value in the window.
  maximum,

  /// Sum of values in the window.
  sum,

  /// Number of values in the window.
  count,

  /// First value in the window.
  first,

  /// Last value in the window.
  last,
}

/// A single data point in a time series.
///
/// Contains a [timestamp] and an arbitrary [data] map with the
/// point's fields and values.
class TimeSeriesPoint {
  /// The timestamp of this data point.
  final DateTime timestamp;

  /// The data fields and values for this data point.
  final Map<String, dynamic> data;

  /// Create a [TimeSeriesPoint] with the given [timestamp] and [data].
  TimeSeriesPoint(this.timestamp, this.data);

  @override
  String toString() => 'TimeSeriesPoint($timestamp, $data)';
}
