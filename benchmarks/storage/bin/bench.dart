import 'dart:io';

import 'package:csv/csv.dart';
import 'package:rift/rift.dart' as rift;
import '../lib/bench_result.dart';
import '../lib/benchmark.dart';
import '../lib/db_type.dart';
import '../lib/test_model.dart';

const benchmarks = [10, 100, 1000, 10000, 100000, 1000000];

void main() async {
  rift.Rift.init('.');
  rift.Rift.registerAdapter(TestModelAdapter());

  await rift.IsolatedRift.init('.');
  rift.IsolatedRift.registerAdapter(TestModelAdapter());

  final riftResults = <BenchResult>[];
  final isolatedResults = <BenchResult>[];

  for (final operations in benchmarks) {
    final riftResult = await runBenchmark(
      name: 'Rift',
      operations: operations,
      type: DbType.rift,
      openBox: rift.Rift.openBox,
    );

    final isolatedResult = await runBenchmark(
      name: 'IsolatedRift',
      operations: operations,
      type: DbType.rift,
      openBox: rift.IsolatedRift.openBox,
    );

    riftResults.add(riftResult);
    isolatedResults.add(isolatedResult);
  }

  await rift.Rift.close();
  await rift.IsolatedRift.close();

  final csvString = csv.encode([
    [
      'Operations',
      'Rift Time',
      'IsolatedRift Time',
      'Rift Size',
      'IsolatedRift Size',
    ],
    for (var i = 0; i < benchmarks.length; i++)
      [
        benchmarks[i],
        formatTime(riftResults[i].time),
        formatTime(isolatedResults[i].time),
        formatSize(riftResults[i].size),
        formatSize(isolatedResults[i].size),
      ],
  ]);

  File('results.csv').writeAsStringSync(csvString);
}

// Format a duration to "00.00 s"
String formatTime(Duration duration) {
  final seconds = duration.inMilliseconds / 1000;
  return '${seconds.toStringAsFixed(2)} s';
}

String formatSize(double size) {
  return '${size.toStringAsFixed(2)} MB';
}
