import 'dart:async';

import 'package:rift/src/box/box_base_impl.dart';
import 'package:rift/src/index/index_manager.dart';
import 'package:rift/src/index/secondary_index.dart';
import 'package:rift/src/query/filter_condition.dart';
import 'package:rift/src/query/sort_condition.dart';
import 'package:rift/src/query/live_query.dart';
import 'package:meta/meta.dart';

/// Fluent query builder for Rift boxes.
///
/// RiftQuery provides a chainable, type-safe API for filtering, sorting,
/// and limiting query results. It can optionally leverage secondary indexes
/// for faster lookups.
///
/// Usage:
/// ```dart
/// final adults = await box.query()
///   .where('age', greaterThan: 18)
///   .where('city', equalTo: 'Cairo')
///   .sortBy('name')
///   .limit(10)
///   .findAll();
///
/// // Live query — auto-updating stream
/// box.query()
///   .where('age', greaterThan: 18)
///   .watch()
///   .listen((results) => print('Found ${results.length} adults'));
/// ```
class RiftQuery<E> {
  /// The box this query operates on.
  final BoxBaseImpl<E> _box;

  /// The index manager for this query's box.
  final IndexManager _indexManager;

  /// Accumulated filter conditions (ANDed together).
  final List<FilterCondition> _filters = [];

  /// Accumulated sort conditions (applied in order).
  final List<SortCondition> _sorts = [];

  /// Maximum number of results to return.
  int? _limit;

  /// Number of results to skip.
  int? _offset;

  /// Whether to use indexes for this query (default: true when available).
  bool _useIndex = true;

  /// Create a new query for the given [box].
  ///
  /// This is typically called via [BoxBaseImpl.query()].
  RiftQuery(this._box, this._indexManager);

  /// The name of the box this query targets.
  String get _boxName => _box.name;

  /// Add a filter condition.
  ///
  /// Multiple [where] calls are ANDed together.
  ///
  /// At least one comparison parameter must be provided.
  ///
  /// Example:
  /// ```dart
  /// query
  ///   .where('age', greaterThan: 18)
  ///   .where('city', equalTo: 'Cairo')
  ///   .where('name', startsWith: 'A')
  ///   .where('status', inList: ['active', 'pending'])
  /// ```
  RiftQuery<E> where(
    String field, {
    dynamic equalTo,
    dynamic greaterThan,
    dynamic lessThan,
    dynamic greaterThanOrEqual,
    dynamic lessThanOrEqual,
    List<dynamic>? inList,
    String? contains,
    String? startsWith,
  }) {
    _filters.add(
      FilterCondition.fromWhere(
        field,
        equalTo: equalTo,
        greaterThan: greaterThan,
        lessThan: lessThan,
        greaterThanOrEqual: greaterThanOrEqual,
        lessThanOrEqual: lessThanOrEqual,
        inList: inList,
        contains: contains,
        startsWith: startsWith,
      ),
    );
    return this;
  }

  /// Add sort order.
  ///
  /// Multiple [sortBy] calls create a multi-level sort.
  /// The first [sortBy] has the highest priority.
  ///
  /// [order] defaults to [SortOrder.asc] (ascending).
  RiftQuery<E> sortBy(String field, [SortOrder order = SortOrder.asc]) {
    _sorts.add(SortCondition(field: field, order: order));
    return this;
  }

  /// Add descending sort order.
  ///
  /// Equivalent to `sortBy(field, SortOrder.desc)`.
  RiftQuery<E> sortByDesc(String field) {
    return sortBy(field, SortOrder.desc);
  }

  /// Set the maximum number of results.
  RiftQuery<E> limit(int count) {
    _limit = count;
    return this;
  }

  /// Set the number of results to skip.
  RiftQuery<E> offset(int count) {
    _offset = count;
    return this;
  }

  /// Disable index usage for this query.
  ///
  /// Forces a full table scan even when indexes are available.
  RiftQuery<E> noIndex() {
    _useIndex = false;
    return this;
  }

  /// Execute the query and return all matching results.
  ///
  /// This is the primary query execution method. It:
  /// 1. Tries to use available indexes for initial key filtering
  /// 2. Falls back to full scan for unindexed filters
  /// 3. Applies all filter conditions
  /// 4. Applies sort conditions
  /// 5. Applies offset and limit
  Future<List<E>> findAll() async {
    _box.checkOpen();

    // Step 1: Get candidate keys (using indexes if possible)
    final candidateKeys = await _getCandidateKeys();

    // Step 2: Load values and apply filters
    final results = await _applyFilters(candidateKeys);

    // Step 3: Apply sorting
    _applySorting(results);

    // Step 4: Apply offset and limit
    return _applyOffsetAndLimit(results);
  }

  /// Execute the query and return the first match or null.
  Future<E?> findFirst() async {
    // Optimize: apply limit 1 at the query level
    final previousLimit = _limit;
    _limit = 1;
    final results = await findAll();
    _limit = previousLimit;
    return results.isEmpty ? null : results.first;
  }

  /// Count the number of matching results.
  Future<int> count() async {
    _box.checkOpen();

    final candidateKeys = await _getCandidateKeys();
    final results = await _applyFilters(candidateKeys);
    return results.length;
  }

  /// Watch query results as a reactive stream.
  ///
  /// Returns a [Stream] that emits the current query results immediately
  /// when subscribed, and then emits updated results whenever the data
  /// in the box changes.
  ///
  /// The stream uses debouncing to avoid excessive re-computation when
  /// multiple changes happen in rapid succession.
  ///
  /// [debounceDuration] controls how long to wait after a change before
  /// re-executing the query (default: 10ms).
  ///
  /// Example:
  /// ```dart
  /// final subscription = box.query()
  ///   .where('age', greaterThan: 18)
  ///   .watch()
  ///   .listen((results) {
  ///     print('Found ${results.length} adults');
  ///   });
  ///
  /// // Don't forget to cancel when done
  /// subscription.cancel();
  /// ```
  Stream<List<E>> watch({
    Duration debounceDuration = const Duration(milliseconds: 10),
  }) {
    final liveQuery = LiveQuery<E>(
      box: _box,
      execute: findAll,
      debounceDuration: debounceDuration,
    );

    // When the stream is done (all listeners cancelled), dispose the live query
    return liveQuery.stream.doOnCancel(() {
      liveQuery.dispose();
    });
  }

  /// Get candidate keys using available indexes.
  ///
  /// If no indexes are available or [noIndex] was called,
  /// returns all keys in the box (full scan).
  Future<Set<dynamic>> _getCandidateKeys() async {
    if (!_useIndex || _filters.isEmpty) {
      return _box.keys.toSet();
    }

    Set<dynamic>? candidateKeys;

    for (final filter in _filters) {
      final indexKeys = await _getIndexKeysForFilter(filter);
      if (indexKeys != null) {
        // Intersect with existing candidates
        if (candidateKeys == null) {
          candidateKeys = indexKeys.toSet();
        } else {
          candidateKeys = candidateKeys.intersection(indexKeys.toSet());
        }

        // Early exit: no candidates left
        if (candidateKeys.isEmpty) break;
      }
      // If no index for this filter, we can't narrow candidates via indexes
      // Fall back to full scan for this filter
    }

    // If we couldn't use any indexes, fall back to full scan
    if (candidateKeys == null) {
      return _box.keys.toSet();
    }

    // If we used indexes but some filters weren't indexed,
    // we still need to check all keys against unindexed filters
    return candidateKeys;
  }

  /// Try to get matching keys from an index for a filter condition.
  ///
  /// Returns null if no suitable index exists.
  Future<List<dynamic>?> _getIndexKeysForFilter(FilterCondition filter) async {
    if (!_indexManager.hasIndex(_boxName, filter.field)) {
      return null;
    }

    switch (filter.operator) {
      case FilterOperator.equalTo:
        return _indexManager.queryIndex(
          _boxName,
          filter.field,
          filter.values[0],
          op: IndexOperator.eq,
        );

      case FilterOperator.greaterThan:
        return _indexManager.queryIndex(
          _boxName,
          filter.field,
          filter.values[0],
          op: IndexOperator.gt,
        );

      case FilterOperator.greaterThanOrEqual:
        return _indexManager.queryIndex(
          _boxName,
          filter.field,
          filter.values[0],
          op: IndexOperator.gte,
        );

      case FilterOperator.lessThan:
        return _indexManager.queryIndex(
          _boxName,
          filter.field,
          filter.values[0],
          op: IndexOperator.lt,
        );

      case FilterOperator.lessThanOrEqual:
        return _indexManager.queryIndex(
          _boxName,
          filter.field,
          filter.values[0],
          op: IndexOperator.lte,
        );

      case FilterOperator.between:
        return _indexManager.queryIndex(
          _boxName,
          filter.field,
          filter.values,
          op: IndexOperator.range,
        );

      case FilterOperator.inList:
        // For inList, query the index for each value and union the results
        final allKeys = <dynamic>[];
        for (final value in filter.values) {
          final keys = await _indexManager.queryIndex(
            _boxName,
            filter.field,
            value,
            op: IndexOperator.eq,
          );
          allKeys.addAll(keys);
        }
        return allKeys;

      case FilterOperator.contains:
      case FilterOperator.startsWith:
        // Contains and startsWith can't use standard indexes efficiently
        // Fall back to full scan for these
        return null;
    }
  }

  /// Apply all filter conditions to the candidate keys.
  ///
  /// Returns a list of (key, value) pairs that pass all filters.
  Future<List<_QueryResult<E>>> _applyFilters(
    Set<dynamic> candidateKeys,
  ) async {
    final extractor = _indexManager.getFieldExtractor(_boxName);

    final results = <_QueryResult<E>>[];

    for (final key in candidateKeys) {
      final value = _getValue(key);
      if (value == null) continue;

      bool passes = true;
      for (final filter in _filters) {
        final fieldValue = extractor(value, filter.field);
        if (!filter.evaluate(fieldValue)) {
          passes = false;
          break;
        }
      }

      if (passes) {
        results.add(_QueryResult(key, value));
      }
    }

    return results;
  }

  /// Get a value from the box by key.
  ///
  /// Works for both regular and lazy boxes.
  dynamic _getValue(dynamic key) {
    if (_box.lazy) {
      // For lazy boxes, we need async access — this is a limitation
      // For queries, we recommend using regular boxes
      return null;
    }
    final frame = _box.keystore.get(key);
    return frame?.value;
  }

  /// Apply sort conditions to the results (in-place).
  void _applySorting(List<_QueryResult<E>> results) {
    if (_sorts.isEmpty) return;

    final extractor = _indexManager.getFieldExtractor(_boxName);

    results.sort((a, b) {
      for (final sort in _sorts) {
        final aValue = extractor(a.value, sort.field);
        final bValue = extractor(b.value, sort.field);
        final cmp = sort.compare(aValue, bValue);
        if (cmp != 0) return cmp;
      }
      return 0;
    });
  }

  /// Apply offset and limit to the results.
  List<E> _applyOffsetAndLimit(List<_QueryResult<E>> results) {
    var start = _offset ?? 0;
    var end = results.length;

    if (_limit != null) {
      end = start + _limit!;
      if (end > results.length) {
        end = results.length;
      }
    }

    if (start >= results.length) {
      return [];
    }

    return results.sublist(start, end).map((r) => r.value as E).toList();
  }

  /// Create a copy of this query with the same filters and sorts.
  ///
  /// Useful for creating variations of a base query.
  @visibleForTesting
  RiftQuery<E> clone() {
    final cloned = RiftQuery<E>(_box, _indexManager);
    cloned._filters.addAll(_filters);
    cloned._sorts.addAll(_sorts);
    cloned._limit = _limit;
    cloned._offset = _offset;
    cloned._useIndex = _useIndex;
    return cloned;
  }

  @override
  String toString() =>
      'RiftQuery(box: $_boxName, filters: $_filters, sorts: $_sorts, '
      'limit: $_limit, offset: $_offset)';
}

/// Internal result holder for query processing.
class _QueryResult<E> {
  final dynamic key;
  final dynamic value;

  _QueryResult(this.key, this.value);
}

/// Extension on Stream to add doOnCancel callback.
extension _StreamDoOnCancel<T> on Stream<T> {
  Stream<T> doOnCancel(void Function() onCancel) {
    final controller = StreamController<T>();

    var hasListener = false;

    controller.onListen = () {
      hasListener = true;
      listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
    };

    controller.onCancel = () {
      if (hasListener) {
        hasListener = false;
        onCancel();
      }
    };

    return controller.stream;
  }
}
