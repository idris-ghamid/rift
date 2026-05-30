/// Master-slave and peer-to-peer replication support.
///
/// Provides replication between Rift instances for multi-device
/// or distributed scenarios. Supports multiple replication modes
/// and conflict resolution strategies.
///
/// Usage:
/// ```dart
/// final manager = ReplicationManager(
///   localNodeId: 'device_1',
///   mode: ReplicationMode.masterSlave,
/// );
///
/// // Add a replica
/// manager.addReplica(ReplicaNode(
///   id: 'device_2',
///   endpoint: 'https://sync.example.com',
///   role: ReplicaRole.slave,
/// ));
///
/// // Start replication
/// await manager.start();
///
/// // Monitor lag
/// print('Replication lag: ${manager.replicationLag}');
/// ```
library;

import 'dart:async';

/// Replication mode.
enum ReplicationMode {
  /// One master, multiple slaves. Only master accepts writes.
  masterSlave,

  /// All nodes are equal. Any node can accept writes.
  peerToPeer,
}

/// Role of a replica node.
enum ReplicaRole {
  /// The primary/master node that accepts writes.
  master,

  /// A secondary/slave node that replicates from master.
  slave,

  /// A peer node in a peer-to-peer setup.
  peer,
}

/// Status of a replica node.
enum ReplicaStatus {
  /// The node is connected and replicating.
  connected,

  /// The node is disconnected.
  disconnected,

  /// The node is currently syncing.
  syncing,

  /// The node has an error.
  error,
}

/// Strategies for resolving replication conflicts.
enum ConflictResolutionStrategy {
  /// The most recent write wins based on timestamp.
  lastWriteWins,

  /// The master node's version always wins.
  masterWins,

  /// The local node's version wins.
  localWins,

  /// Custom conflict resolution via a user-provided function.
  custom,
}

/// Represents a replication conflict between two versions.
class ReplicationConflict {
  /// The key that has conflicting versions.
  final String key;

  /// The local value.
  final dynamic localValue;

  /// The remote value.
  final dynamic remoteValue;

  /// The local version timestamp.
  final DateTime localTimestamp;

  /// The remote version timestamp.
  final DateTime remoteTimestamp;

  /// The source node ID.
  final String sourceNodeId;

  /// Creates a [ReplicationConflict].
  const ReplicationConflict({
    required this.key,
    this.localValue,
    this.remoteValue,
    required this.localTimestamp,
    required this.remoteTimestamp,
    required this.sourceNodeId,
  });
}

/// Represents a replica node in the replication topology.
class ReplicaNode {
  /// Unique identifier for this node.
  final String id;

  /// The endpoint URL for connecting to this replica.
  final String? endpoint;

  /// The role of this node.
  final ReplicaRole role;

  /// Current status of the node.
  ReplicaStatus status;

  /// Last known replication timestamp on this node.
  DateTime? lastReplicatedAt;

  /// Number of pending changes to replicate to this node.
  int pendingChanges;

  /// Creates a [ReplicaNode].
  ReplicaNode({
    required this.id,
    this.endpoint,
    this.role = ReplicaRole.slave,
    this.status = ReplicaStatus.disconnected,
    this.lastReplicatedAt,
    this.pendingChanges = 0,
  });

  /// The replication lag in milliseconds (time since last replication).
  int? get lagMs {
    if (lastReplicatedAt == null) return null;
    return DateTime.now().difference(lastReplicatedAt!).inMilliseconds;
  }
}

/// A replication event.
class ReplicationEvent {
  /// The type of event.
  final ReplicationEventType type;

  /// The source node ID.
  final String sourceNodeId;

  /// The key affected.
  final String? key;

  /// The value.
  final dynamic value;

  /// When this event occurred.
  final DateTime timestamp;

  /// Creates a [ReplicationEvent].
  const ReplicationEvent({
    required this.type,
    required this.sourceNodeId,
    this.key,
    this.value,
    required this.timestamp,
  });
}

/// Types of replication events.
enum ReplicationEventType {
  /// A key was created or updated.
  upsert,

  /// A key was deleted.
  delete,

  /// A full sync started.
  syncStart,

  /// A full sync completed.
  syncComplete,

  /// A conflict was detected.
  conflict,

  /// A replica connected.
  connected,

  /// A replica disconnected.
  disconnected,
}

/// Manages replication between Rift instances.
///
/// [ReplicationManager] coordinates data replication across
/// multiple nodes. It handles conflict detection and resolution,
/// lag monitoring, and automatic reconnection.
class ReplicationManager {
  /// The local node ID.
  final String localNodeId;

  /// The replication mode.
  final ReplicationMode mode;

  /// The conflict resolution strategy.
  final ConflictResolutionStrategy conflictStrategy;

  /// Custom conflict resolver (used when strategy is custom).
  final dynamic Function(ReplicationConflict)? customConflictResolver;

  /// Registered replica nodes.
  final Map<String, ReplicaNode> _replicas = {};

  /// Stream controller for replication events.
  final StreamController<ReplicationEvent> _eventController =
      StreamController.broadcast();

  /// Whether replication is currently active.
  bool _isRunning = false;

  /// Timer for periodic sync checks.
  Timer? _syncTimer;

  /// Interval for periodic sync checks.
  final Duration syncInterval;

  /// Local change queue awaiting replication.
  final List<ReplicationEvent> _pendingEvents = [];

  /// Creates a [ReplicationManager].
  ReplicationManager({
    required this.localNodeId,
    this.mode = ReplicationMode.masterSlave,
    this.conflictStrategy = ConflictResolutionStrategy.lastWriteWins,
    this.customConflictResolver,
    this.syncInterval = const Duration(seconds: 5),
  });

  /// Stream of replication events.
  Stream<ReplicationEvent> get events => _eventController.stream;

  /// Whether replication is running.
  bool get isRunning => _isRunning;

  /// The registered replica nodes.
  List<ReplicaNode> get replicas => List.unmodifiable(_replicas.values);

  /// The current replication lag in milliseconds (max across all replicas).
  int? get replicationLag {
    int? maxLag;
    for (final replica in _replicas.values) {
      final lag = replica.lagMs;
      if (lag != null) {
        maxLag = maxLag == null ? lag : (lag > maxLag ? lag : maxLag);
      }
    }
    return maxLag;
  }

  /// The number of pending changes awaiting replication.
  int get pendingChangeCount => _pendingEvents.length;

  /// Adds a replica node to the replication topology.
  void addReplica(ReplicaNode node) {
    _replicas[node.id] = node;
    _emitEvent(
      ReplicationEvent(
        type: ReplicationEventType.connected,
        sourceNodeId: node.id,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Removes a replica node.
  void removeReplica(String nodeId) {
    _replicas.remove(nodeId);
    _emitEvent(
      ReplicationEvent(
        type: ReplicationEventType.disconnected,
        sourceNodeId: nodeId,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Records a local change that needs to be replicated.
  void recordChange(String key, dynamic value, ReplicationEventType type) {
    if (!_isRunning) return;
    _pendingEvents.add(
      ReplicationEvent(
        type: type,
        sourceNodeId: localNodeId,
        key: key,
        value: value,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Starts the replication manager.
  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    // Start periodic sync
    _syncTimer = Timer.periodic(syncInterval, (_) => _sync());

    // Mark replicas as connecting
    for (final replica in _replicas.values) {
      replica.status = ReplicaStatus.syncing;
    }
  }

  /// Stops the replication manager.
  Future<void> stop() async {
    _isRunning = false;
    _syncTimer?.cancel();
    _syncTimer = null;

    for (final replica in _replicas.values) {
      replica.status = ReplicaStatus.disconnected;
    }
  }

  /// Forces an immediate sync of all pending changes.
  Future<void> forceSync() async {
    if (!_isRunning) return;
    await _sync();
  }

  Future<void> _sync() async {
    if (_pendingEvents.isEmpty) return;

    final eventsToSync = List<ReplicationEvent>.from(_pendingEvents);
    _pendingEvents.clear();

    for (final replica in _replicas.values) {
      if (replica.status == ReplicaStatus.disconnected) continue;

      replica.status = ReplicaStatus.syncing;
      try {
        // Simulate sending events to replica
        // In a real implementation, this would make HTTP/gRPC calls
        for (final event in eventsToSync) {
          _emitEvent(event);
        }
        replica.lastReplicatedAt = DateTime.now();
        replica.pendingChanges = 0;
        replica.status = ReplicaStatus.connected;
      } catch (e) {
        replica.status = ReplicaStatus.error;
        // Re-queue events for next sync
        _pendingEvents.addAll(eventsToSync);
      }
    }
  }

  /// Resolves a replication conflict using the configured strategy.
  dynamic resolveConflict(ReplicationConflict conflict) {
    switch (conflictStrategy) {
      case ConflictResolutionStrategy.lastWriteWins:
        return conflict.localTimestamp.isAfter(conflict.remoteTimestamp)
            ? conflict.localValue
            : conflict.remoteValue;
      case ConflictResolutionStrategy.masterWins:
        return mode == ReplicationMode.masterSlave
            ? conflict
                  .remoteValue // Remote is master
            : conflict.localValue;
      case ConflictResolutionStrategy.localWins:
        return conflict.localValue;
      case ConflictResolutionStrategy.custom:
        return customConflictResolver?.call(conflict) ?? conflict.localValue;
    }
  }

  void _emitEvent(ReplicationEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// Disposes the replication manager.
  void dispose() {
    stop();
    _eventController.close();
    _replicas.clear();
    _pendingEvents.clear();
  }
}
