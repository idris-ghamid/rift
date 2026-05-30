import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class ProfilerDemoPage extends StatelessWidget {
  const ProfilerDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Profiler',
      description: 'Performance profiling for database operations',
      codeExample:
          "final profiler = RiftProfiler()..enable();\nawait profiler.time('op', () => doWork());\nfinal report = profiler.generateReport();",
      runDemo: () async {
        final profiler = RiftProfiler();
        profiler.enable();

        final buf = StringBuffer();
        buf.writeln('=== Profiler Demo ===\n');

        // Profile async operations
        buf.writeln('--- Profiling Operations ---');
        for (int i = 0; i < 5; i++) {
          await profiler.time('db_write', () async {
            await Future.delayed(Duration(milliseconds: 10 + i * 5));
          });
        }

        for (int i = 0; i < 3; i++) {
          await profiler.time('db_read', () async {
            await Future.delayed(Duration(milliseconds: 2 + i));
          });
        }

        // Simulate a failure
        try {
          await profiler.time('db_delete', () async {
            await Future.delayed(const Duration(milliseconds: 5));
            throw Exception('Record not found');
          });
        } catch (_) {}

        buf.writeln('  5 writes, 3 reads, 1 failed delete\n');

        // Per-operation stats
        buf.writeln('--- db_write Stats ---');
        final writeStats = profiler.getStats('db_write');
        if (writeStats != null) {
          buf.writeln('  Count: ${writeStats.count}');
          buf.writeln('  Failures: ${writeStats.failures}');
          buf.writeln('  Avg: ${writeStats.averageTime.inMilliseconds}ms');
          buf.writeln('  Min: ${writeStats.minTime.inMilliseconds}ms');
          buf.writeln('  Max: ${writeStats.maxTime.inMilliseconds}ms');
          buf.writeln('  Failure rate: ${writeStats.failureRate}');
        }

        // Full report
        buf.writeln('\n--- Full Report ---');
        final report = profiler.generateReport();
        buf.writeln('  Total ops: ${report.summary['totalOperations']}');
        buf.writeln('  Total failures: ${report.summary['totalFailures']}');
        buf.writeln(
            '  Total time: ${report.summary['totalTimeMs']?.toStringAsFixed(2)}ms');
        for (final op in report.operations.entries) {
          buf.writeln(
              '  ${op.key}: avg=${op.value['avgTimeMs']?.toStringAsFixed(2)}ms, p95=${op.value['p95Ms']?.toStringAsFixed(2)}ms');
        }

        // Markdown report
        buf.writeln('\n--- Markdown Report ---');
        buf.writeln(report.toMarkdown().substring(0, 300));

        profiler.reset();
        return buf.toString();
      },
    );
  }
}
