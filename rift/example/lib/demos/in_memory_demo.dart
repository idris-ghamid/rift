import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class InMemoryDemoPage extends StatelessWidget {
  const InMemoryDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'In-Memory Mode',
      description: 'In-memory database mode with no disk writes',
      codeExample:
          "// Initialize in-memory mode\nawait Rift.init('');\n\n// Open box — data lives only in RAM\nfinal box = await Rift.openBox<Map>('demo');\nawait box.put('key', {'data': 'value'});",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== In-Memory Mode Demo ===\n');

        buf.writeln('In-memory mode stores data only in RAM — no disk writes.');
        buf.writeln('Perfect for tests, demos, caching, and temporary data.\n');

        buf.writeln('--- Step 1: In-Memory Concept ---');
        buf.writeln(
            '  To use in-memory mode: Rift.init(\'\') or Rift.init(null)');
        buf.writeln(
            '  This sets up a volatile backend with no disk persistence.');
        buf.writeln('  Note: Rift is already initialized by the app.\n');

        // Open a regular box for demonstration
        buf.writeln('--- Step 2: Open Box ---');
        final box = await Rift.openBox<Map>('memory_demo');
        await box.clear();
        buf.writeln('  Box opened: ${box.name}');
        buf.writeln('');

        // Add data
        buf.writeln('--- Step 3: Add Data ---');
        await box.put('session', {'user': 'Alice', 'role': 'admin'});
        await box.put('temp_cache', {'key': 'data', 'ttl': 30});
        await box.put('counter', {'value': 42});
        buf.writeln('  Added 3 entries to box');
        for (final k in box.keys) {
          buf.writeln('    $k => ${box.get(k)}');
        }
        buf.writeln('');

        // Verify data exists
        buf.writeln('--- Step 4: Verify Data ---');
        buf.writeln('  box.length = ${box.length}');
        buf.writeln(
            '  box.containsKey("session") = ${box.containsKey("session")}');
        buf.writeln('  box.get("counter") = ${box.get("counter")}');
        buf.writeln('');

        // Update data
        buf.writeln('--- Step 5: Update Data ---');
        await box.put('counter', {'value': 100});
        buf.writeln('  Updated counter -> ${box.get("counter")}');
        buf.writeln('');

        // Delete
        buf.writeln('--- Step 6: Delete Data ---');
        await box.delete('temp_cache');
        buf.writeln('  Deleted temp_cache');
        buf.writeln('  box.length = ${box.length}');
        buf.writeln('');

        buf.writeln('--- In-Memory vs Persistent ---');
        buf.writeln('  In-memory:  Rift.init(\'\')  -> data lost on close');
        buf.writeln('  Persistent: Rift.init(path) -> data survives restart');
        buf.writeln('');

        buf.writeln('--- Use Cases ---');
        buf.writeln('  Unit testing - fast, no file I/O');
        buf.writeln(
            '  Caching - temporary data that doesn\'t need persistence');
        buf.writeln('  Demos & prototyping - quick setup without disk');
        buf.writeln('  Session data - ephemeral user sessions');

        await box.close();
        return buf.toString();
      },
    );
  }
}
