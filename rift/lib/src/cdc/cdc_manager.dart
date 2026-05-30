import 'dart:async';

/// Change Data Capture (CDC) for Rift.
/// Emits structured change events for sync, audit, and integration.
class CDCManager {
  final StreamController<CDCEvent> _controller = StreamController.broadcast();
  final List<CDCEvent> _eventLog = [];
  int _sequenceNumber = 0;
  final int _maxLogSize;

  /// Stream of change events.
  Stream<CDCEvent> get stream => _controller.stream;

  /// Create a CDC manager with optional max log size (default 100000).
  CDCManager({int maxLogSize = 100000}) : _maxLogSize = maxLogSize;

  /// Record a change event.
  void recordChange(
    CDCEventType type,
    String boxName,
    String? key,
    dynamic beforeValue,
    dynamic afterValue,
  ) {
    final event = CDCEvent(
      sequence: _sequenceNumber++,
      timestamp: DateTime.now(),
      type: type,
      boxName: boxName,
      key: key,
      beforeValue: beforeValue,
      afterValue: afterValue,
    );
    _eventLog.add(event);
    _controller.add(event);

    // Enforce max log size
    if (_eventLog.length > _maxLogSize) {
      _eventLog.removeRange(0, _eventLog.length - _maxLogSize);
    }
  }

  /// Get changes since a sequence number, optionally filtered.
  Future<List<CDCEvent>> getChangesSince(
    int sequence, {
    CDCFilter? filter,
  }) async {
    var events = _eventLog.where((e) => e.sequence > sequence).toList();
    if (filter != null) {
      events = _applyFilter(events, filter);
    }
    return events;
  }

  /// Get all recorded events, optionally filtered.
  Future<List<CDCEvent>> getEvents({CDCFilter? filter}) async {
    if (filter == null) return List.unmodifiable(_eventLog);
    return _applyFilter(_eventLog, filter);
  }

  /// Subscribe to changes from specific boxes and/or event types.
  Stream<CDCEvent> subscribe({
    List<String>? boxNames,
    List<CDCEventType>? eventTypes,
  }) {
    return _controller.stream.where((event) {
      if (boxNames != null && !boxNames.contains(event.boxName)) return false;
      if (eventTypes != null && !eventTypes.contains(event.type)) return false;
      return true;
    });
  }

  /// Get the current sequence number.
  int get currentSequence => _sequenceNumber;

  /// Number of events in the log.
  int get eventCount => _eventLog.length;

  /// Clear the event log.
  void clear() {
    _eventLog.clear();
  }

  /// Dispose the CDC manager.
  void dispose() {
    _controller.close();
  }

  List<CDCEvent> _applyFilter(List<CDCEvent> events, CDCFilter filter) {
    return events.where((e) {
      if (filter.boxNames != null && !filter.boxNames!.contains(e.boxName)) {
        return false;
      }
      if (filter.eventTypes != null && !filter.eventTypes!.contains(e.type)) {
        return false;
      }
      if (filter.since != null && e.timestamp.isBefore(filter.since!)) {
        return false;
      }
      return true;
    }).toList();
  }
}

/// A single CDC event.
class CDCEvent {
  /// Monotonically increasing sequence number.
  final int sequence;

  /// When the event occurred.
  final DateTime timestamp;

  /// The type of change.
  final CDCEventType type;

  /// The name of the box that changed.
  final String boxName;

  /// The key that was affected.
  final String? key;

  /// The value before the change.
  final dynamic beforeValue;

  /// The value after the change.
  final dynamic afterValue;

  /// Create a CDC event.
  CDCEvent({
    required this.sequence,
    required this.timestamp,
    required this.type,
    required this.boxName,
    this.key,
    this.beforeValue,
    this.afterValue,
  });

  /// Serialize to JSON.
  Map<String, dynamic> toJson() => {
    'seq': sequence,
    'ts': timestamp.toIso8601String(),
    'type': type.name,
    'box': boxName,
    'key': key,
    'before': beforeValue,
    'after': afterValue,
  };

  @override
  String toString() =>
      'CDCEvent(seq: $sequence, $type, box: $boxName, key: $key)';
}

/// Type of CDC event.
enum CDCEventType {
  /// A new key-value pair was inserted.
  insert,

  /// An existing key-value pair was updated.
  update,

  /// A key-value pair was deleted.
  delete,

  /// The box was cleared.
  clear,
}

/// Filter for CDC events.
class CDCFilter {
  /// Only include events from these boxes.
  final List<String>? boxNames;

  /// Only include events of these types.
  final List<CDCEventType>? eventTypes;

  /// Only include events after this time.
  final DateTime? since;

  /// Create a CDC filter.
  CDCFilter({this.boxNames, this.eventTypes, this.since});
}
