import 'dart:math';

/// A CRDT document that can sync across devices without conflicts.
/// Uses a vector clock to track causality and resolves conflicts
/// using last-writer-wins semantics with vector clock comparison.
class CRDTDocument {
  /// The identifier for this node.
  final String nodeId;

  final Map<String, _CRDTValue> _data;
  final Map<String, int> _vectorClock; // nodeId → counter

  /// Create a CRDTDocument for the given [nodeId].
  CRDTDocument(this.nodeId) : _data = {}, _vectorClock = {nodeId: 0};

  CRDTDocument._(this.nodeId, this._data, this._vectorClock);

  /// Put a value for [key]. Increments the local vector clock.
  void put(String key, dynamic value) {
    _vectorClock[nodeId] = (_vectorClock[nodeId] ?? 0) + 1;
    _data[key] = _CRDTValue(
      value: value,
      vectorClock: Map<String, int>.from(_vectorClock),
      deleted: false,
      timestamp: DateTime.now(),
      nodeId: nodeId,
    );
  }

  /// Delete a value for [key] (tombstone).
  void delete(String key) {
    if (_data.containsKey(key) && !_data[key]!.deleted) {
      _vectorClock[nodeId] = (_vectorClock[nodeId] ?? 0) + 1;
      _data[key] = _CRDTValue(
        value: null,
        vectorClock: Map<String, int>.from(_vectorClock),
        deleted: true,
        timestamp: DateTime.now(),
        nodeId: nodeId,
      );
    }
  }

  /// Get the current value for [key], or null if not present or deleted.
  dynamic get(String key) {
    final entry = _data[key];
    if (entry == null || entry.deleted) return null;
    return entry.value;
  }

  /// Whether the document contains a non-deleted value for [key].
  bool containsKey(String key) {
    final entry = _data[key];
    return entry != null && !entry.deleted;
  }

  /// All non-deleted keys.
  Iterable<String> get keys =>
      _data.entries.where((e) => !e.value.deleted).map((e) => e.key);

  /// The current vector clock state.
  Map<String, int> get vectorClock => Map.unmodifiable(_vectorClock);

  /// The current number of non-deleted entries.
  int get length => _data.values.where((v) => !v.deleted).length;

  /// Merge with another CRDTDocument.
  /// Uses vector clock comparison for conflict resolution:
  /// - If one value's clock dominates, that value wins.
  /// - If clocks are concurrent, uses timestamp then nodeId as tiebreaker.
  CRDTDocument merge(CRDTDocument other) {
    final merged = CRDTDocument._(
      nodeId,
      Map<String, _CRDTValue>.from(_data),
      _mergeVectorClocks(_vectorClock, other._vectorClock),
    );

    for (final entry in other._data.entries) {
      final local = _data[entry.key];
      final remote = entry.value;

      if (local == null) {
        merged._data[entry.key] = remote;
      } else {
        // Compare vector clocks
        final comparison = _compareVectorClocks(
          local.vectorClock,
          remote.vectorClock,
        );
        if (comparison < 0) {
          // Remote dominates
          merged._data[entry.key] = remote;
        } else if (comparison > 0) {
          // Local dominates, keep local (already in merged)
        } else {
          // Concurrent - use timestamp, then nodeId as tiebreaker
          if (remote.timestamp.isAfter(local.timestamp)) {
            merged._data[entry.key] = remote;
          } else if (local.timestamp.isAfter(remote.timestamp)) {
            // Keep local
          } else {
            // Same timestamp, use nodeId
            if (remote.nodeId.compareTo(local.nodeId) > 0) {
              merged._data[entry.key] = remote;
            }
          }
        }
      }
    }

    return merged;
  }

  /// Export changes since a given vector clock state.
  /// Returns a map with 'changes' (list of key-value pairs) and
  /// 'vectorClock' (the current vector clock).
  Map<String, dynamic> exportChanges(Map<String, int> sinceClock) {
    final changes = <Map<String, dynamic>>[];
    for (final entry in _data.entries) {
      final vc = entry.value.vectorClock;
      if (_hasChangedSince(vc, sinceClock)) {
        changes.add({
          'key': entry.key,
          'value': entry.value.value,
          'deleted': entry.value.deleted,
          'vectorClock': vc,
          'timestamp': entry.value.timestamp.toIso8601String(),
          'nodeId': entry.value.nodeId,
        });
      }
    }
    return {
      'changes': changes,
      'vectorClock': Map<String, dynamic>.from(_vectorClock),
      'nodeId': nodeId,
    };
  }

  /// Import changes from another node.
  void importChanges(Map<String, dynamic> changesData) {
    final changes = changesData['changes'] as List;
    final remoteNodeId = changesData['nodeId'] as String;

    for (final change in changes) {
      final key = change['key'] as String;
      final value = change['value'];
      final deleted = change['deleted'] as bool;
      final remoteVC = (change['vectorClock'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as int),
      );
      final timestamp = DateTime.parse(change['timestamp'] as String);
      final changeNodeId = change['nodeId'] as String;

      final local = _data[key];
      if (local == null) {
        _data[key] = _CRDTValue(
          value: value,
          vectorClock: remoteVC,
          deleted: deleted,
          timestamp: timestamp,
          nodeId: changeNodeId,
        );
      } else {
        final comparison = _compareVectorClocks(local.vectorClock, remoteVC);
        if (comparison < 0) {
          _data[key] = _CRDTValue(
            value: value,
            vectorClock: remoteVC,
            deleted: deleted,
            timestamp: timestamp,
            nodeId: changeNodeId,
          );
        } else if (comparison == 0) {
          if (timestamp.isAfter(local.timestamp)) {
            _data[key] = _CRDTValue(
              value: value,
              vectorClock: remoteVC,
              deleted: deleted,
              timestamp: timestamp,
              nodeId: changeNodeId,
            );
          } else if (timestamp == local.timestamp &&
              changeNodeId.compareTo(local.nodeId) > 0) {
            _data[key] = _CRDTValue(
              value: value,
              vectorClock: remoteVC,
              deleted: deleted,
              timestamp: timestamp,
              nodeId: changeNodeId,
            );
          }
        }
      }
    }

    // Update vector clock
    final remoteClock = (changesData['vectorClock'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as int));
    for (final entry in remoteClock.entries) {
      _vectorClock[entry.key] = max(_vectorClock[entry.key] ?? 0, entry.value);
    }
  }

  /// Check if a vector clock indicates changes since the given clock state.
  bool _hasChangedSince(Map<String, int> vc, Map<String, int> sinceClock) {
    for (final entry in vc.entries) {
      final sinceValue = sinceClock[entry.key] ?? 0;
      if (entry.value > sinceValue) return true;
    }
    return false;
  }

  /// Merge two vector clocks by taking the max per node.
  static Map<String, int> _mergeVectorClocks(
    Map<String, int> a,
    Map<String, int> b,
  ) {
    final result = Map<String, int>.from(a);
    for (final entry in b.entries) {
      result[entry.key] = max(result[entry.key] ?? 0, entry.value);
    }
    return result;
  }

  /// Compare two vector clocks.
  /// Returns -1 if b dominates a (a < b), 1 if a dominates b (a > b),
  /// 0 if they are concurrent.
  static int _compareVectorClocks(Map<String, int> a, Map<String, int> b) {
    final allKeys = <String>{...a.keys, ...b.keys};
    bool aGreater = false;
    bool bGreater = false;

    for (final key in allKeys) {
      final aVal = a[key] ?? 0;
      final bVal = b[key] ?? 0;
      if (aVal > bVal) aGreater = true;
      if (bVal > aVal) bGreater = true;
    }

    if (aGreater && !bGreater) return 1;
    if (bGreater && !aGreater) return -1;
    return 0; // concurrent or equal
  }

  /// Serialize the full document state.
  Map<String, dynamic> toJson() {
    final dataJson = <String, dynamic>{};
    for (final entry in _data.entries) {
      dataJson[entry.key] = {
        'value': entry.value.value,
        'deleted': entry.value.deleted,
        'vectorClock': entry.value.vectorClock,
        'timestamp': entry.value.timestamp.toIso8601String(),
        'nodeId': entry.value.nodeId,
      };
    }
    return {
      'nodeId': nodeId,
      'data': dataJson,
      'vectorClock': Map<String, dynamic>.from(_vectorClock),
    };
  }

  /// Deserialize from a JSON map.
  static CRDTDocument fromJson(Map<String, dynamic> json) {
    final data = <String, _CRDTValue>{};
    final dataJson = json['data'] as Map<String, dynamic>;
    for (final entry in dataJson.entries) {
      final v = entry.value as Map<String, dynamic>;
      data[entry.key] = _CRDTValue(
        value: v['value'],
        deleted: v['deleted'] as bool,
        vectorClock: (v['vectorClock'] as Map<String, dynamic>).map(
          (k, val) => MapEntry(k, val as int),
        ),
        timestamp: DateTime.parse(v['timestamp'] as String),
        nodeId: v['nodeId'] as String,
      );
    }
    final vectorClock = (json['vectorClock'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as int),
    );
    return CRDTDocument._(json['nodeId'] as String, data, vectorClock);
  }

  @override
  String toString() => 'CRDTDocument(nodeId: $nodeId, entries: $length)';
}

/// Internal representation of a CRDT value with metadata.
class _CRDTValue {
  final dynamic value;
  final Map<String, int> vectorClock;
  final bool deleted;
  final DateTime timestamp;
  final String nodeId;

  _CRDTValue({
    required this.value,
    required this.vectorClock,
    required this.deleted,
    required this.timestamp,
    required this.nodeId,
  });
}
