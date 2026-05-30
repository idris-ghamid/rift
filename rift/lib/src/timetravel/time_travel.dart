import 'package:rift/rift.dart';

/// Time travel capability for Rift boxes.
/// Allows reverting to any previous state via event sourcing.
class TimeTravel {
  /// The name of the box this time travel instance tracks.
  final String boxName;

  final List<TimeTravelEvent> _events = [];
  final Map<int, BoxSnapshot> _snapshots = {};
  int _currentVersion = 0;

  /// How many versions between automatic snapshot suggestions.
  final int snapshotInterval;

  /// Create a TimeTravel instance for [boxName].
  /// [snapshotInterval] controls how often snapshots should be created (default 100).
  TimeTravel(this.boxName, {int snapshotInterval = 100})
    : snapshotInterval = snapshotInterval;

  /// Record a change event.
  void record(
    TimeTravelEventType type,
    String? key,
    dynamic oldValue,
    dynamic newValue,
  ) {
    _events.add(
      TimeTravelEvent(
        version: _currentVersion++,
        timestamp: DateTime.now(),
        type: type,
        key: key,
        oldValue: oldValue,
        newValue: newValue,
      ),
    );
  }

  /// Save a snapshot at the current version.
  void saveSnapshot(BoxSnapshot snapshot) {
    _snapshots[_currentVersion] = snapshot;
  }

  /// Create and save a snapshot from a [Box] at the current version.
  Future<void> snapshotBox(Box box) async {
    final snapshot = await BoxSnapshot.fromBox(box, _currentVersion);
    _snapshots[_currentVersion] = snapshot;
  }

  /// Get events since a given version.
  List<TimeTravelEvent> getEventsSince(int version) {
    return _events.where((e) => e.version > version).toList();
  }

  /// Get all versions.
  List<int> get versions => _events.map((e) => e.version).toList();

  /// Get event at a specific version.
  TimeTravelEvent? getEventAt(int version) {
    for (final event in _events) {
      if (event.version == version) return event;
    }
    return null;
  }

  /// Find the nearest snapshot before or at a given version.
  BoxSnapshot? findNearestSnapshot(int version) {
    final keys = _snapshots.keys.where((k) => k <= version).toList()..sort();
    return keys.isNotEmpty ? _snapshots[keys.last] : null;
  }

  /// Get events between two versions (inclusive).
  List<TimeTravelEvent> getEventsBetween(int from, int to) {
    return _events.where((e) => e.version >= from && e.version <= to).toList();
  }

  /// Prune events older than a version (keeps snapshots).
  void prune(int keepSinceVersion) {
    _events.removeWhere((e) => e.version < keepSinceVersion);
    _snapshots.removeWhere((k, _) => k < keepSinceVersion);
  }

  /// Reconstruct the state at a given version by replaying events from
  /// the nearest snapshot.
  Map<String, dynamic> reconstructAt(int version) {
    // Find nearest snapshot
    final snapshot = findNearestSnapshot(version);
    Map<String, dynamic> state;

    if (snapshot != null) {
      state = Map<String, dynamic>.from(snapshot.data);
    } else {
      state = {};
    }

    // Get the starting version (snapshot version or 0)
    final startVersion = snapshot?.version ?? -1;

    // Replay events from snapshot to target version
    for (final event in _events) {
      if (event.version <= startVersion) continue;
      if (event.version > version) break;

      switch (event.type) {
        case TimeTravelEventType.put:
          if (event.key != null) {
            state[event.key!] = event.newValue;
          }
          break;
        case TimeTravelEventType.delete:
          if (event.key != null) {
            state.remove(event.key!);
          }
          break;
        case TimeTravelEventType.clear:
          state.clear();
          break;
      }
    }

    return state;
  }

  /// The current version number.
  int get currentVersion => _currentVersion;

  /// All recorded events (unmodifiable).
  List<TimeTravelEvent> get history => List.unmodifiable(_events);

  /// All saved snapshots.
  Map<int, BoxSnapshot> get snapshots => Map.unmodifiable(_snapshots);

  /// Number of recorded events.
  int get eventCount => _events.length;

  /// Number of saved snapshots.
  int get snapshotCount => _snapshots.length;
}

/// Type of time travel event.
enum TimeTravelEventType {
  /// A key-value pair was put.
  put,

  /// A key was deleted.
  delete,

  /// The box was cleared.
  clear,
}

/// A single recorded event in the time travel log.
class TimeTravelEvent {
  /// The version number (monotonically increasing).
  final int version;

  /// When this event occurred.
  final DateTime timestamp;

  /// The type of event.
  final TimeTravelEventType type;

  /// The key that was affected (null for clear events).
  final String? key;

  /// The value before the change.
  final dynamic oldValue;

  /// The value after the change.
  final dynamic newValue;

  /// Create a time travel event.
  TimeTravelEvent({
    required this.version,
    required this.timestamp,
    required this.type,
    this.key,
    this.oldValue,
    this.newValue,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'timestamp': timestamp.toIso8601String(),
    'type': type.name,
    'key': key,
    'oldValue': oldValue?.toString(),
    'newValue': newValue?.toString(),
  };

  @override
  String toString() =>
      'TimeTravelEvent(v$version, $type, key: $key, old: $oldValue, new: $newValue)';
}

/// A snapshot of a box's state at a specific version.
class BoxSnapshot {
  /// The version at which this snapshot was taken.
  final int version;

  /// When this snapshot was created.
  final DateTime timestamp;

  /// The data in the box at the time of the snapshot.
  final Map<String, dynamic> data;

  /// Create a box snapshot.
  BoxSnapshot({
    required this.version,
    required this.timestamp,
    required this.data,
  });

  /// Create a snapshot from a [Box] at a given [version].
  static Future<BoxSnapshot> fromBox(Box box, int version) async {
    final data = <String, dynamic>{};
    for (final key in box.keys) {
      data[key.toString()] = box.get(key);
    }
    return BoxSnapshot(version: version, timestamp: DateTime.now(), data: data);
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'timestamp': timestamp.toIso8601String(),
    'data': data,
  };

  @override
  String toString() =>
      'BoxSnapshot(v$version, ${data.length} entries, $timestamp)';
}
