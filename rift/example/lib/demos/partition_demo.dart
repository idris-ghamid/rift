import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class PartitionDemoPage extends StatelessWidget {
  const PartitionDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Partitioning',
      description: 'Hash and range partitioning for large datasets',
      codeExample:
          "final pbox = PartitionedBox(\n  name: 'users',\n  strategy: HashPartitionStrategy(partitions: 4),\n  openBox: (n) => Rift.openBox<Map>(n),\n);",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Partitioning Demo ===\n');

        // Hash partition strategy
        final strategy = HashPartitionStrategy(partitionCount: 4);
        buf.writeln('Strategy: Hash, Partitions: ${strategy.partitionCount}');

        // Show which partition each key goes to
        buf.writeln('\n--- Key → Partition Mapping ---');
        final keys = [
          'user_alice',
          'user_bob',
          'user_charlie',
          'user_diana',
          'user_eve',
          'user_frank',
          'order_1',
          'order_2'
        ];
        for (final key in keys) {
          final p = strategy.partitionFor(key);
          buf.writeln('  $key → partition $p');
        }

        // Create partitioned box
        final partitioned = PartitionedBox(
          name: 'partition_demo',
          strategy: strategy,
          openBox: (name) => Rift.openBox<Map>(name),
        );
        await partitioned.initialize();

        // Insert data
        buf.writeln('\n--- Insert Data ---');
        await partitioned.put('user_alice', {'name': 'Alice', 'age': 30});
        await partitioned.put('user_bob', {'name': 'Bob', 'age': 22});
        await partitioned.put('user_charlie', {'name': 'Charlie', 'age': 35});
        await partitioned.put('user_diana', {'name': 'Diana', 'age': 19});
        buf.writeln('  Inserted 4 users');

        // Partition sizes
        buf.writeln('\n--- Partition Sizes ---');
        final sizes = partitioned.partitionSizes;
        for (final entry in sizes.entries) {
          buf.writeln('  Partition ${entry.key}: ${entry.value} entries');
        }

        // Retrieve data
        buf.writeln('\n--- Retrieve Data ---');
        final alice = partitioned.get('user_alice');
        buf.writeln('  user_alice: $alice');

        // Cross-partition query
        buf.writeln('\n--- Cross-partition Query (age > 25) ---');
        final results = await partitioned.query((data) => data['age'] > 25);
        for (final entry in results) {
          buf.writeln('  ${entry.key}: ${entry.value}');
        }

        // Total count
        buf.writeln('\n--- Total Stats ---');
        buf.writeln('  Total entries: ${partitioned.length}');
        buf.writeln('  Partition count: ${partitioned.partitionCount}');

        // Range partition strategy
        buf.writeln('\n--- Range Partition Strategy ---');
        final rangeStrategy = RangePartitionStrategy(['M', 'S']);
        buf.writeln('  Boundaries: [M, S] → 3 partitions');
        final names = ['Alice', 'Bob', 'Charlie', 'Diana', 'Eve', 'Frank'];
        for (final n in names) {
          buf.writeln('  $n → partition ${rangeStrategy.partitionFor(n)}');
        }

        await partitioned.close();
        return buf.toString();
      },
    );
  }
}
