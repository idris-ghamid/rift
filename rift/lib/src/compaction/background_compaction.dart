import 'dart:async';

import 'package:rift/src/box/box.dart';

/// Background compaction for Rift boxes.
/// Performs incremental compaction without blocking reads.
///
/// The [BackgroundCompactor] runs compaction on registered boxes at
/// regular intervals. This is useful for long-running applications
/// where boxes accumulate deleted/overwritten entries that need to
/// be cleaned up periodically.
///
/// Compaction is non-blocking: reads can proceed while compaction
/// is in progress since Rift's architecture supports concurrent reads.
///
/// Usage:
/// ```dart
/// final compactor = BackgroundCompactor(
///   {'users': usersBox, 'settings': settingsBox},
///   interval: Duration(minutes: 10),
/// );
///
/// compactor.start();
///
/// // Listen for compaction events
/// compactor.events.listen((event) {
///   print('${event.boxName} compacted in ${event.duration.inMilliseconds}ms');
/// });
///
/// // Stop when done
/// compactor.stop();
/// ```
class BackgroundCompactor {
  final Map<String, Box> _boxes;
  Duration _interval;
  Timer? _timer;
  bool _isRunning = false;
  int _compactionCount = 0;
  final StreamController<CompactionEvent> _eventController =
      StreamController.broadcast();

  /// Create a [BackgroundCompactor] for the given [boxes].
  ///
  /// The map keys are box names used in [CompactionEvent] reports.
  /// The [interval] specifies how often compaction runs (default 5 minutes).
  BackgroundCompactor(
    this._boxes, {
    Duration interval = const Duration(minutes: 5),
  }) : _interval = interval;

  /// Start automatic background compaction.
  ///
  /// After calling this, compaction will run at the configured interval.
  /// Calling [start] while already running has no effect.
  void start() {
    if (_isRunning) return;
    _timer = Timer.periodic(_interval, (_) => compactAll());
    _isRunning = true;
  }

  /// Stop automatic compaction.
  ///
  /// Cancels the periodic timer. Any in-progress compaction will
  /// still complete.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  /// Compact all registered boxes.
  ///
  /// Iterates through all registered boxes and compacts each one.
  /// A [CompactionEvent] is emitted for each box that is compacted.
  Future<void> compactAll() async {
    for (final entry in _boxes.entries) {
      await compactBox(entry.key);
    }
  }

  /// Compact a specific box by [boxName].
  ///
  /// If no box with the given name is registered, this is a no-op.
  /// Measures the time taken and emits a [CompactionEvent].
  Future<void> compactBox(String boxName) async {
    final box = _boxes[boxName];
    if (box == null) return;

    final sw = Stopwatch()..start();
    await box.compact();
    sw.stop();

    _compactionCount++;
    if (!_eventController.isClosed) {
      _eventController.add(
        CompactionEvent(boxName, sw.elapsed, DateTime.now()),
      );
    }
  }

  /// Register an additional box for compaction.
  void registerBox(String name, Box box) {
    _boxes[name] = box;
  }

  /// Unregister a box from compaction.
  void unregisterBox(String name) {
    _boxes.remove(name);
  }

  /// Stream of compaction events.
  ///
  /// Emits a [CompactionEvent] after each box is compacted.
  Stream<CompactionEvent> get events => _eventController.stream;

  /// Whether the compactor is currently running.
  bool get isRunning => _isRunning;

  /// The total number of compactions performed.
  int get compactionCount => _compactionCount;

  /// The current compaction interval.
  Duration get interval => _interval;

  /// Update the compaction interval.
  ///
  /// Stops and restarts the timer with the new interval.
  void updateInterval(Duration newInterval) {
    _interval = newInterval;
    if (_isRunning) {
      stop();
      start();
    }
  }

  /// Get the names of all registered boxes.
  Iterable<String> get registeredBoxNames => _boxes.keys;

  /// Dispose of the compactor, stopping the timer and closing the event stream.
  void dispose() {
    stop();
    _eventController.close();
  }
}

/// Event emitted when a box is compacted.
class CompactionEvent {
  /// The name of the box that was compacted.
  final String boxName;

  /// How long the compaction took.
  final Duration duration;

  /// When the compaction occurred.
  final DateTime timestamp;

  /// Create a [CompactionEvent].
  CompactionEvent(this.boxName, this.duration, this.timestamp);

  @override
  String toString() =>
      'CompactionEvent($boxName, ${duration.inMilliseconds}ms, $timestamp)';
}
