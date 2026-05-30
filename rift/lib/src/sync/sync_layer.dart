import 'dart:async';

import 'package:rift/rift.dart';

/// Abstract interface for sync backends.
/// Implement this to connect Rift to any backend
/// (Supabase, Firebase, REST, WebSocket).
abstract class SyncBackend {
  /// Connect to the sync backend with the given [config].
  Future<void> connect(SyncConfig config);

  /// Disconnect from the sync backend.
  Future<void> disconnect();

  /// Push local changes to the backend.
  Future<SyncResult> pushChanges(List<SyncChange> changes);

  /// Pull remote changes from the backend since the given cursor.
  Future<List<SyncChange>> pullChanges(SyncCursor cursor);

  /// Stream of sync events (real-time updates).
  Stream<SyncEvent> get events;

  /// Current connection status.
  SyncStatus get status;
}

/// Configuration for a sync connection.
class SyncConfig {
  /// The endpoint URL for the sync backend.
  final String endpoint;

  /// Optional API key for authentication.
  final String? apiKey;

  /// Optional auth token for authentication.
  final String? authToken;

  /// How often to sync automatically.
  final Duration syncInterval;

  /// How to resolve conflicts.
  final ConflictResolution conflictResolution;

  /// Create sync configuration.
  SyncConfig({
    required this.endpoint,
    this.apiKey,
    this.authToken,
    this.syncInterval = const Duration(seconds: 30),
    this.conflictResolution = ConflictResolution.lastWriteWins,
  });
}

/// Strategy for resolving sync conflicts.
enum ConflictResolution {
  /// The last write (by timestamp) wins.
  lastWriteWins,

  /// The first write (by timestamp) wins.
  firstWriteWins,

  /// Merge both values if possible.
  merge,

  /// Custom resolution via a callback.
  custom,
}

/// Current status of the sync connection.
enum SyncStatus {
  /// Not connected.
  disconnected,

  /// Currently connecting.
  connecting,

  /// Connected and ready.
  connected,

  /// Currently syncing data.
  syncing,

  /// An error occurred.
  error,
}

/// A single change to be synced.
class SyncChange {
  /// The name of the box this change belongs to.
  final String boxName;

  /// The key of the changed entry.
  final String key;

  /// The type of change.
  final ChangeType type;

  /// The new value (null for deletions).
  final dynamic value;

  /// When this change occurred.
  final DateTime timestamp;

  /// The node that made the change.
  final String nodeId;

  /// Create a sync change.
  SyncChange({
    required this.boxName,
    required this.key,
    required this.type,
    this.value,
    required this.timestamp,
    required this.nodeId,
  });

  Map<String, dynamic> toJson() => {
    'box': boxName,
    'key': key,
    'type': type.name,
    'value': value,
    'timestamp': timestamp.toIso8601String(),
    'nodeId': nodeId,
  };

  static SyncChange fromJson(Map<String, dynamic> json) => SyncChange(
    boxName: json['box'] as String,
    key: json['key'] as String,
    type: ChangeType.values.firstWhere((e) => e.name == json['type']),
    value: json['value'],
    timestamp: DateTime.parse(json['timestamp'] as String),
    nodeId: json['nodeId'] as String,
  );
}

/// Type of change operation.
enum ChangeType {
  /// A new key-value pair was created.
  create,

  /// An existing key-value pair was updated.
  update,

  /// A key-value pair was deleted.
  delete,
}

/// Result of a push operation.
class SyncResult {
  /// Whether the push was successful.
  final bool success;

  /// Number of changes that were pushed.
  final int pushedCount;

  /// Any conflicts that were detected.
  final List<SyncConflict> conflicts;

  /// Error message if the push failed.
  final String? error;

  /// Create a sync result.
  SyncResult({
    required this.success,
    this.pushedCount = 0,
    this.conflicts = const [],
    this.error,
  });
}

/// A conflict between local and remote changes.
class SyncConflict {
  /// The local change.
  final SyncChange local;

  /// The remote change.
  final SyncChange remote;

  /// How the conflict was resolved.
  final ConflictResolution resolution;

  /// The resolved value after conflict resolution.
  final dynamic resolvedValue;

  /// Create a sync conflict.
  SyncConflict({
    required this.local,
    required this.remote,
    required this.resolution,
    this.resolvedValue,
  });
}

/// A real-time event from the sync backend.
class SyncEvent {
  /// The type of event.
  final SyncEventType type;

  /// Event data.
  final dynamic data;

  /// Create a sync event.
  SyncEvent(this.type, this.data);

  @override
  String toString() => 'SyncEvent($type, $data)';
}

/// In-memory sync backend for testing.
/// Stores all changes in memory and allows pulling them back.
class InMemorySyncBackend implements SyncBackend {
  SyncStatus _status = SyncStatus.disconnected;
  SyncConfig? _config;
  final List<SyncChange> _changes = [];
  final StreamController<SyncEvent> _eventController =
      StreamController.broadcast();

  @override
  Future<void> connect(SyncConfig config) async {
    _status = SyncStatus.connecting;
    _config = config;
    await Future.delayed(const Duration(milliseconds: 10));
    _status = SyncStatus.connected;
    _eventController.add(SyncEvent(SyncEventType.connected, null));
  }

  @override
  Future<void> disconnect() async {
    _status = SyncStatus.disconnected;
    _config = null;
    _eventController.add(SyncEvent(SyncEventType.disconnected, null));
  }

  @override
  Future<SyncResult> pushChanges(List<SyncChange> changes) async {
    _status = SyncStatus.syncing;
    _eventController.add(SyncEvent(SyncEventType.syncStarted, null));

    await Future.delayed(const Duration(milliseconds: 10));

    _changes.addAll(changes);

    _status = SyncStatus.connected;
    _eventController.add(
      SyncEvent(SyncEventType.syncCompleted, changes.length),
    );

    return SyncResult(success: true, pushedCount: changes.length);
  }

  @override
  Future<List<SyncChange>> pullChanges(SyncCursor cursor) async {
    _status = SyncStatus.syncing;
    await Future.delayed(const Duration(milliseconds: 10));

    final result = _changes
        .where((c) => c.timestamp.isAfter(cursor.lastSync))
        .toList();

    _status = SyncStatus.connected;
    return result;
  }

  @override
  Stream<SyncEvent> get events => _eventController.stream;

  @override
  SyncStatus get status => _status;

  /// Get all stored changes (for testing).
  List<SyncChange> get allChanges => List.unmodifiable(_changes);

  /// Clear all stored changes (for testing).
  void clearChanges() => _changes.clear();

  /// Dispose the backend.
  void dispose() {
    _eventController.close();
  }
}

/// RiftSync - main sync manager.
/// Coordinates synchronization between local boxes and a remote backend.
class RiftSync {
  SyncBackend? _backend;
  SyncConfig? _config;
  final Map<String, Box> _syncedBoxes = {};
  final ChangeTracker _changeTracker = ChangeTracker();
  Timer? _syncTimer;
  final StreamController<SyncEvent> _eventController =
      StreamController.broadcast();
  String _nodeId = 'node_${DateTime.now().millisecondsSinceEpoch}';

  /// Configure sync with a backend and config.
  void configure(SyncBackend backend, SyncConfig config) {
    _backend = backend;
    _config = config;
  }

  /// Set the node identifier for this sync instance.
  void setNodeId(String id) {
    _nodeId = id;
  }

  /// Register a box for syncing.
  void registerBox(String name, Box box) {
    _syncedBoxes[name] = box;

    // Watch for local changes
    box.watch().listen((event) {
      final key = event.key?.toString() ?? '';
      final isDelete = event.deleted;
      final existing = _changeTracker.getChanges(name);
      final isNew =
          existing.isEmpty ||
          !existing.any((c) => c.key == key && c.type == ChangeType.create);

      _changeTracker.track(
        name,
        key,
        isDelete
            ? ChangeType.delete
            : (isNew ? ChangeType.create : ChangeType.update),
        event.value,
        nodeId: _nodeId,
      );
    });
  }

  /// Start periodic sync.
  Future<void> startSync() async {
    if (_backend == null || _config == null) {
      throw RiftError('Sync not configured. Call configure() first.');
    }

    await _backend!.connect(_config!);
    _eventController.add(SyncEvent(SyncEventType.connected, null));

    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_config!.syncInterval, (_) async {
      await _performSync();
    });
  }

  /// Stop syncing.
  Future<void> stopSync() async {
    _syncTimer?.cancel();
    _syncTimer = null;
    if (_backend != null) {
      await _backend!.disconnect();
    }
    _eventController.add(SyncEvent(SyncEventType.disconnected, null));
  }

  /// Force a full sync cycle.
  Future<SyncResult> forceSync() async {
    if (_backend == null || _config == null) {
      throw RiftError('Sync not configured. Call configure() first.');
    }
    return _performSync();
  }

  Future<SyncResult> _performSync() async {
    if (_backend == null) {
      return SyncResult(success: false, error: 'Backend not configured');
    }

    _eventController.add(SyncEvent(SyncEventType.syncStarted, null));

    try {
      // Push local changes
      final allChanges = <SyncChange>[];
      for (final boxName in _syncedBoxes.keys) {
        allChanges.addAll(_changeTracker.getChanges(boxName));
      }

      SyncResult pushResult = SyncResult(success: true);
      if (allChanges.isNotEmpty) {
        pushResult = await _backend!.pushChanges(allChanges);
        if (pushResult.success) {
          for (final boxName in _syncedBoxes.keys) {
            _changeTracker.clearChanges(boxName);
          }
        }
      }

      // Pull remote changes
      final cursor = SyncCursor(
        DateTime.now().subtract(_config!.syncInterval),
        null,
      );
      final remoteChanges = await _backend!.pullChanges(cursor);

      // Apply remote changes locally
      for (final change in remoteChanges) {
        final box = _syncedBoxes[change.boxName];
        if (box != null) {
          switch (change.type) {
            case ChangeType.create:
            case ChangeType.update:
              await box.put(change.key, change.value);
              break;
            case ChangeType.delete:
              await box.delete(change.key);
              break;
          }
        }
      }

      _eventController.add(
        SyncEvent(SyncEventType.syncCompleted, {
          'pushed': pushResult.pushedCount,
          'pulled': remoteChanges.length,
        }),
      );

      return SyncResult(
        success: true,
        pushedCount: pushResult.pushedCount,
        conflicts: pushResult.conflicts,
      );
    } catch (e) {
      _eventController.add(SyncEvent(SyncEventType.error, e.toString()));
      return SyncResult(success: false, error: e.toString());
    }
  }

  /// Get sync status.
  SyncStatus get status => _backend?.status ?? SyncStatus.disconnected;

  /// Stream of sync events.
  Stream<SyncEvent> get events => _eventController.stream;

  /// The change tracker.
  ChangeTracker get changeTracker => _changeTracker;

  /// Dispose the sync manager.
  void dispose() {
    _syncTimer?.cancel();
    _eventController.close();
  }
}

/// Tracks local changes for sync.
class ChangeTracker {
  final Map<String, List<SyncChange>> _changes = {};

  /// Track a change.
  void track(
    String boxName,
    String key,
    ChangeType type,
    dynamic value, {
    String? nodeId,
  }) {
    _changes.putIfAbsent(boxName, () => []);
    _changes[boxName]!.add(
      SyncChange(
        boxName: boxName,
        key: key,
        type: type,
        value: value,
        timestamp: DateTime.now(),
        nodeId: nodeId ?? 'unknown',
      ),
    );
  }

  /// Get tracked changes for a box, optionally since a given time.
  List<SyncChange> getChanges(String boxName, {DateTime? since}) {
    final changes = _changes[boxName] ?? [];
    if (since == null) return List.unmodifiable(changes);
    return changes.where((c) => c.timestamp.isAfter(since)).toList();
  }

  /// Clear tracked changes for a box.
  void clearChanges(String boxName) {
    _changes.remove(boxName);
  }

  /// Clear all tracked changes.
  void clearAll() {
    _changes.clear();
  }

  /// Total number of pending changes across all boxes.
  int get totalChangeCount =>
      _changes.values.fold(0, (sum, list) => sum + list.length);
}
