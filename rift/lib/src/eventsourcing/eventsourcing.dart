/// Event sourcing pattern for Rift.
///
/// Stores events instead of state, allowing the current state to be
/// derived by replaying events. Supports projections, snapshots,
/// and event replay for rebuilding state.
///
/// Usage:
/// ```dart
/// final eventStore = EventStore<String>('orders');
///
/// // Append events
/// await eventStore.append('order_1', Event(type: 'created', data: {'item': 'Book', 'qty': 2}));
/// await eventStore.append('order_1', Event(type: 'item_added', data: {'item': 'Pen', 'qty': 5}));
/// await eventStore.append('order_1', Event(type: 'item_removed', data: {'item': 'Book'}));
///
/// // Project current state
/// final projection = OrderProjection();
/// final state = await eventStore.project('order_1', projection);
/// print(state); // {items: {Pen: 5}}
///
/// // Replay all events
/// final events = eventStore.getEvents('order_1');
/// ```
library;

import 'dart:async';

/// A typed event with metadata.
class Event {
  /// The event type (e.g., 'created', 'updated', 'deleted').
  final String type;

  /// The event data/payload.
  final Map<String, dynamic> data;

  /// When this event occurred.
  final DateTime timestamp;

  /// The event version (monotonically increasing per stream).
  final int version;

  /// Optional correlation ID for tracing.
  final String? correlationId;

  /// Optional metadata.
  final Map<String, dynamic>? metadata;

  /// Creates an [Event].
  Event({
    required this.type,
    required this.data,
    DateTime? timestamp,
    this.version = 0,
    this.correlationId,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Converts the event to a JSON-serializable map.
  Map<String, dynamic> toJson() => {
    'type': type,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'version': version,
    if (correlationId != null) 'correlationId': correlationId,
    if (metadata != null) 'metadata': metadata,
  };

  /// Creates an [Event] from a JSON map.
  factory Event.fromJson(Map<String, dynamic> json) => Event(
    type: json['type'] as String,
    data: Map<String, dynamic>.from(json['data'] as Map),
    timestamp: DateTime.parse(json['timestamp'] as String),
    version: json['version'] as int? ?? 0,
    correlationId: json['correlationId'] as String?,
    metadata: json['metadata'] != null
        ? Map<String, dynamic>.from(json['metadata'] as Map)
        : null,
  );

  @override
  String toString() => 'Event($type v$version at $timestamp)';
}

/// Abstract base class for projections.
///
/// A projection derives current state from a sequence of events.
/// Override [apply] to handle each event type and update the
/// accumulator state.
abstract class Projection<T> {
  /// The initial state before any events are applied.
  T get initialState;

  /// Applies an [event] to the current [state] and returns
  /// the new state.
  T apply(T state, Event event);
}

/// Replays events to rebuild state.
class EventReplay {
  /// Replays a list of [events] through a [projection], starting
  /// from [initialState].
  ///
  /// Returns the final state after all events have been applied.
  static T replay<T>(
    List<Event> events,
    Projection<T> projection, [
    T? initialState,
  ]) {
    var state = initialState ?? projection.initialState;
    for (final event in events) {
      state = projection.apply(state, event);
    }
    return state;
  }

  /// Replays events up to a specific [version].
  static T replayUpTo<T>(
    List<Event> events,
    Projection<T> projection,
    int version, [
    T? initialState,
  ]) {
    var state = initialState ?? projection.initialState;
    for (final event in events) {
      if (event.version > version) break;
      state = projection.apply(state, event);
    }
    return state;
  }
}

/// Append-only event storage.
///
/// [EventStore] stores events for multiple streams (identified by
/// stream IDs). It supports appending events, retrieving events,
/// projecting state, and creating snapshots for performance.
class EventStore<T> {
  /// The name of this event store.
  final String name;

  /// Events per stream: streamId → list of events.
  final Map<String, List<Event>> _streams = {};

  /// Version counters per stream.
  final Map<String, int> _versionCounters = {};

  /// Snapshots per stream: streamId → (version, state).
  final Map<String, (int version, T state)> _snapshots = {};

  /// Stream controller for event notifications.
  final StreamController<Event> _eventController = StreamController.broadcast();

  /// Maximum events to keep per stream before snapshot compaction.
  final int snapshotThreshold;

  /// Creates an [EventStore].
  EventStore(this.name, {this.snapshotThreshold = 100});

  /// Stream of all appended events.
  Stream<Event> get eventStream => _eventController.stream;

  /// Appends an event to a stream.
  ///
  /// [streamId] is the identifier for the event stream.
  /// [event] is the event to append. The event's version is
  /// automatically assigned.
  Future<void> append(String streamId, Event event) async {
    _streams.putIfAbsent(streamId, () => []);
    _versionCounters.putIfAbsent(streamId, () => 0);
    _versionCounters[streamId] = _versionCounters[streamId]! + 1;

    final versionedEvent = Event(
      type: event.type,
      data: event.data,
      timestamp: event.timestamp,
      version: _versionCounters[streamId]!,
      correlationId: event.correlationId,
      metadata: event.metadata,
    );

    _streams[streamId]!.add(versionedEvent);

    if (!_eventController.isClosed) {
      _eventController.add(versionedEvent);
    }
  }

  /// Appends multiple events to a stream atomically.
  Future<void> appendAll(String streamId, List<Event> events) async {
    for (final event in events) {
      await append(streamId, event);
    }
  }

  /// Gets all events for a stream.
  List<Event> getEvents(String streamId) {
    return List.unmodifiable(_streams[streamId] ?? []);
  }

  /// Gets events for a stream starting from [fromVersion].
  List<Event> getEventsFrom(String streamId, int fromVersion) {
    final events = _streams[streamId] ?? [];
    return events.where((e) => e.version >= fromVersion).toList();
  }

  /// Gets the current version of a stream.
  int? getVersion(String streamId) => _versionCounters[streamId];

  /// Gets the number of events in a stream.
  int eventCount(String streamId) => _streams[streamId]?.length ?? 0;

  /// Projects the current state of a stream using a [projection].
  ///
  /// If a snapshot exists, starts from the snapshot and only
  /// replays events after the snapshot version.
  Future<T> project(String streamId, Projection<T> projection) async {
    final snapshot = _snapshots[streamId];
    final events = _streams[streamId] ?? [];

    if (snapshot != null) {
      final (snapshotVersion, snapshotState) = snapshot;
      final eventsAfterSnapshot = events
          .where((e) => e.version > snapshotVersion)
          .toList();
      return EventReplay.replay(eventsAfterSnapshot, projection, snapshotState);
    }

    return EventReplay.replay(events, projection);
  }

  /// Creates a snapshot of the current state for a stream.
  ///
  /// Snapshots allow faster state reconstruction by only replaying
  /// events after the snapshot version.
  Future<void> createSnapshot(String streamId, Projection<T> projection) async {
    final state = await project(streamId, projection);
    final version = _versionCounters[streamId] ?? 0;
    _snapshots[streamId] = (version, state);
  }

  /// Deletes all events for a stream.
  void deleteStream(String streamId) {
    _streams.remove(streamId);
    _versionCounters.remove(streamId);
    _snapshots.remove(streamId);
  }

  /// Gets all stream IDs.
  Iterable<String> get streamIds => _streams.keys;

  /// The number of streams in the store.
  int get streamCount => _streams.length;

  /// Clears all events and snapshots.
  void clear() {
    _streams.clear();
    _versionCounters.clear();
    _snapshots.clear();
  }

  /// Disposes the event store.
  void dispose() {
    _eventController.close();
    clear();
  }
}

/// A generic map-based projection that applies handler functions.
///
/// Each event type maps to a handler that transforms the state.
class MapProjection extends Projection<Map<String, dynamic>> {
  /// Handler functions per event type.
  final Map<
    String,
    Map<String, dynamic> Function(Map<String, dynamic> state, Event event)
  >
  handlers;

  /// Creates a [MapProjection].
  MapProjection(this.handlers);

  @override
  Map<String, dynamic> get initialState => {};

  @override
  Map<String, dynamic> apply(Map<String, dynamic> state, Event event) {
    final handler = handlers[event.type];
    if (handler != null) {
      return handler(state, event);
    }
    return state;
  }
}
