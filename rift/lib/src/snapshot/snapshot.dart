/// Snapshot isolation for Rift boxes.
///
/// Provides MVCC-style (Multi-Version Concurrency Control) snapshot
/// isolation, allowing reads from a consistent point-in-time view
/// of a box while concurrent writes continue.
///
/// Usage:
/// ```dart
/// final isolation = SnapshotIsolation();
///
/// // Create a snapshot at the current version
/// final snapshot = await isolation.createSnapshot(box);
///
/// // Reads from snapshot are not affected by writes
/// final value = snapshot.get('key');
///
/// // Compare two snapshots
/// final later = await isolation.createSnapshot(box);
/// final diff = SnapshotDiff.between(snapshot, later);
/// for (final change in diff.changes) {
///   print('${change.key}: ${change.oldValue} → ${change.newValue}');
/// }
/// ```
library;

import 'package:rift/rift.dart';

/// A change between two snapshots.
class SnapshotChange {
  /// The key that changed.
  final dynamic key;

  /// The old value (null if the key was added).
  final dynamic oldValue;

  /// The new value (null if the key was deleted).
  final dynamic newValue;

  /// The type of change.
  final SnapshotChangeType type;

  /// Creates a [SnapshotChange].
  const SnapshotChange({
    required this.key,
    this.oldValue,
    this.newValue,
    required this.type,
  });

  @override
  String toString() => 'SnapshotChange($type: $key, $oldValue → $newValue)';
}

/// The type of change between snapshots.
enum SnapshotChangeType {
  /// A new key was added.
  added,

  /// An existing key was modified.
  modified,

  /// A key was deleted.
  removed,
}

/// An immutable snapshot of a box's state at a specific version.
///
/// [BoxSnapshotData] captures the entire state of a box at the time
/// of creation. Reads from the snapshot are not affected by subsequent
/// writes to the box.
class BoxSnapshotData {
  /// The snapshot version (monotonically increasing).
  final int version;

  /// The timestamp when the snapshot was created.
  final DateTime timestamp;

  /// The immutable copy of the box data.
  final Map<dynamic, dynamic> _data;

  /// The name of the box this snapshot belongs to.
  final String boxName;

  /// Creates a [BoxSnapshotData].
  BoxSnapshotData({
    required this.version,
    required this.timestamp,
    required Map<dynamic, dynamic> data,
    required this.boxName,
  }) : _data = Map.unmodifiable(Map<dynamic, dynamic>.from(data));

  /// Gets the value for [key], or null if not present.
  dynamic get(dynamic key) => _data[key];

  /// Whether the snapshot contains [key].
  bool containsKey(dynamic key) => _data.containsKey(key);

  /// All keys in the snapshot.
  Iterable<dynamic> get keys => _data.keys;

  /// All values in the snapshot.
  Iterable<dynamic> get values => _data.values;

  /// The number of entries in the snapshot.
  int get length => _data.length;

  /// Whether the snapshot is empty.
  bool get isEmpty => _data.isEmpty;

  /// Whether the snapshot is not empty.
  bool get isNotEmpty => _data.isNotEmpty;

  /// Returns the snapshot data as an unmodifiable map.
  Map<dynamic, dynamic> toMap() => _data;

  @override
  String toString() =>
      'BoxSnapshotData(box: $boxName, version: $version, entries: $length)';
}

/// Computes the diff between two snapshots.
class SnapshotDiff {
  /// The source snapshot.
  final BoxSnapshotData from;

  /// The target snapshot.
  final BoxSnapshotData to;

  /// The list of changes between [from] and [to].
  final List<SnapshotChange> changes;

  /// Private constructor.
  SnapshotDiff._({required this.from, required this.to, required this.changes});

  /// Computes the diff between two snapshots.
  ///
  /// Compares [from] and [to] and returns all changes needed to
  /// transform [from] into [to].
  static SnapshotDiff between(BoxSnapshotData from, BoxSnapshotData to) {
    final changes = <SnapshotChange>[];
    final allKeys = <dynamic>{...from._data.keys, ...to._data.keys};

    for (final key in allKeys) {
      final fromValue = from._data[key];
      final toValue = to._data[key];

      if (!from._data.containsKey(key)) {
        changes.add(
          SnapshotChange(
            key: key,
            newValue: toValue,
            type: SnapshotChangeType.added,
          ),
        );
      } else if (!to._data.containsKey(key)) {
        changes.add(
          SnapshotChange(
            key: key,
            oldValue: fromValue,
            type: SnapshotChangeType.removed,
          ),
        );
      } else if (fromValue != toValue) {
        changes.add(
          SnapshotChange(
            key: key,
            oldValue: fromValue,
            newValue: toValue,
            type: SnapshotChangeType.modified,
          ),
        );
      }
    }

    return SnapshotDiff._(from: from, to: to, changes: changes);
  }

  /// The number of added keys.
  int get addedCount =>
      changes.where((c) => c.type == SnapshotChangeType.added).length;

  /// The number of modified keys.
  int get modifiedCount =>
      changes.where((c) => c.type == SnapshotChangeType.modified).length;

  /// The number of removed keys.
  int get removedCount =>
      changes.where((c) => c.type == SnapshotChangeType.removed).length;

  /// Whether the snapshots are identical (no changes).
  bool get isIdentical => changes.isEmpty;

  /// Gets only the added changes.
  List<SnapshotChange> get additions =>
      changes.where((c) => c.type == SnapshotChangeType.added).toList();

  /// Gets only the modified changes.
  List<SnapshotChange> get modifications =>
      changes.where((c) => c.type == SnapshotChangeType.modified).toList();

  /// Gets only the removed changes.
  List<SnapshotChange> get removals =>
      changes.where((c) => c.type == SnapshotChangeType.removed).toList();
}

/// Creates and manages snapshots for Rift boxes.
///
/// [SnapshotIsolation] provides MVCC-style snapshot isolation. Each
/// snapshot captures a consistent point-in-time view of a box.
class SnapshotIsolation {
  /// Active snapshots by box name, ordered by version.
  final Map<String, List<BoxSnapshotData>> _snapshots = {};

  /// The current version counter per box.
  final Map<String, int> _versionCounters = {};

  /// Maximum snapshots to retain per box (default: 10).
  int maxSnapshotsPerBox;

  /// Creates a [SnapshotIsolation].
  SnapshotIsolation({this.maxSnapshotsPerBox = 10});

  /// Creates a snapshot of the current state of [box].
  ///
  /// The snapshot captures all key-value pairs at the time of creation.
  /// Reads from the snapshot are isolated from subsequent writes.
  Future<BoxSnapshotData> createSnapshot(Box box) async {
    final boxName = box.name;
    final version = (_versionCounters[boxName] ?? 0) + 1;
    _versionCounters[boxName] = version;

    final snapshot = BoxSnapshotData(
      version: version,
      timestamp: DateTime.now(),
      data: box.toMap(),
      boxName: boxName,
    );

    _snapshots.putIfAbsent(boxName, () => []);
    _snapshots[boxName]!.add(snapshot);

    // Evict oldest snapshots if over limit
    while (_snapshots[boxName]!.length > maxSnapshotsPerBox) {
      _snapshots[boxName]!.removeAt(0);
    }

    return snapshot;
  }

  /// Gets the latest snapshot for [boxName], or null if none exists.
  BoxSnapshotData? getLatestSnapshot(String boxName) {
    final snapshots = _snapshots[boxName];
    if (snapshots == null || snapshots.isEmpty) return null;
    return snapshots.last;
  }

  /// Gets a snapshot for [boxName] at a specific [version].
  BoxSnapshotData? getSnapshot(String boxName, int version) {
    final snapshots = _snapshots[boxName];
    if (snapshots == null) return null;
    for (final s in snapshots) {
      if (s.version == version) return s;
    }
    return null;
  }

  /// Gets all snapshots for [boxName].
  List<BoxSnapshotData> getSnapshots(String boxName) =>
      List.unmodifiable(_snapshots[boxName] ?? []);

  /// Computes the diff between two snapshot versions of [boxName].
  SnapshotDiff? diff(String boxName, int fromVersion, int toVersion) {
    final from = getSnapshot(boxName, fromVersion);
    final to = getSnapshot(boxName, toVersion);
    if (from == null || to == null) return null;
    return SnapshotDiff.between(from, to);
  }

  /// Removes a specific snapshot.
  bool removeSnapshot(String boxName, int version) {
    final snapshots = _snapshots[boxName];
    if (snapshots == null) return false;
    snapshots.removeWhere((s) => s.version == version);
    return snapshots.every((s) => s.version != version);
  }

  /// Removes all snapshots for [boxName].
  void clearSnapshots(String boxName) {
    _snapshots.remove(boxName);
    _versionCounters.remove(boxName);
  }

  /// Removes all snapshots across all boxes.
  void clearAll() {
    _snapshots.clear();
    _versionCounters.clear();
  }

  /// The number of snapshots for [boxName].
  int snapshotCount(String boxName) => _snapshots[boxName]?.length ?? 0;

  /// All box names that have snapshots.
  Iterable<String> get boxNames => _snapshots.keys;
}
