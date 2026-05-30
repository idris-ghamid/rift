/// Data partitioning for large datasets.
///
/// Partitions data across multiple boxes for better performance
/// with large datasets. Supports hash, range, and custom
/// partitioning strategies.
///
/// Usage:
/// ```dart
/// final strategy = HashPartitionStrategy(partitions: 4);
/// final partitioned = PartitionedBox(
///   name: 'users',
///   strategy: strategy,
///   openBox: (name) => Rift.openBox<Map>(name),
/// );
/// await partitioned.initialize();
///
/// // Data is automatically routed to the correct partition
/// await partitioned.put('user_123', {'name': 'Idris'});
/// final user = partitioned.get('user_123');
///
/// // Cross-partition queries
/// final allUsers = await partitioned.query((data) => data['age'] > 18);
/// ```
library;

import 'package:rift/rift.dart';

/// Strategy for partitioning data.
enum PartitionStrategyType {
  /// Distribute keys by hash modulo partition count.
  hash,

  /// Distribute keys by value ranges.
  range,

  /// Custom partitioning logic.
  custom,
}

/// Abstract base class for partition strategies.
///
/// A partition strategy determines which partition a given key
/// should be stored in.
abstract class PartitionStrategy {
  /// The type of this partition strategy.
  PartitionStrategyType get type;

  /// The number of partitions.
  int get partitionCount;

  /// Determines the partition index for the given [key].
  ///
  /// Returns a value in the range [0, partitionCount).
  int partitionFor(dynamic key);

  /// Determines the partitions that might contain keys matching
  /// the given [predicate]. For full scans, returns all partitions.
  List<int> partitionsForQuery(bool Function(dynamic key)? predicate) {
    // Default: scan all partitions
    return List.generate(partitionCount, (i) => i);
  }
}

/// Hash-based partitioning strategy.
///
/// Distributes keys uniformly across partitions using a hash function.
/// This provides even distribution for most key types.
class HashPartitionStrategy extends PartitionStrategy {
  @override
  final int partitionCount;

  @override
  PartitionStrategyType get type => PartitionStrategyType.hash;

  /// Creates a [HashPartitionStrategy] with the given [partitionCount].
  HashPartitionStrategy({this.partitionCount = 4});

  @override
  int partitionFor(dynamic key) {
    final hash = key.hashCode;
    return (hash & 0x7FFFFFFF) % partitionCount;
  }
}

/// Range-based partitioning strategy.
///
/// Distributes keys based on value ranges. Keys are assigned to
/// partitions based on defined range boundaries.
class RangePartitionStrategy extends PartitionStrategy {
  /// The range boundaries that define the partitions.
  /// If boundaries are [a, b, c], partitions are:
  ///   - partition 0: keys < a
  ///   - partition 1: a <= keys < b
  ///   - partition 2: b <= keys < c
  ///   - partition 3: keys >= c
  final List<dynamic> boundaries;

  @override
  PartitionStrategyType get type => PartitionStrategyType.range;

  /// Creates a [RangePartitionStrategy] with the given [boundaries].
  RangePartitionStrategy(this.boundaries);

  @override
  int get partitionCount => boundaries.length + 1;

  @override
  int partitionFor(dynamic key) {
    for (int i = 0; i < boundaries.length; i++) {
      if (_compare(key, boundaries[i]) < 0) return i;
    }
    return boundaries.length;
  }

  @override
  List<int> partitionsForQuery(bool Function(dynamic key)? predicate) {
    // Range queries can potentially narrow down partitions
    // but without a specific range, scan all
    return List.generate(partitionCount, (i) => i);
  }

  int _compare(dynamic a, dynamic b) {
    if (a is Comparable && b is Comparable) {
      return (a).compareTo(b);
    }
    return a.toString().compareTo(b.toString());
  }
}

/// Custom partitioning strategy using a user-provided function.
class CustomPartitionStrategy extends PartitionStrategy {
  final int _partitionCount;
  final int Function(dynamic key) _partitionFunction;
  final List<int> Function(bool Function(dynamic key)?) _queryFunction;

  @override
  PartitionStrategyType get type => PartitionStrategyType.custom;

  @override
  int get partitionCount => _partitionCount;

  /// Creates a [CustomPartitionStrategy] with the given [partitionCount],
  /// [partitionFunction] that maps keys to partition indices, and optional
  /// [queryFunction] that maps query predicates to relevant partitions.
  CustomPartitionStrategy({
    required int partitionCount,
    required int Function(dynamic key) partitionFunction,
    List<int> Function(bool Function(dynamic key)?)? queryFunction,
  }) : _partitionCount = partitionCount,
       _partitionFunction = partitionFunction,
       _queryFunction =
           queryFunction ?? ((_) => List.generate(partitionCount, (i) => i));

  @override
  int partitionFor(dynamic key) => _partitionFunction(key);

  @override
  List<int> partitionsForQuery(bool Function(dynamic key)? predicate) =>
      _queryFunction(predicate);
}

/// A virtual box that delegates to partition boxes.
///
/// [PartitionedBox] provides the same interface as a regular [Box],
/// but automatically routes operations to the correct partition
/// based on the configured [PartitionStrategy].
class PartitionedBox {
  /// The name of this virtual partitioned box.
  final String name;

  /// The partitioning strategy.
  final PartitionStrategy strategy;

  /// Function to open a partition box by name.
  final Future<Box<Map>> Function(String name) openBox;

  /// The opened partition boxes, indexed by partition number.
  final Map<int, Box<Map>> _partitions = {};

  /// Whether the partitioned box has been initialized.
  bool _initialized = false;

  /// Creates a [PartitionedBox].
  PartitionedBox({
    required this.name,
    required this.strategy,
    required this.openBox,
  });

  /// Initializes all partition boxes.
  ///
  /// Must be called before any other operations.
  Future<void> initialize() async {
    for (int i = 0; i < strategy.partitionCount; i++) {
      final partitionName = '${name}__p$i';
      _partitions[i] = await openBox(partitionName);
    }
    _initialized = true;
  }

  void _checkInitialized() {
    if (!_initialized) {
      throw StateError(
        'PartitionedBox not initialized. Call initialize() first.',
      );
    }
  }

  /// Gets the partition box for a given [key].
  Box<Map> _partitionFor(dynamic key) {
    final index = strategy.partitionFor(key);
    return _partitions[index]!;
  }

  /// Stores a value in the appropriate partition.
  Future<void> put(dynamic key, Map value) async {
    _checkInitialized();
    await _partitionFor(key).put(key, value);
  }

  /// Retrieves a value from the appropriate partition.
  Map? get(dynamic key) {
    _checkInitialized();
    return _partitionFor(key).get(key);
  }

  /// Deletes a value from the appropriate partition.
  Future<void> delete(dynamic key) async {
    _checkInitialized();
    await _partitionFor(key).delete(key);
  }

  /// Checks if a key exists in the appropriate partition.
  bool containsKey(dynamic key) {
    _checkInitialized();
    return _partitionFor(key).containsKey(key);
  }

  /// Queries across all partitions.
  ///
  /// [predicate] is applied to each entry's value. Returns all
  /// entries across all partitions that match.
  Future<List<MapEntry<dynamic, Map>>> query(
    bool Function(Map value) predicate,
  ) async {
    _checkInitialized();
    final results = <MapEntry<dynamic, Map>>[];
    for (final partition in _partitions.values) {
      for (final key in partition.keys) {
        final value = partition.get(key);
        if (value != null && predicate(value)) {
          results.add(MapEntry(key, value));
        }
      }
    }
    return results;
  }

  /// Gets the total number of entries across all partitions.
  int get length {
    _checkInitialized();
    return _partitions.values.fold(0, (sum, p) => sum + p.length);
  }

  /// Whether all partitions are empty.
  bool get isEmpty => length == 0;

  /// Whether any partition has entries.
  bool get isNotEmpty => !isEmpty;

  /// Returns all key-value pairs across all partitions.
  Map<dynamic, Map> toMap() {
    _checkInitialized();
    final result = <dynamic, Map>{};
    for (final partition in _partitions.values) {
      result.addAll(partition.toMap().cast<dynamic, Map>());
    }
    return result;
  }

  /// Clears all partitions.
  Future<void> clear() async {
    _checkInitialized();
    for (final partition in _partitions.values) {
      await partition.clear();
    }
  }

  /// Gets stats for each partition.
  Map<int, int> get partitionSizes {
    return _partitions.map((i, p) => MapEntry(i, p.length));
  }

  /// The number of partitions.
  int get partitionCount => strategy.partitionCount;

  /// Closes all partition boxes.
  Future<void> close() async {
    for (final partition in _partitions.values) {
      await partition.close();
    }
    _partitions.clear();
    _initialized = false;
  }
}
