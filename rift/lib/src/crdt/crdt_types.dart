import 'dart:math';

/// CRDT types for conflict-free distributed data.
/// Supports counters, sets, maps, and registers with automatic conflict resolution.

/// G-Counter (Grow-only counter) - can only increment.
/// Each node maintains its own count. The total value is the sum of all
/// node counts. Merge takes the maximum per node.
class GCounter {
  /// The identifier for this node.
  final String nodeId;

  final Map<String, int> _counts;

  /// Create a G-Counter for the given [nodeId], starting at 0.
  GCounter(this.nodeId) : _counts = {nodeId: 0};

  GCounter._(this.nodeId, this._counts);

  /// The current total value (sum of all node counts).
  int get value => _counts.values.fold(0, (a, b) => a + b);

  /// Increment this node's counter by [amount] (default 1).
  void increment([int amount = 1]) {
    _counts[nodeId] = (_counts[nodeId] ?? 0) + amount;
  }

  /// Get the count for a specific node.
  int countFor(String nodeId) => _counts[nodeId] ?? 0;

  /// Merge with another G-Counter by taking the max per node.
  GCounter merge(GCounter other) {
    final merged = Map<String, int>.from(_counts);
    for (final entry in other._counts.entries) {
      merged[entry.key] = max(merged[entry.key] ?? 0, entry.value);
    }
    return GCounter._(nodeId, merged);
  }

  /// Serialize to a JSON-serializable map.
  Map<String, dynamic> toJson() => {
    'nodeId': nodeId,
    'counts': Map<String, dynamic>.from(_counts),
  };

  /// Deserialize from a JSON map.
  static GCounter fromJson(Map<String, dynamic> json) {
    final counts = (json['counts'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as int),
    );
    return GCounter._(json['nodeId'] as String, counts);
  }

  @override
  String toString() => 'GCounter(nodeId: $nodeId, value: $value)';
}

/// PN-Counter (Positive-Negative counter) - can increment and decrement.
/// Composed of two G-Counters: one for increments and one for decrements.
class PNCounter {
  /// The identifier for this node.
  final String nodeId;

  final GCounter _positive;
  final GCounter _negative;

  /// Create a PN-Counter for the given [nodeId], starting at 0.
  PNCounter(this.nodeId)
    : _positive = GCounter(nodeId),
      _negative = GCounter(nodeId);

  PNCounter._(this.nodeId, this._positive, this._negative);

  /// The current value (positive count minus negative count).
  int get value => _positive.value - _negative.value;

  /// Increment the counter by [amount] (default 1).
  void increment([int amount = 1]) {
    _positive.increment(amount);
  }

  /// Decrement the counter by [amount] (default 1).
  void decrement([int amount = 1]) {
    _negative.increment(amount);
  }

  /// Merge with another PN-Counter.
  PNCounter merge(PNCounter other) {
    return PNCounter._(
      nodeId,
      _positive.merge(other._positive),
      _negative.merge(other._negative),
    );
  }

  /// Serialize to a JSON-serializable map.
  Map<String, dynamic> toJson() => {
    'nodeId': nodeId,
    'positive': _positive.toJson(),
    'negative': _negative.toJson(),
  };

  /// Deserialize from a JSON map.
  static PNCounter fromJson(Map<String, dynamic> json) {
    return PNCounter._(
      json['nodeId'] as String,
      GCounter.fromJson(json['positive'] as Map<String, dynamic>),
      GCounter.fromJson(json['negative'] as Map<String, dynamic>),
    );
  }

  @override
  String toString() => 'PNCounter(nodeId: $nodeId, value: $value)';
}

/// G-Set (Grow-only set) - can only add elements.
/// Merge is the union of both sets.
class GSet<T> {
  final Set<T> _elements;

  /// Create an empty G-Set.
  GSet() : _elements = {};

  GSet._(this._elements);

  /// An unmodifiable view of the current elements.
  Set<T> get value => Set.unmodifiable(_elements);

  /// Add an [element] to the set.
  void add(T element) {
    _elements.add(element);
  }

  /// Whether the set contains [element].
  bool contains(T element) => _elements.contains(element);

  /// The number of elements in the set.
  int get length => _elements.length;

  /// Merge with another G-Set (union).
  GSet<T> merge(GSet<T> other) => GSet<T>._(_elements.union(other._elements));

  /// Serialize to a JSON-serializable map.
  Map<String, dynamic> toJson() => {'elements': _elements.toList()};

  /// Deserialize from a JSON map.
  static GSet<T> fromJson<T>(Map<String, dynamic> json) {
    final elements = (json['elements'] as List).cast<T>().toSet();
    return GSet<T>._(elements);
  }

  @override
  String toString() => 'GSet($value)';
}

/// OR-Set (Observed-Remove set) - supports add and remove with conflict resolution.
/// Each add operation attaches a unique tag. Remove only removes tags that have
/// been observed, so concurrent add and remove operations resolve in favor of add.
class ORSet<T> {
  final String _nodeId;
  int _counter = 0;

  /// Maps each element to the set of unique tags for its additions.
  final Map<T, Set<String>> _addTags;

  /// Set of tags that have been removed (tombstones).
  final Set<String> _removeTags;

  /// Create an OR-Set for the given [nodeId].
  ORSet(this._nodeId) : _addTags = {}, _removeTags = {};

  ORSet._(this._nodeId, this._counter, this._addTags, this._removeTags);

  /// The current visible elements (added tags minus removed tags).
  Set<T> get value {
    final result = <T>{};
    for (final entry in _addTags.entries) {
      if (entry.value.difference(_removeTags).isNotEmpty) {
        result.add(entry.key);
      }
    }
    return Set.unmodifiable(result);
  }

  /// Add an [element] to the set.
  void add(T element) {
    final tag = '${_nodeId}_${_counter++}';
    _addTags.putIfAbsent(element, () => <String>{});
    _addTags[element]!.add(tag);
  }

  /// Remove an [element] from the set.
  /// Only removes tags that have been observed.
  void remove(T element) {
    final tags = _addTags[element];
    if (tags != null) {
      _removeTags.addAll(tags);
    }
  }

  /// Whether the set currently contains [element].
  bool contains(T element) {
    final tags = _addTags[element];
    if (tags == null) return false;
    return tags.difference(_removeTags).isNotEmpty;
  }

  /// The number of visible elements.
  int get length => value.length;

  /// Merge with another OR-Set.
  /// Union of add tags, union of remove tags.
  ORSet<T> merge(ORSet<T> other) {
    final mergedAddTags = <T, Set<String>>{};
    for (final entry in _addTags.entries) {
      mergedAddTags[entry.key] = Set<String>.from(entry.value);
    }
    for (final entry in other._addTags.entries) {
      mergedAddTags.putIfAbsent(entry.key, () => <String>{});
      mergedAddTags[entry.key]!.addAll(entry.value);
    }
    final mergedRemoveTags = _removeTags.union(other._removeTags);
    final maxCounter = max(_counter, other._counter);
    return ORSet<T>._(_nodeId, maxCounter, mergedAddTags, mergedRemoveTags);
  }

  @override
  String toString() => 'ORSet($value)';
}

/// LWW-Register (Last-Writer-Wins register) - single value with timestamp.
/// When merging, the value with the later timestamp wins.
/// Ties are broken by nodeId comparison for determinism.
class LWWRegister<T> {
  T _value;
  DateTime _timestamp;
  final String _nodeId;

  /// Create a LWW-Register with an initial [value] and [nodeId].
  LWWRegister(this._value, this._nodeId) : _timestamp = DateTime.now();

  LWWRegister._(this._value, this._timestamp, this._nodeId);

  /// The current value.
  T get value => _value;

  /// The timestamp of the last write.
  DateTime get timestamp => _timestamp;

  /// The node that last wrote the value.
  String get nodeId => _nodeId;

  /// Set a new value, updating the timestamp.
  void set(T newValue) {
    _value = newValue;
    _timestamp = DateTime.now();
  }

  /// Set a new value with a specific timestamp (for importing).
  void setWithTimestamp(T newValue, DateTime newTimestamp) {
    if (!newTimestamp.isBefore(_timestamp)) {
      _value = newValue;
      _timestamp = newTimestamp;
    }
  }

  /// Merge with another LWW-Register.
  /// The register with the later timestamp wins.
  /// Ties are broken by comparing nodeIds.
  LWWRegister<T> merge(LWWRegister<T> other) {
    if (other._timestamp.isAfter(_timestamp)) {
      return other;
    } else if (_timestamp.isAfter(other._timestamp)) {
      return this;
    } else {
      // Timestamps are equal, break tie by nodeId
      return _nodeId.compareTo(other._nodeId) >= 0 ? this : other;
    }
  }

  /// Serialize to a JSON-serializable map.
  Map<String, dynamic> toJson() => {
    'value': _value,
    'timestamp': _timestamp.toIso8601String(),
    'nodeId': _nodeId,
  };

  /// Deserialize from a JSON map.
  static LWWRegister<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(dynamic) fromValue,
  ) {
    return LWWRegister<T>._(
      fromValue(json['value']),
      DateTime.parse(json['timestamp'] as String),
      json['nodeId'] as String,
    );
  }

  @override
  String toString() => 'LWWRegister(value: $_value, timestamp: $_timestamp)';
}

/// LWW-Map (Last-Writer-Wins map) - a map where each key has an independent
/// LWW-Register, so conflicts are resolved per-key.
class LWWMap<K, V> {
  final String _nodeId;
  final Map<K, LWWRegister<V>> _registers = {};

  /// Create an empty LWW-Map with the given [nodeId].
  LWWMap(this._nodeId);

  /// The current key-value pairs (resolved values).
  Map<K, V> get value {
    final result = <K, V>{};
    for (final entry in _registers.entries) {
      result[entry.key] = entry.value.value;
    }
    return Map.unmodifiable(result);
  }

  /// The keys in the map.
  Iterable<K> get keys => _registers.keys;

  /// The number of entries in the map.
  int get length => _registers.length;

  /// Set a value for [key].
  void put(K key, V value) {
    if (_registers.containsKey(key)) {
      _registers[key]!.set(value);
    } else {
      _registers[key] = LWWRegister<V>(value, _nodeId);
    }
  }

  /// Get the value for [key], or null if not present.
  V? get(K key) => _registers[key]?.value;

  /// Whether the map contains [key].
  bool containsKey(K key) => _registers.containsKey(key);

  /// Remove a key by setting it to a tombstone marker.
  /// In a LWW-Map, deletion is handled by setting a special marker.
  void remove(K key) {
    if (_registers.containsKey(key)) {
      _registers[key]!.set(null as V);
    }
  }

  /// Merge with another LWW-Map.
  /// Each key is resolved independently using LWW semantics.
  LWWMap<K, V> merge(LWWMap<K, V> other) {
    final merged = LWWMap<K, V>(_nodeId);
    final allKeys = <K>{..._registers.keys, ...other._registers.keys};
    for (final key in allKeys) {
      final local = _registers[key];
      final remote = other._registers[key];
      if (local != null && remote != null) {
        merged._registers[key] = local.merge(remote);
      } else if (local != null) {
        merged._registers[key] = LWWRegister<V>._(
          local.value,
          local.timestamp,
          local.nodeId,
        );
      } else if (remote != null) {
        merged._registers[key] = LWWRegister<V>._(
          remote.value,
          remote.timestamp,
          remote.nodeId,
        );
      }
    }
    return merged;
  }

  @override
  String toString() => 'LWWMap($value)';
}
