import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class CursorDemoPage extends StatelessWidget {
  const CursorDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Cursor Iterator',
      description: 'Cursor-based iteration for large datasets',
      codeExample:
          "final cursor = RiftCursor(box, keys, batchSize: 50);\nwhile (cursor.hasNext) {\n  final batch = await cursor.nextBatch();\n}",
      runDemo: () async {
        final box = await Rift.openBox<Map>('cursor_demo');
        await box.clear();
        final buf = StringBuffer();
        buf.writeln('=== Cursor Iterator Demo ===\n');

        for (int i = 0; i < 10; i++) {
          await box.put('item_$i', {'name': 'Item $i', 'value': i * 5});
        }
        buf.writeln('Created 10 items\n');

        // Basic iteration
        buf.writeln('--- Forward Iteration (batch of 3) ---');
        final cursor = RiftCursor<String, Map>(
            box, box.keys.toList().cast<String>(),
            batchSize: 3);
        int batch = 0;
        while (cursor.hasNext) {
          batch++;
          final items = await cursor.nextBatch();
          buf.writeln('  Batch $batch: ${items.map((e) => e.key).toList()}');
        }

        // Reset and skip
        buf.writeln('\n--- Skip + Peek ---');
        cursor.reset();
        cursor.skip(3);
        buf.writeln('  Skipped 3, position: ${cursor.position}');
        final peeked = cursor.peek();
        buf.writeln('  Peek: ${peeked?.key} => ${peeked?.value}');

        // Where filter
        buf.writeln('\n--- Filter: value > 25 ---');
        cursor.reset();
        final filtered = await cursor.where((key, value) {
          if (value is Map) return (value['value'] ?? 0) > 25;
          return false;
        });
        final filteredItems = await filtered.collectAll();
        buf.writeln('  Found ${filteredItems.length} items:');
        for (final e in filteredItems) {
          buf.writeln('    ${e.key} => ${e.value}');
        }

        // Map transform
        buf.writeln('\n--- Map: extract names ---');
        cursor.reset();
        final mapped =
            await cursor.map((key, value) => value?['name'] ?? 'unknown');
        final mappedItems = await mapped.collectAll();
        buf.writeln('  Names: ${mappedItems.map((e) => e.value).toList()}');

        buf.writeln('\n--- Cursor Stats ---');
        buf.writeln('  Length: ${cursor.length}');
        buf.writeln('  Remaining: ${cursor.remaining}');
        buf.writeln('  Is exhausted: ${cursor.isExhausted}');

        await box.close();
        return buf.toString();
      },
    );
  }
}
