import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class TimeseriesDemoPage extends StatelessWidget {
  const TimeseriesDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Time-Series',
      description: 'Time-series data storage and queries',
      codeExample:
          "await box.put('ts_\${now.millisecondsSinceEpoch}', metric);\nfinal pipeline = AggregationPipeline()\n  .group('shift', [AggregationOp('avg', AggregationOpType.avg)]);",
      runDemo: () async {
        final box = await Rift.openBox<Map>('ts_demo');
        await box.clear();
        final buf = StringBuffer();
        buf.writeln('=== Time-Series Data Demo ===\n');

        // Insert time-series data using timestamp keys
        final now = DateTime.now();
        final entries = <String, Map<String, dynamic>>{};
        for (int i = 0; i < 24; i++) {
          final ts = now.subtract(Duration(hours: 23 - i));
          final key = 'metric_${ts.millisecondsSinceEpoch}';
          entries[key] = {
            'timestamp': ts.toIso8601String(),
            'hour': ts.hour,
            'cpu': 20 + (i % 10) * 5.0,
            'memory': 40 + (i % 8) * 3.0,
            'requests': 100 + i * 10,
          };
        }
        await box.putAll(entries);
        buf.writeln('Inserted 24 hours of metrics\n');

        // Query recent data
        buf.writeln('--- Last 5 Hours (sorted by timestamp) ---');
        final recent = await box
            .query()
            .where('cpu', greaterThan: 0)
            .sortBy('timestamp')
            .limit(5)
            .findAll();
        for (final r in recent) {
          buf.writeln(
              '  hour=${r['hour']}, cpu=${r['cpu']}%, mem=${r['memory']}%, reqs=${r['requests']}');
        }

        // Aggregation on time-series
        buf.writeln('\n--- Aggregation: Avg CPU by 8-hour shifts ---');
        final pipeline = AggregationPipeline()
            .match((doc) => doc['cpu'] != null)
            .addFields((doc) {
          final hour = doc['hour'] as int;
          return {
            'shift': hour < 8 ? 'night' : (hour < 16 ? 'day' : 'evening')
          };
        }).group('shift', [
          AggregationOp('avgCpu', AggregationOpType.avg, inputField: 'cpu'),
          AggregationOp('avgMem', AggregationOpType.avg, inputField: 'memory'),
          AggregationOp('totalReqs', AggregationOpType.sum,
              inputField: 'requests'),
          AggregationOp('count', AggregationOpType.count),
        ]).sort('avgCpu', descending: true);
        final aggResults = await pipeline.execute(box);
        for (final doc in aggResults) {
          buf.writeln('  $doc');
        }

        // Cursor for large time-series
        buf.writeln('\n--- Cursor-Based Streaming ---');
        final cursor = RiftCursor(box, box.keys.toList(), batchSize: 8);
        int batchNum = 0;
        while (cursor.hasNext) {
          batchNum++;
          final batch = await cursor.nextBatch();
          buf.writeln('  Batch $batchNum: ${batch.length} entries');
        }

        buf.writeln('\n--- Time-Series Patterns ---');
        buf.writeln('  ✅ Use timestamp-based keys for time-series');
        buf.writeln('  ✅ Aggregation pipeline for rollups');
        buf.writeln('  ✅ Cursor for streaming large datasets');
        buf.writeln('  ✅ Query builder for time range filtering');
        buf.writeln('  ✅ TTL for auto-expiring old data');

        await box.close();
        return buf.toString();
      },
    );
  }
}
