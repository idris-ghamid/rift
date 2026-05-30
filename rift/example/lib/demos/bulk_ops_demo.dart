import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class BulkOpsDemoPage extends StatelessWidget {
  const BulkOpsDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Bulk Operations',
      description: 'High-performance bulk put, get, and delete',
      codeExample:
          "BulkOperations.bulkPut(box, entries, batchSize: 1000);\nBulkOperations.bulkGet(box, keys);\nBulkOperations.exportJson(box);",
      runDemo: () async {
        final box = await Rift.openBox<Map>('bulk_demo');
        await box.clear();
        final buf = StringBuffer();
        buf.writeln('=== Bulk Operations Demo ===\n');

        // Bulk put
        buf.writeln('--- Bulk Put (100 entries) ---');
        final entries = <String, Map<String, dynamic>>{};
        for (int i = 0; i < 100; i++) {
          entries['item_$i'] = {'name': 'Item $i', 'value': i * 10};
        }
        final sw = Stopwatch()..start();
        final written =
            await BulkOperations.bulkPut(box, entries, batchSize: 25);
        sw.stop();
        buf.writeln(
            '  Written: $written entries in ${sw.elapsedMilliseconds}ms');

        // Bulk get
        buf.writeln('\n--- Bulk Get (selected keys) ---');
        final keys = ['item_10', 'item_50', 'item_99', 'item_999'];
        final results = await BulkOperations.bulkGet(box, keys);
        for (final e in results.entries) {
          buf.writeln('  ${e.key} => ${e.value}');
        }

        // Export JSON
        buf.writeln('\n--- Export as JSON ---');
        final exported = await BulkOperations.exportJson(box);
        buf.writeln('  Exported ${exported.length} entries');

        // Import JSON
        buf.writeln('\n--- Import from JSON ---');
        final importData = {
          'new_1': {'name': 'New Item', 'value': 999}
        };
        final imported = await BulkOperations.importJson(box, importData);
        buf.writeln('  Imported: $imported entries');
        buf.writeln('  Box length: ${box.length}');

        // Count where
        buf.writeln('\n--- Count Where (value > 500) ---');
        final cnt = await BulkOperations.countWhere(
          box,
          (key, value) => value is Map && (value['value'] ?? 0) > 500,
        );
        buf.writeln('  Count: $cnt');

        // Delete where
        buf.writeln('\n--- Delete Where (value < 100) ---');
        final deleted = await BulkOperations.deleteWhere(
          box,
          (key, value) => value is Map && (value['value'] ?? 0) < 100,
        );
        buf.writeln('  Deleted: $deleted');
        buf.writeln('  Remaining: ${box.length}');

        await box.close();
        return buf.toString();
      },
    );
  }
}
