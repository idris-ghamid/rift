import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class QueryOptDemoPage extends StatelessWidget {
  const QueryOptDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Query Optimization',
      description: 'Query optimizer with cost estimation and index hints',
      codeExample:
          "final optimizer = QueryOptimizer();\nfinal plan = optimizer.optimize(QueryAnalysis(\n  boxName: 'users',\n  filters: [FilterDesc('age', '>', 18)],\n));\nprint(plan.suggestedIndexes);",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Query Optimization Demo ===\n');

        final optimizer = QueryOptimizer();

        // Register available indexes
        optimizer.registerIndex('users', 'name');

        // Complex query
        final query = QueryAnalysis(
          boxName: 'users',
          filters: [
            const FilterDesc('city', '==', 'Cairo'),
            const FilterDesc('age', '>', 18),
            const FilterDesc('role', '==', 'admin'),
            const FilterDesc('status', '!=', null), // no-op filter
          ],
          sortFields: ['name'],
          limit: 10,
          estimatedRowCount: 100000,
        );

        buf.writeln('--- Original Query ---');
        buf.writeln('  Box: ${query.boxName}');
        buf.writeln('  Filters: ${query.filters}');
        buf.writeln('  Sort: ${query.sortFields}');
        buf.writeln('  Limit: ${query.limit}');
        buf.writeln('  Estimated rows: ${query.estimatedRowCount}');

        // Optimize
        buf.writeln('\n--- Optimized Query Plan ---');
        final plan = optimizer.optimize(query);
        buf.writeln('  Estimated cost: ${plan.cost}');
        buf.writeln('  Rows scanned: ${plan.cost.rowsScanned.round()}');
        buf.writeln('  Rows returned: ${plan.cost.rowsReturned.round()}');
        buf.writeln('  Estimated time: ${plan.estimatedTimeUs}μs');
        buf.writeln('  Index sort possible: ${plan.indexSortPossible}');

        // Optimized filter order
        buf.writeln('\n--- Optimized Filter Order ---');
        for (final f in plan.optimizedFilters) {
          buf.writeln(
              '  ${f.field} ${f.operator} ${f.value} (selectivity: ${f.estimatedSelectivity})');
        }

        // Applied rewrites
        buf.writeln('\n--- Applied Rewrites ---');
        for (final rewrite in plan.appliedRewrites) {
          buf.writeln('  ${rewrite.type.name}: ${rewrite.description}');
        }

        // Index hints
        buf.writeln('\n--- Index Hints ---');
        for (final hint in plan.suggestedIndexes) {
          buf.writeln(
              '  ${hint.fields.join("+")} (${hint.indexType}): ${hint.improvementFactor.toStringAsFixed(1)}x improvement');
          buf.writeln('    Reason: ${hint.reason}');
        }

        // Query without indexes
        buf.writeln('\n--- Query Without Indexes ---');
        final noIndexPlan = optimizer.optimize(query, availableIndexes: {});
        buf.writeln(
            '  Cost with indexes: ${plan.cost.totalCost.toStringAsFixed(1)}');
        buf.writeln(
            '  Cost without indexes: ${noIndexPlan.cost.totalCost.toStringAsFixed(1)}');
        buf.writeln(
            '  Index benefit: ${(noIndexPlan.cost.totalCost / plan.cost.totalCost).toStringAsFixed(1)}x faster');

        // Register more indexes and re-optimize
        buf.writeln('\n--- With More Indexes ---');
        optimizer.registerIndex('users', 'city');
        optimizer.registerIndex('users', 'role');
        final betterPlan = optimizer.optimize(query);
        buf.writeln('  New cost: ${betterPlan.cost}');
        buf.writeln('  Index hints: ${betterPlan.suggestedIndexes.length}');

        // Slow query log
        buf.writeln('\n--- Slow Query Log ---');
        optimizer.logSlowQuery(SlowQueryEntry(
          query: query,
          plan: plan,
          actualTimeUs: 500000,
          timestamp: DateTime.now(),
        ));
        final slowQueries = optimizer.slowQueries;
        for (final sq in slowQueries) {
          buf.writeln(
              '  ${sq.actualTimeUs}μs (${sq.slowdownFactor.toStringAsFixed(1)}x slower)');
        }

        // Recommendations
        buf.writeln('\n--- Recommendations ---');
        final recs = optimizer.analyzeSlowQueries();
        for (final rec in recs) {
          buf.writeln('  $rec');
        }

        // FilterDesc properties
        buf.writeln('\n--- Filter Properties ---');
        const eqFilter = FilterDesc('name', '==', 'Idris');
        const rangeFilter = FilterDesc('age', '>', 18);
        const containsFilter = FilterDesc('bio', 'contains', 'Rift');
        buf.writeln(
            '  Equality selectivity: ${eqFilter.estimatedSelectivity}, index-friendly: ${eqFilter.isIndexFriendly}');
        buf.writeln(
            '  Range selectivity: ${rangeFilter.estimatedSelectivity}, index-friendly: ${rangeFilter.isIndexFriendly}');
        buf.writeln(
            '  Contains selectivity: ${containsFilter.estimatedSelectivity}, index-friendly: ${containsFilter.isIndexFriendly}');

        return buf.toString();
      },
    );
  }
}
