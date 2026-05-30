import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class InspectorDemoPage extends StatelessWidget {
  const InspectorDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Inspector',
      description: 'Box inspection and debugging utilities',
      codeExample:
          "// Inspect a box\nprint(box.toMap());\nprint(box.keys.toList());\nfinal exists = await Rift.boxExists('myBox');",
      runDemo: () async {
        final box = await Rift.openBox<Map>('inspect_demo');
        await box.clear();
        final buf = StringBuffer();
        buf.writeln('=== Inspector / Debug Utilities Demo ===\n');

        // Populate
        await box.putAll({
          'u1': {'name': 'Alice', 'age': 30, 'active': true},
          'u2': {'name': 'Bob', 'age': 25, 'active': false},
          'u3': {'name': 'Charlie', 'age': 35, 'active': true},
        });

        // Basic inspection
        buf.writeln('--- Box Inspection ---');
        buf.writeln('  Box name: ${box.name}');
        buf.writeln('  Is open: ${box.isOpen}');
        buf.writeln('  Length: ${box.length}');
        buf.writeln('  Is empty: ${box.isEmpty}');
        buf.writeln('  Keys: ${box.keys.toList()}');

        // Value inspection
        buf.writeln('\n--- Value Inspection ---');
        for (final key in box.keys) {
          final val = box.get(key);
          buf.writeln('  $key => $val');
          buf.writeln('    Type: ${val.runtimeType}');
          buf.writeln(
              '    Contains "name": ${(val as Map).containsKey('name')}');
        }

        // Check existence
        buf.writeln('\n--- Key Existence ---');
        buf.writeln('  containsKey("u1"): ${box.containsKey('u1')}');
        buf.writeln('  containsKey("u99"): ${box.containsKey('u99')}');

        // toMap dump
        buf.writeln('\n--- Full Data Dump ---');
        final fullMap = box.toMap();
        buf.writeln('  ${fullMap.length} entries total');

        // Query inspection
        buf.writeln('\n--- Query Inspection ---');
        final query = box.query().where('age', greaterThan: 25).sortBy('name');
        buf.writeln('  Query: $query');

        // Box exists check
        buf.writeln('\n--- Box Exists ---');
        buf.writeln(
            '  inspect_demo exists: ${await Rift.boxExists('inspect_demo')}');
        buf.writeln(
            '  nonexistent exists: ${await Rift.boxExists('nonexistent')}');

        // Delete box
        buf.writeln('\n--- Cleanup ---');
        buf.writeln('  Box open: ${Rift.isBoxOpen('inspect_demo')}');
        await box.close();
        buf.writeln('  Box closed');

        buf.writeln('\n--- Debug Tips ---');
        buf.writeln('  ✅ Use box.toMap() for full data dump');
        buf.writeln('  ✅ Use box.query() for filtered inspection');
        buf.writeln('  ✅ Use Rift.boxExists() before opening');
        buf.writeln('  ✅ Use Rift.isBoxOpen() to check state');
        buf.writeln('  ✅ Use Rift.deleteBoxFromDisk() for cleanup');

        return buf.toString();
      },
    );
  }
}
