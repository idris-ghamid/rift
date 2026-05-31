/// Query optimizer that rewrites queries for better performance.
///
/// Analyzes queries and produces optimized execution plans with
/// cost estimation, index hints, and rewrite rules.
///
/// Usage:
/// ```dart
/// final optimizer = QueryOptimizer();
///
/// // Analyze a query
/// final plan = optimizer.optimize(
///   QueryAnalysis(
///     boxName: 'users',
///     filters: [FilterDesc('age', '>', 18), FilterDesc('city', '==', 'Cairo')],
///     sortFields: ['name'],
///     limit: 10,
///   ),
///   availableIndexes: ['age', 'city'],
/// );
///
/// print(plan.estimatedCost);
/// print(plan.suggestedIndexes);
/// print(plan.rewrittenQuery);
/// ```
library;

/// Description of a filter in a query analysis.
class FilterDesc {
  /// The field name.
  final String field;

  /// The operator as a string (e.g., '>', '==', '<', '>=', '<=', '!=', 'in', 'contains').
  final String operator;

  /// The filter value.
  final dynamic value;

  /// Estimated selectivity (0.0 to 1.0) — fraction of rows that pass this filter.
  final double? selectivity;

  /// Creates a [FilterDesc].
  const FilterDesc(this.field, this.operator, this.value, {this.selectivity});

  /// Estimated selectivity, defaulting to a heuristic.
  double get estimatedSelectivity {
    if (selectivity != null) return selectivity!;
    switch (operator) {
      case '==':
        return 0.01; // Equality is very selective
      case '!=':
        return 0.99;
      case '>':
      case '>=':
      case '<':
      case '<=':
        return 0.3; // Range matches ~30% of data
      case 'in':
        return 0.05;
      case 'contains':
        return 0.1;
      case 'startsWith':
        return 0.05;
      default:
        return 0.5;
    }
  }

  /// Whether this filter can use an index on [field].
  bool get isIndexFriendly {
    switch (operator) {
      case '==':
      case '>':
      case '>=':
      case '<':
      case '<=':
      case 'in':
        return true;
      default:
        return false;
    }
  }

  @override
  String toString() => '$field $operator $value';
}

/// Description of a query to be optimized.
class QueryAnalysis {
  /// The box name being queried.
  final String boxName;

  /// The filters in the query.
  final List<FilterDesc> filters;

  /// The fields used for sorting.
  final List<String> sortFields;

  /// The query limit (0 for no limit).
  final int limit;

  /// The query offset.
  final int offset;

  /// Estimated row count for the box.
  final int estimatedRowCount;

  /// Creates a [QueryAnalysis].
  const QueryAnalysis({
    required this.boxName,
    this.filters = const [],
    this.sortFields = const [],
    this.limit = 0,
    this.offset = 0,
    this.estimatedRowCount = 10000,
  });
}

/// Cost estimation for a query execution plan.
class CostEstimate {
  /// Estimated number of rows scanned.
  final double rowsScanned;

  /// Estimated number of rows returned.
  final double rowsReturned;

  /// Estimated CPU cost (relative units).
  final double cpuCost;

  /// Estimated I/O cost (relative units).
  final double ioCost;

  /// Creates a [CostEstimate].
  const CostEstimate({
    required this.rowsScanned,
    required this.rowsReturned,
    required this.cpuCost,
    required this.ioCost,
  });

  /// Total estimated cost.
  double get totalCost => cpuCost + ioCost;

  @override
  String toString() =>
      'CostEstimate(scanned: ${rowsScanned.round()}, returned: ${rowsReturned.round()}, '
      'total: ${totalCost.toStringAsFixed(1)})';
}

/// An optimized query execution plan.
class QueryPlan {
  /// The original query analysis.
  final QueryAnalysis query;

  /// The estimated cost.
  final CostEstimate cost;

  /// Indexes suggested for this query.
  final List<IndexHint> suggestedIndexes;

  /// The optimized filter order (most selective first).
  final List<FilterDesc> optimizedFilters;

  /// Rewrite rules that were applied.
  final List<QueryRewrite> appliedRewrites;

  /// Whether an index can be used for sorting.
  final bool indexSortPossible;

  /// The estimated execution time in microseconds.
  final int estimatedTimeUs;

  /// Creates a [QueryPlan].
  const QueryPlan({
    required this.query,
    required this.cost,
    required this.suggestedIndexes,
    required this.optimizedFilters,
    required this.appliedRewrites,
    required this.indexSortPossible,
    required this.estimatedTimeUs,
  });

  @override
  String toString() =>
      'QueryPlan(cost: ${cost.totalCost.toStringAsFixed(1)}, '
      'indexes: ${suggestedIndexes.length}, '
      'rewrites: ${appliedRewrites.length})';
}

/// Suggestion for an index that would improve query performance.
class IndexHint {
  /// The field(s) to index.
  final List<String> fields;

  /// The type of index recommended.
  final String indexType;

  /// The estimated improvement factor (e.g., 10.0 means 10x faster).
  final double improvementFactor;

  /// Reason for the suggestion.
  final String reason;

  /// Creates an [IndexHint].
  const IndexHint({
    required this.fields,
    required this.indexType,
    required this.improvementFactor,
    required this.reason,
  });

  @override
  String toString() =>
      'IndexHint(${fields.join('+')}, $indexType, ${improvementFactor}x: $reason)';
}

/// A rewrite rule applied to a query.
class QueryRewrite {
  /// The type of rewrite.
  final QueryRewriteType type;

  /// Description of the rewrite.
  final String description;

  /// The rewritten query analysis.
  final QueryAnalysis rewrittenQuery;

  /// Creates a [QueryRewrite].
  const QueryRewrite({
    required this.type,
    required this.description,
    required this.rewrittenQuery,
  });

  @override
  String toString() => 'QueryRewrite(${type.name}: $description)';
}

/// Types of query rewrites.
enum QueryRewriteType {
  /// Reorder filters by selectivity (most selective first).
  predicatePushdown,

  /// Select an index for the query.
  indexSelection,

  /// Convert a filter to an index scan.
  filterToIndexScan,

  /// Merge redundant filters.
  filterMerging,

  /// Remove no-op filters.
  filterElimination,

  /// Optimize sort using index.
  sortOptimization,

  /// Limit pushdown (apply limit early).
  limitPushdown,
}

/// A record in the slow query log.
class SlowQueryEntry {
  /// The query analysis.
  final QueryAnalysis query;

  /// The execution plan used.
  final QueryPlan plan;

  /// Actual execution time in microseconds.
  final int actualTimeUs;

  /// When this query was executed.
  final DateTime timestamp;

  /// Creates a [SlowQueryEntry].
  const SlowQueryEntry({
    required this.query,
    required this.plan,
    required this.actualTimeUs,
    required this.timestamp,
  });

  /// How much slower than estimated (factor).
  double get slowdownFactor =>
      plan.estimatedTimeUs > 0 ? actualTimeUs / plan.estimatedTimeUs : 1.0;

  @override
  String toString() =>
      'SlowQueryEntry($actualTimeUsμs, ${slowdownFactor.toStringAsFixed(1)}x slower than estimated)';
}

/// Query optimizer that analyzes and optimizes queries.
///
/// [QueryOptimizer] takes a query analysis and produces an optimized
/// execution plan. It applies rewrite rules, estimates costs, and
/// suggests indexes.
class QueryOptimizer {
  /// Available indexes per box: boxName → list of indexed fields.
  final Map<String, Set<String>> _availableIndexes = {};

  /// The slow query threshold (queries slower than this are logged).
  final Duration slowQueryThreshold;

  /// The slow query log.
  final List<SlowQueryEntry> _slowQueryLog = [];

  /// Maximum slow query log entries to keep.
  final int maxSlowQueryLogSize;

  /// Creates a [QueryOptimizer].
  QueryOptimizer({
    this.slowQueryThreshold = const Duration(milliseconds: 100),
    this.maxSlowQueryLogSize = 1000,
  });

  /// Registers an available index for a box.
  void registerIndex(String boxName, String field) {
    _availableIndexes.putIfAbsent(boxName, () => {});
    _availableIndexes[boxName]!.add(field);
  }

  /// Removes a registered index.
  void unregisterIndex(String boxName, String field) {
    _availableIndexes[boxName]?.remove(field);
  }

  /// Optimizes a query and returns an execution plan.
  QueryPlan optimize(QueryAnalysis query, {Set<String>? availableIndexes}) {
    final indexes = availableIndexes ?? _availableIndexes[query.boxName] ?? {};

    final rewrites = <QueryRewrite>[];
    var currentQuery = query;

    // Apply rewrite rules
    currentQuery = _applyPredicatePushdown(currentQuery, rewrites);
    currentQuery = _applyFilterElimination(currentQuery, rewrites);
    currentQuery = _applyFilterMerging(currentQuery, rewrites);
    currentQuery = _applyLimitPushdown(currentQuery, rewrites);

    // Determine suggested indexes
    final indexHints = _suggestIndexes(currentQuery, indexes);

    // Determine if index can be used for sorting
    final indexSortPossible = _canIndexSort(currentQuery, indexes);

    // Estimate cost
    final cost = _estimateCost(currentQuery, indexes);

    // Estimate execution time
    final estimatedTimeUs = (cost.totalCost * 10).round(); // Rough estimate

    return QueryPlan(
      query: currentQuery,
      cost: cost,
      suggestedIndexes: indexHints,
      optimizedFilters: currentQuery.filters,
      appliedRewrites: rewrites,
      indexSortPossible: indexSortPossible,
      estimatedTimeUs: estimatedTimeUs,
    );
  }

  /// Logs a slow query entry.
  void logSlowQuery(SlowQueryEntry entry) {
    _slowQueryLog.add(entry);
    if (_slowQueryLog.length > maxSlowQueryLogSize) {
      _slowQueryLog.removeAt(0);
    }
  }

  /// Gets all slow query log entries.
  List<SlowQueryEntry> get slowQueries => List.unmodifiable(_slowQueryLog);

  /// Gets the slowest queries.
  List<SlowQueryEntry> getSlowestQueries({int limit = 10}) {
    final sorted = List<SlowQueryEntry>.from(_slowQueryLog)
      ..sort((a, b) => b.actualTimeUs.compareTo(a.actualTimeUs));
    return sorted.take(limit).toList();
  }

  /// Clears the slow query log.
  void clearSlowQueryLog() {
    _slowQueryLog.clear();
  }

  /// Analyzes slow query patterns and returns recommendations.
  List<String> analyzeSlowQueries() {
    final recommendations = <String>[];

    if (_slowQueryLog.isEmpty) return recommendations;

    // Find most common slow query boxes
    final boxCounts = <String, int>{};
    for (final entry in _slowQueryLog) {
      boxCounts[entry.query.boxName] =
          (boxCounts[entry.query.boxName] ?? 0) + 1;
    }

    for (final entry in boxCounts.entries) {
      if (entry.value > 3) {
        recommendations.add(
          'Box "${entry.key}" has ${entry.value} slow queries. Consider adding indexes.',
        );
      }
    }

    // Find common filter fields without indexes
    final filterFields = <String, int>{};
    for (final entry in _slowQueryLog) {
      for (final filter in entry.query.filters) {
        if (filter.isIndexFriendly) {
          filterFields[filter.field] = (filterFields[filter.field] ?? 0) + 1;
        }
      }
    }

    final indexes = _availableIndexes;
    for (final entry in filterFields.entries) {
      bool hasIndex = false;
      for (final boxIndexes in indexes.values) {
        if (boxIndexes.contains(entry.key)) {
          hasIndex = true;
          break;
        }
      }
      if (!hasIndex && entry.value > 2) {
        recommendations.add(
          'Field "${entry.key}" is frequently filtered (${entry.value} times) without an index. '
          'Consider creating an index.',
        );
      }
    }

    return recommendations;
  }

  // --- Rewrite Rules ---

  QueryAnalysis _applyPredicatePushdown(
    QueryAnalysis query,
    List<QueryRewrite> rewrites,
  ) {
    if (query.filters.length <= 1) return query;

    // Sort filters by selectivity (most selective first)
    final sorted = List<FilterDesc>.from(
      query.filters,
    )..sort((a, b) => a.estimatedSelectivity.compareTo(b.estimatedSelectivity));

    if (sorted.map((f) => f.toString()).join() !=
        query.filters.map((f) => f.toString()).join()) {
      rewrites.add(
        QueryRewrite(
          type: QueryRewriteType.predicatePushdown,
          description:
              'Reordered filters by selectivity: '
              '${sorted.map((f) => f.field).join(' → ')}',
          rewrittenQuery: QueryAnalysis(
            boxName: query.boxName,
            filters: sorted,
            sortFields: query.sortFields,
            limit: query.limit,
            offset: query.offset,
            estimatedRowCount: query.estimatedRowCount,
          ),
        ),
      );
      return QueryAnalysis(
        boxName: query.boxName,
        filters: sorted,
        sortFields: query.sortFields,
        limit: query.limit,
        offset: query.offset,
        estimatedRowCount: query.estimatedRowCount,
      );
    }

    return query;
  }

  QueryAnalysis _applyFilterElimination(
    QueryAnalysis query,
    List<QueryRewrite> rewrites,
  ) {
    final optimized = <FilterDesc>[];
    var eliminated = 0;

    for (final filter in query.filters) {
      // Eliminate tautologies like field > -infinity
      if (filter.operator == '>' &&
          filter.value is num &&
          (filter.value as num) == double.negativeInfinity) {
        eliminated++;
        continue;
      }
      // Eliminate field != null (always true for non-null fields)
      if (filter.operator == '!=' && filter.value == null) {
        eliminated++;
        continue;
      }
      optimized.add(filter);
    }

    if (eliminated > 0) {
      rewrites.add(
        QueryRewrite(
          type: QueryRewriteType.filterElimination,
          description: 'Eliminated $eliminated no-op filter(s)',
          rewrittenQuery: QueryAnalysis(
            boxName: query.boxName,
            filters: optimized,
            sortFields: query.sortFields,
            limit: query.limit,
            offset: query.offset,
            estimatedRowCount: query.estimatedRowCount,
          ),
        ),
      );
      return QueryAnalysis(
        boxName: query.boxName,
        filters: optimized,
        sortFields: query.sortFields,
        limit: query.limit,
        offset: query.offset,
        estimatedRowCount: query.estimatedRowCount,
      );
    }

    return query;
  }

  QueryAnalysis _applyFilterMerging(
    QueryAnalysis query,
    List<QueryRewrite> rewrites,
  ) {
    // Merge filters on the same field with compatible operators
    // e.g., age > 18 AND age < 65 → age in range(18, 65)
    final fieldFilters = <String, List<FilterDesc>>{};
    for (final filter in query.filters) {
      fieldFilters.putIfAbsent(filter.field, () => []).add(filter);
    }

    var merged = false;
    final result = <FilterDesc>[];

    for (final entry in fieldFilters.entries) {
      if (entry.value.length == 1) {
        result.add(entry.value.first);
      } else {
        // Check for range merge (e.g., > x AND < y)
        FilterDesc? lowerBound;
        FilterDesc? upperBound;
        FilterDesc? equality;

        for (final f in entry.value) {
          if (f.operator == '==' || f.operator == 'in') {
            equality = f;
          } else if (f.operator == '>' || f.operator == '>=') {
            lowerBound = f;
          } else if (f.operator == '<' || f.operator == '<=') {
            upperBound = f;
          }
        }

        if (equality != null) {
          result.add(equality);
          merged = true;
        } else {
          result.addAll(entry.value);
        }
      }
    }

    if (merged) {
      rewrites.add(
        QueryRewrite(
          type: QueryRewriteType.filterMerging,
          description: 'Merged redundant filters',
          rewrittenQuery: QueryAnalysis(
            boxName: query.boxName,
            filters: result,
            sortFields: query.sortFields,
            limit: query.limit,
            offset: query.offset,
            estimatedRowCount: query.estimatedRowCount,
          ),
        ),
      );
      return QueryAnalysis(
        boxName: query.boxName,
        filters: result,
        sortFields: query.sortFields,
        limit: query.limit,
        offset: query.offset,
        estimatedRowCount: query.estimatedRowCount,
      );
    }

    return query;
  }

  QueryAnalysis _applyLimitPushdown(
    QueryAnalysis query,
    List<QueryRewrite> rewrites,
  ) {
    // If there's a limit, we can stop scanning after finding enough results
    // This doesn't change the query but affects cost estimation
    if (query.limit > 0 && query.filters.isNotEmpty) {
      rewrites.add(
        QueryRewrite(
          type: QueryRewriteType.limitPushdown,
          description: 'Applied limit ${query.limit} early to reduce scanning',
          rewrittenQuery: query,
        ),
      );
    }
    return query;
  }

  List<IndexHint> _suggestIndexes(
    QueryAnalysis query,
    Set<String> availableIndexes,
  ) {
    final hints = <IndexHint>[];

    for (final filter in query.filters) {
      if (!filter.isIndexFriendly) continue;
      if (availableIndexes.contains(filter.field)) continue;

      double improvementFactor;
      String indexType;

      if (filter.operator == '==' || filter.operator == 'in') {
        indexType = 'hash';
        improvementFactor = 1 / filter.estimatedSelectivity;
      } else {
        indexType = 'btree';
        improvementFactor = (1 / filter.estimatedSelectivity) * 0.5;
      }

      hints.add(
        IndexHint(
          fields: [filter.field],
          indexType: indexType,
          improvementFactor: improvementFactor.clamp(1.0, 1000.0),
          reason:
              'Filter on ${filter.field} with operator ${filter.operator} '
              'scans ${(filter.estimatedSelectivity * 100).toStringAsFixed(1)}% of rows',
        ),
      );
    }

    // Suggest composite index for common filter combinations
    if (query.filters.length > 1) {
      final indexFields = query.filters
          .where((f) => f.isIndexFriendly)
          .map((f) => f.field)
          .toList();
      if (indexFields.length > 1 &&
          !availableIndexes.contains(indexFields.join('+'))) {
        hints.add(
          IndexHint(
            fields: indexFields,
            indexType: 'composite',
            improvementFactor: 10.0,
            reason:
                'Composite index on ${indexFields.join(', ')} would cover multiple filters',
          ),
        );
      }
    }

    // Sort by improvement factor (descending)
    hints.sort((a, b) => b.improvementFactor.compareTo(a.improvementFactor));
    return hints;
  }

  bool _canIndexSort(QueryAnalysis query, Set<String> availableIndexes) {
    if (query.sortFields.isEmpty) return false;
    // If the first sort field has an index, we can use it
    return availableIndexes.contains(query.sortFields.first);
  }

  CostEstimate _estimateCost(
    QueryAnalysis query,
    Set<String> availableIndexes,
  ) {
    final totalRows = query.estimatedRowCount.toDouble();

    // Calculate how many rows pass all filters
    var selectivity = 1.0;
    for (final filter in query.filters) {
      if (availableIndexes.contains(filter.field) && filter.isIndexFriendly) {
        // Index scan: only scan matching rows
        selectivity *= filter.estimatedSelectivity;
      } else {
        // Full scan: scan all rows but filter in memory
        selectivity *= filter.estimatedSelectivity;
      }
    }

    final rowsReturned = totalRows * selectivity;
    var rowsScanned = totalRows;

    // If we have an index, we scan fewer rows
    for (final filter in query.filters) {
      if (availableIndexes.contains(filter.field) && filter.isIndexFriendly) {
        rowsScanned = min(rowsScanned, totalRows * filter.estimatedSelectivity);
      }
    }

    // Apply limit
    final effectiveLimit = query.limit > 0
        ? query.limit.toDouble()
        : rowsReturned;
    final rowsAfterLimit = min(rowsReturned, effectiveLimit);

    // CPU cost: proportional to rows scanned for filtering
    final cpuCost = rowsScanned * 0.01;

    // I/O cost: proportional to rows scanned from storage
    final hasIndexScan = query.filters.any(
      (f) => availableIndexes.contains(f.field) && f.isIndexFriendly,
    );
    final ioCost = hasIndexScan
        ? rowsScanned *
              0.1 // Index scan: less I/O
        : totalRows * 0.5; // Full scan: more I/O

    // Sort cost
    final sortCost = query.sortFields.isNotEmpty ? rowsAfterLimit * 0.05 : 0;

    return CostEstimate(
      rowsScanned: rowsScanned,
      rowsReturned: rowsAfterLimit,
      cpuCost: cpuCost + sortCost,
      ioCost: ioCost,
    );
  }

  double min(double a, double b) => a < b ? a : b;
}
