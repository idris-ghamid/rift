import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class IndexDemoPage extends StatelessWidget {
  const IndexDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Secondary Index',
      description: 'Secondary indexes accelerate lookups and range queries',
      codeExample:
          "indexManager.createIndex('box', 'age', type: IndexType.btree);\nawait indexManager.queryIndex('box', 'age', 25, op: IndexOperator.gt);",
      runDemo: () async {
        final indexManager = IndexManager();
        final box = await Rift.openBox<Map>('index_demo');
        await box.clear();

        final buf = StringBuffer();
        buf.writeln('=== Secondary Index Demo ===\n');

        // Create index
        await indexManager.createIndex('index_demo', 'age',
            type: IndexType.btree);
        await indexManager.createIndex('index_demo', 'city',
            type: IndexType.hash);
        buf.writeln('Created btree index on "age", hash index on "city"');

        // Register field extractor
        indexManager.registerFieldExtractor('index_demo', (value, field) {
          if (value is Map) return value[field];
          return null;
        });

        // Insert data and update indexes
        final users = {
          'u1': {'name': 'Alice', 'age': 30, 'city': 'Cairo'},
          'u2': {'name': 'Bob', 'age': 22, 'city': 'Riyadh'},
          'u3': {'name': 'Charlie', 'age': 35, 'city': 'Cairo'},
          'u4': {'name': 'Diana', 'age': 19, 'city': 'Dubai'},
        };
        for (final e in users.entries) {
          await box.put(e.key, e.value);
          await indexManager.updateIndex('index_demo', e.key, e.value);
        }

        buf.writeln('\nInserted 4 users\n');

        // Query btree index - range query
        buf.writeln('--- BTree index: age > 25 ---');
        final ageKeys = await indexManager.queryIndex('index_demo', 'age', 25,
            op: IndexOperator.gt);
        buf.writeln('  Keys: $ageKeys');
        for (final k in ageKeys) {
          buf.writeln('  $k => ${box.get(k)}');
        }

        // Query hash index - equality
        buf.writeln('\n--- Hash index: city == Cairo ---');
        final cityKeys =
            await indexManager.queryIndex('index_demo', 'city', 'Cairo');
        buf.writeln('  Keys: $cityKeys');
        for (final k in cityKeys) {
          buf.writeln('  $k => ${box.get(k)}');
        }

        buf.writeln('\n--- Has index on "age"? ---');
        buf.writeln('  ${indexManager.hasIndex('index_demo', 'age')}');

        // Composite index
        await indexManager.createCompositeIndex('index_demo', ['city', 'age']);
        buf.writeln('\nCreated composite index on [city, age]');

        await box.close();
        return buf.toString();
      },
    );
  }
}
