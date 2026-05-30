import 'dart:async';

import 'package:rift/src/box/box_base.dart';

/// A live query that automatically re-executes when box data changes.
///
/// LiveQuery wraps a query execution function and a [Box.watch()] stream.
/// Whenever the underlying data changes, the query is re-executed and
/// the latest results are emitted to all subscribers.
///
/// This class handles:
/// - Debouncing rapid changes to avoid excessive re-computation
/// - Proper subscription lifecycle management
/// - Error handling and recovery
///
/// Usage:
/// ```dart
/// final liveQuery = LiveQuery<int>(
///   box: myBox,
///   execute: () => myBox.query()
///     .where('age', greaterThan: 18)
///     .findAll(),
/// );
///
/// liveQuery.stream.listen((results) {
///   print('Found ${results.length} adults');
/// });
///
/// // Don't forget to dispose when done
/// liveQuery.dispose();
/// ```
class LiveQuery<E> {
  /// The box to watch for changes.
  final BoxBase<E> _box;

  /// The function that executes the query and returns results.
  final Future<List<E>> Function() _execute;

  /// Debounce duration to avoid excessive re-computation.
  final Duration _debounceDuration;

  /// Stream controller for emitting query results.
  late final StreamController<List<E>> _controller;

  /// Subscription to the box's change stream.
  StreamSubscription<BoxEvent>? _watchSubscription;

  /// Timer for debouncing.
  Timer? _debounceTimer;

  /// Whether this live query has been disposed.
  bool _disposed = false;

  /// The most recent query results (for immediate emission to new listeners).
  List<E>? _lastResults;

  /// Create a live query.
  ///
  /// [_box] is watched for changes via [BoxBase.watch()].
  /// [_execute] is called to (re-)run the query.
  /// [_debounceDuration] controls how long to wait after a change before
  /// re-executing the query (default: 10ms).
  LiveQuery({
    required BoxBase<E> box,
    required Future<List<E>> Function() execute,
    Duration debounceDuration = const Duration(milliseconds: 10),
  }) : _box = box,
       _execute = execute,
       _debounceDuration = debounceDuration {
    _controller = StreamController<List<E>>.broadcast(
      onListen: _onListen,
      onCancel: _onCancel,
    );
  }

  /// The stream of query results.
  ///
  /// Emits the current results when first listened to, and then
  /// emits updated results whenever the box data changes.
  Stream<List<E>> get stream => _controller.stream;

  /// The most recent query results, or null if the query hasn't run yet.
  List<E>? get lastResults => _lastResults;

  /// Called when the first listener subscribes.
  void _onListen() {
    if (_disposed) return;

    // Execute the query immediately for the initial result
    _executeQuery();

    // Subscribe to box changes
    _watchSubscription = _box.watch().listen((_) {
      _scheduleRefresh();
    });
  }

  /// Called when the last listener unsubscribes.
  void _onCancel() {
    _watchSubscription?.cancel();
    _watchSubscription = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  /// Schedule a query refresh after the debounce duration.
  void _scheduleRefresh() {
    if (_disposed) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      if (!_disposed && _controller.hasListener) {
        _executeQuery();
      }
    });
  }

  /// Execute the query and emit results.
  void _executeQuery() {
    if (_disposed) return;

    _execute()
        .then((results) {
          if (!_disposed && _controller.hasListener) {
            _lastResults = results;
            _controller.add(results);
          }
        })
        .catchError((error, stackTrace) {
          if (!_disposed && _controller.hasListener) {
            _controller.addError(error, stackTrace);
          }
        });
  }

  /// Manually trigger a refresh of the query results.
  ///
  /// This is useful when you know the data has changed but the
  /// change wasn't detected by the watch stream.
  void refresh() {
    _executeQuery();
  }

  /// Dispose this live query and release all resources.
  ///
  /// After calling [dispose], the [stream] will no longer emit events.
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    _debounceTimer?.cancel();
    _debounceTimer = null;

    _watchSubscription?.cancel();
    _watchSubscription = null;

    _controller.close();
  }

  @override
  String toString() => 'LiveQuery(box: ${_box.name}, disposed: $_disposed)';
}
