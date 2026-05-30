import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class MetricsDemoPage extends StatelessWidget {
  const MetricsDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Observability / Metrics',
      description: 'Collect timing, counts, and success rates for operations',
      codeExample:
          "final metrics = RiftMetrics.instance..enable();\nawait metrics.time(OperationType.put, 'box', () => box.put('k', 'v'));\nfinal report = metrics.generateReport();",
      runDemo: () async {
        final metrics = RiftMetrics.instance;
        metrics.clear();
        metrics.enable();

        final buf = StringBuffer();
        buf.writeln('=== Observability / Metrics Demo ===\n');
        buf.writeln('Metrics enabled: ${metrics.isEnabled}');

        // Perform various operations
        final box = await Rift.openBox<Map>('metrics_demo');
        await box.clear();

        buf.writeln('\n--- Performing Operations ---');
        // Timed puts
        await metrics.time(OperationType.put, 'metrics_demo', () async {
          await box.put('key1', {'value': 'data1'});
        });
        await metrics.time(OperationType.put, 'metrics_demo', () async {
          await box.put('key2', {'value': 'data2'});
        });
        await metrics.time(OperationType.put, 'metrics_demo', () async {
          await box.put('key3', {'value': 'data3'});
        });
        buf.writeln('  3 put operations');

        // Timed gets
        await metrics.time(OperationType.get, 'metrics_demo', () async {
          box.get('key1');
        });
        await metrics.time(OperationType.get, 'metrics_demo', () async {
          box.get('key2');
        });
        buf.writeln('  2 get operations');

        // Timed query
        await metrics.time(OperationType.query, 'metrics_demo', () async {
          await box.query().findAll();
        });
        buf.writeln('  1 query operation');

        // Simulate a failure
        metrics.recordFailure(OperationType.delete, 'metrics_demo', 500);
        buf.writeln('  1 simulated failure');

        // Show individual metrics
        buf.writeln('\n--- Individual Metrics ---');
        for (final m in metrics.allMetrics) {
          buf.writeln('  ${m.type.name} on ${m.boxName}:');
          buf.writeln(
              '    Count: ${m.count}, Success: ${m.successCount}, Fail: ${m.failureCount}');
          buf.writeln(
              '    Avg: ${m.avgDurationUs.round()}μs, Min: ${m.minDurationUs ?? "-"}μs, Max: ${m.maxDurationUs ?? "-"}μs');
          buf.writeln(
              '    Success rate: ${(m.successRate * 100).toStringAsFixed(1)}%');
        }

        // Generate report
        buf.writeln('\n--- Metrics Report ---');
        final report = metrics.generateReport();
        buf.writeln('  Generated at: ${report.generatedAt.toIso8601String()}');
        buf.writeln('  Metrics count: ${report.metrics.length}');

        // Markdown report
        buf.writeln('\n--- Markdown Report ---');
        final md = report.toMarkdown();
        for (final line in md.split('\n').take(6)) {
          buf.writeln('  $line');
        }

        // Prometheus format
        buf.writeln('\n--- Prometheus Format (sample) ---');
        final prom = report.toPrometheus();
        for (final line in prom.split('\n').take(6)) {
          buf.writeln('  $line');
        }

        await box.close();
        metrics.disable();
        return buf.toString();
      },
    );
  }
}
