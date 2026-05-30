import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class IsolateDemoPage extends StatelessWidget {
  const IsolateDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Isolate Support',
      description:
          'Native isolate support for safe multi-isolate database access',
      codeExample:
          "await IsolatedRift.init(null);\nfinal box = await IsolatedRift.openBox<Map>('demo');\nawait box.put('key', {'name': 'Alice'});\nfinal val = await box.get('key');\nawait IsolatedRift.close();",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Native Isolate Support Demo ===\n');

        // Initialize IsolatedRift
        buf.writeln('--- Initializing IsolatedRift ---');
        await IsolatedRift.init(null);
        buf.writeln('  IsolatedRift.init(null) → in-memory isolate mode');
        buf.writeln(
            '  IsolatedRift provides safe multi-isolate database access');

        // Open a box in the isolate
        buf.writeln('\n--- Opening Box in Isolate ---');
        final box = await IsolatedRift.openBox<Map>('isolate_demo');
        buf.writeln('  Opened box: ${box.name}');
        buf.writeln('  Box is lazy: ${box.lazy}');

        // Write data
        buf.writeln('\n--- Writing Data ---');
        await box.put('user1', {'name': 'Alice', 'age': 30});
        await box.put('user2', {'name': 'Bob', 'age': 25});
        await box.put('user3', {'name': 'Charlie', 'age': 35});
        buf.writeln('  Put 3 user entries');

        // Read data back
        buf.writeln('\n--- Reading Data Back ---');
        final user1 = await box.get('user1');
        final user2 = await box.get('user2');
        buf.writeln('  user1: $user1');
        buf.writeln('  user2: $user2');

        // Check box properties
        buf.writeln('\n--- Box Properties ---');
        final keys = await box.keys;
        final length = await box.length;
        final isEmpty = await box.isEmpty;
        buf.writeln('  Keys: $keys');
        buf.writeln('  Length: $length');
        buf.writeln('  Is empty: $isEmpty');

        // Contains key check
        buf.writeln('\n--- Contains Key Check ---');
        final hasUser1 = await box.containsKey('user1');
        final hasUser99 = await box.containsKey('user99');
        buf.writeln('  containsKey("user1"): $hasUser1');
        buf.writeln('  containsKey("user99"): $hasUser99');

        // PutAll
        buf.writeln('\n--- Batch Put (putAll) ---');
        await box.putAll({
          'user4': {'name': 'Diana', 'age': 28},
          'user5': {'name': 'Eve', 'age': 22},
        });
        final newLength = await box.length;
        buf.writeln('  After putAll: length = $newLength');

        // Delete
        buf.writeln('\n--- Delete Operation ---');
        await box.delete('user3');
        final afterDelete = await box.length;
        buf.writeln('  After delete("user3"): length = $afterDelete');

        // Convert to map
        buf.writeln('\n--- Full Box Contents ---');
        final allData = await box.toMap();
        for (final entry in allData.entries) {
          buf.writeln('  ${entry.key}: ${entry.value}');
        }

        // Cleanup
        await box.close();
        await IsolatedRift.close();

        buf.writeln('\n--- Isolate Communication ---');
        buf.writeln('  IsolatedRift delegates calls to a background isolate');
        buf.writeln('  This ensures safe concurrent access without locks');
        buf.writeln('  On web, IsolatedRift falls back to direct Rift calls');

        buf.writeln('\n✅ Isolate demo complete');

        return buf.toString();
      },
    );
  }
}
