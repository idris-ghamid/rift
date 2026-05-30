import 'dart:collection';

import 'package:rift/src/util/indexable_skip_list.dart';

/// Index type determines the underlying data structure and query capabilities.
enum IndexType {
  /// B-tree style sorted index using IndexableSkipList.
  /// Supports equality, range, and prefix queries.
  btree,

  /// Hash-based index for O(1) equality lookups.
  /// Does NOT support range queries.
  hash,

  /// Composite index spanning multiple fields.
  /// Delegated to [CompositeIndex].
  composite,
}

/// Operators for index queries.
enum IndexOperator {
  /// Equal to value.
  eq,

  /// Greater than value.
  gt,

  /// Greater than or equal to value.
  gte,

  /// Less than value.
  lt,

  /// Less than or equal to value.
  lte,

  /// Range between two values (inclusive on both ends).
  range,
}

/// A secondary index on a single field of a Rift box.
///
/// Internally uses an [IndexableSkipList] for sorted (B-tree-like) indexes,
/// which provides O(log n) lookups, range scans, and ordered iteration.
/// For hash indexes, a [HashMap] is used for O(1) equality lookups.
///
/// The index maps field values to sets of primary keys, allowing fast
/// lookups without scanning all entries in a box.
class SecondaryIndex {
  /// The name of the indexed field.
  final String field;

  /// The type of this index.
  final IndexType type;

  /// Sorted index: maps field value → set of primary keys.
  /// Uses IndexableSkipList for range query support.
  final IndexableSkipList<dynamic, Set<dynamic>> _sortedIndex;

  /// Hash index: maps field value → set of primary keys.
  /// Used when [type] is [IndexType.hash].
  final Map<dynamic, Set<dynamic>> _hashIndex;

  /// Create a new secondary index.
  SecondaryIndex({required this.field, this.type = IndexType.btree})
    : _sortedIndex = IndexableSkipList(_compareValues),
      _hashIndex = HashMap<dynamic, Set<dynamic>>();

  /// Insert a key into the index under the given field value.
  void insert(dynamic fieldValue, dynamic primaryKey) {
    if (type == IndexType.hash) {
      _hashIndex.putIfAbsent(fieldValue, () => <dynamic>{});
      _hashIndex[fieldValue]!.add(primaryKey);
    } else {
      final existing = _sortedIndex.get(fieldValue);
      if (existing != null) {
        existing.add(primaryKey);
      } else {
        _sortedIndex.insert(fieldValue, <dynamic>{primaryKey});
      }
    }
  }

  /// Remove a key from the index for the given field value.
  ///
  /// Returns `true` if the key was found and removed.
  bool remove(dynamic fieldValue, dynamic primaryKey) {
    if (type == IndexType.hash) {
      final set = _hashIndex[fieldValue];
      if (set != null) {
        final removed = set.remove(primaryKey);
        if (set.isEmpty) {
          _hashIndex.remove(fieldValue);
        }
        return removed;
      }
      return false;
    } else {
      final set = _sortedIndex.get(fieldValue);
      if (set != null) {
        final removed = set.remove(primaryKey);
        if (set.isEmpty) {
          _sortedIndex.delete(fieldValue);
        }
        return removed;
      }
      return false;
    }
  }

  /// Remove a primary key from the index without knowing its field value.
  ///
  /// This scans all index entries to find and remove the primary key.
  /// This is slower than [remove] but necessary when the old field value
  /// is unknown (e.g., for lazy boxes where the value isn't in memory).
  ///
  /// Returns `true` if the key was found and removed.
  bool removeByPrimaryKey(dynamic primaryKey) {
    if (type == IndexType.hash) {
      dynamic foundKey;
      for (final entry in _hashIndex.entries) {
        if (entry.value.remove(primaryKey)) {
          if (entry.value.isEmpty) {
            foundKey = entry.key;
          }
          break;
        }
      }
      if (foundKey != null) {
        _hashIndex.remove(foundKey);
        return true;
      }
      return false;
    } else {
      final keys = _sortedIndex.keys.toList();
      for (final key in keys) {
        final set = _sortedIndex.get(key);
        if (set != null && set.remove(primaryKey)) {
          if (set.isEmpty) {
            _sortedIndex.delete(key);
          }
          return true;
        }
      }
      return false;
    }
  }

  /// Query the index for keys matching the given [value] with [op].
  ///
  /// For [IndexType.hash], only [IndexOperator.eq] is supported.
  /// For [IndexType.btree], all operators are supported including range.
  List<dynamic> query(dynamic value, {IndexOperator op = IndexOperator.eq}) {
    if (type == IndexType.hash) {
      if (op != IndexOperator.eq) {
        throw UnsupportedError(
          'Hash indexes only support equality (eq) lookups. '
          'Use a btree index for range queries.',
        );
      }
      final set = _hashIndex[value];
      return set?.toList() ?? [];
    }

    // B-tree (IndexableSkipList) queries
    switch (op) {
      case IndexOperator.eq:
        final set = _sortedIndex.get(value);
        return set?.toList() ?? [];

      case IndexOperator.gt:
        return _rangeQuery(value, exclusiveStart: true);

      case IndexOperator.gte:
        return _rangeQuery(value, exclusiveStart: false);

      case IndexOperator.lt:
        return _rangeQueryLessThan(value, exclusiveEnd: true);

      case IndexOperator.lte:
        return _rangeQueryLessThan(value, exclusiveEnd: false);

      case IndexOperator.range:
        // For range, value should be a List of [low, high]
        if (value is! List || value.length != 2) {
          throw ArgumentError(
            'Range query value must be a List of [low, high].',
          );
        }
        return _rangeBetween(value[0], value[1]);
    }
  }

  /// Query for all keys where the field value is greater than (or equal to)
  /// [startValue].
  List<dynamic> _rangeQuery(dynamic startValue, {bool exclusiveStart = false}) {
    final result = <dynamic>[];

    // Collect all key-value pairs by iterating sorted keys
    final keys = _sortedIndex.keys.toList();
    for (final key in keys) {
      final cmp = _compareValues(key, startValue);
      if (exclusiveStart && cmp > 0 || !exclusiveStart && cmp >= 0) {
        final set = _sortedIndex.get(key);
        if (set != null) {
          result.addAll(set);
        }
      }
    }

    return result;
  }

  /// Query for all keys where the field value is less than (or equal to)
  /// [endValue].
  List<dynamic> _rangeQueryLessThan(
    dynamic endValue, {
    bool exclusiveEnd = false,
  }) {
    final result = <dynamic>[];

    final keys = _sortedIndex.keys.toList();
    for (final key in keys) {
      final cmp = _compareValues(key, endValue);
      if (exclusiveEnd && cmp < 0 || !exclusiveEnd && cmp <= 0) {
        final set = _sortedIndex.get(key);
        if (set != null) {
          result.addAll(set);
        }
      }
    }

    return result;
  }

  /// Query for all keys where the field value is between [low] and [high]
  /// (inclusive on both ends).
  List<dynamic> _rangeBetween(dynamic low, dynamic high) {
    final result = <dynamic>[];

    final keys = _sortedIndex.keys.toList();
    for (final key in keys) {
      final cmpLow = _compareValues(key, low);
      final cmpHigh = _compareValues(key, high);
      if (cmpLow >= 0 && cmpHigh <= 0) {
        final set = _sortedIndex.get(key);
        if (set != null) {
          result.addAll(set);
        }
      }
    }

    return result;
  }

  /// Get all primary keys in this index (for full scans).
  List<dynamic> allKeys() {
    final result = <dynamic>[];

    if (type == IndexType.hash) {
      for (final set in _hashIndex.values) {
        result.addAll(set);
      }
    } else {
      for (final set in _sortedIndex.values) {
        result.addAll(set);
      }
    }

    return result;
  }

  /// Clear all entries from this index.
  void clear() {
    if (type == IndexType.hash) {
      _hashIndex.clear();
    } else {
      _sortedIndex.clear();
    }
  }

  /// The number of distinct field values in this index.
  int get size {
    if (type == IndexType.hash) {
      return _hashIndex.length;
    }
    return _sortedIndex.length;
  }

  /// Compare two index key values for ordering.
  ///
  /// Handles nulls (null < any non-null), numbers, strings, and Comparables.
  static int _compareValues(dynamic a, dynamic b) {
    if (identical(a, b)) return 0;
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;

    if (a is num && b is num) return a.compareTo(b);
    if (a is String && b is String) return a.compareTo(b);
    if (a is Comparable && b is Comparable && a.runtimeType == b.runtimeType) {
      return a.compareTo(b);
    }

    // Fallback: compare string representations
    return a.toString().compareTo(b.toString());
  }

  @override
  String toString() =>
      'SecondaryIndex(field: $field, type: $type, size: $size)';
}
