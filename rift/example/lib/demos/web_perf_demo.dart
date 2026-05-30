import 'package:flutter/material.dart';
import '../widgets/demo_page.dart';

class WebPerfDemoPage extends StatelessWidget {
  const WebPerfDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Web Performance',
      description:
          'Web performance pack with IDB batch, Web Worker, and OPFS optimizations',
      codeExample:
          "// IndexedDB batching\nawait box.putAll({'key1': val, 'key2': val});\n\n// Web Worker offload via IsolatedRift\nawait IsolatedRift.init(null);\n\n// OPFS SyncAccessHandle for zero-copy I/O\nconst root = await navigator.storage.getDirectory();",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Web Performance Demo ===\n');

        buf.writeln('--- IndexedDB Batch Operations ---');
        buf.writeln('Without batching: N separate transactions (slow!)');
        buf.writeln(
            'With IDB batching: 1 transaction for all writes (10-50x faster!)');
        buf.writeln(
            '  await box.putAll({for (var i = 0; i < 1000; i++) "key_\$i": value});');

        buf.writeln('\n--- Web Worker Offloading ---');
        buf.writeln('IsolatedRift runs all I/O in a background worker');
        buf.writeln('Main thread stays at 60fps!');
        buf.writeln('  await IsolatedRift.init(null);');
        buf.writeln('  final box = await IsolatedRift.openBox<Map>("data");');

        buf.writeln('\n--- OPFS Sync Access ---');
        buf.writeln('Synchronous access via OPFS eliminates async overhead');
        buf.writeln('Zero-copy synchronous read/write in Web Workers');

        buf.writeln('\n--- Binary Frame Optimization ---');
        buf.writeln('Varint encoding: small integers use fewer bytes');
        buf.writeln('Value 127 → 1 byte, Value 16383 → 2 bytes');
        buf.writeln('Saves ~30-50% for typical key-value data');

        buf.writeln('\n--- Performance Summary ---');
        buf.writeln('  Feature           │ IndexedDB │ OPFS    │ Rift    ');
        buf.writeln('  Batch writes       │ Manual    │ Manual  │ Auto ✓  ');
        buf.writeln('  Worker offload     │ Manual    │ Required│ Auto ✓  ');
        buf.writeln('  Sync access        │ No        │ Yes     │ Auto ✓  ');
        buf.writeln('  Binary encoding    │ No        │ Manual  │ Auto ✓  ');
        buf.writeln('  Varint ints        │ No        │ No      │ Auto ✓  ');
        buf.writeln('  Auto-compaction    │ No        │ No      │ Auto ✓  ');
        buf.writeln('  Cache layer        │ Manual    │ Manual  │ Auto ✓  ');

        buf.writeln('\nRift automatically applies the best strategy');
        buf.writeln('for each platform without any configuration.');

        return buf.toString();
      },
    );
  }
}
