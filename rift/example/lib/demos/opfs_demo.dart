import 'package:flutter/material.dart';
import '../widgets/demo_page.dart';

class OpfsDemoPage extends StatelessWidget {
  const OpfsDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'OPFS Support',
      description: 'OPFS support for near-native web performance',
      codeExample:
          "// OPFS is accessed via navigator.storage\nconst root = await navigator.storage.getDirectory();\nconst fileHandle = await root.getFileHandle('data.rift',\n    { create: true });\nconst accessHandle =\n    await fileHandle.createSyncAccessHandle();",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== OPFS Support Demo ===\n');

        buf.writeln('--- What is OPFS? ---');
        buf.writeln(
            '  Origin Private File System (OPFS) is a web API providing');
        buf.writeln('  direct access to a domain-private filesystem.\n');

        buf.writeln('--- FileSystemSyncAccessHandle ---');
        buf.writeln(
            '  FileSystemSyncAccessHandle enables synchronous read/write');
        buf.writeln('  inside a Web Worker, eliminating async overhead.\n');

        buf.writeln('--- Performance Comparison ---');
        buf.writeln('  ┌──────────────┬──────────────┬─────────┐');
        buf.writeln('  │ Operation     │ IndexedDB    │ OPFS    │');
        buf.writeln('  ├──────────────┼──────────────┼─────────┤');
        buf.writeln('  │ Write 1KB    │ ~2ms         │ ~0.05ms │');
        buf.writeln('  │ Read 1KB     │ ~1ms         │ ~0.02ms │');
        buf.writeln('  │ Write 100KB  │ ~15ms        │ ~0.3ms  │');
        buf.writeln('  │ Read 100KB   │ ~8ms         │ ~0.1ms  │');
        buf.writeln('  │ Bulk 1000 ops│ ~200ms       │ ~5ms    │');
        buf.writeln('  └──────────────┴──────────────┴─────────┘\n');

        buf.writeln('--- Rift + OPFS Integration ---');
        buf.writeln(
            '  Rift automatically uses OPFS on the web when available,');
        buf.writeln('  falling back to IndexedDB.');
        buf.writeln('  Rift.init(null); // Auto-selects best backend\n');

        buf.writeln('--- Web Worker Architecture ---');
        buf.writeln('  Rift runs inside a Web Worker to prevent I/O from');
        buf.writeln('  blocking the main thread.\n');

        buf.writeln('--- Key Points ---');
        buf.writeln('  • OPFS requires Secure Context (HTTPS)');
        buf.writeln('  • SyncAccessHandle only in Web Workers');
        buf.writeln('  • 10-100x faster than IndexedDB');
        buf.writeln('  • No structured clone overhead');
        buf.writeln('  • Rift auto-detects and uses OPFS');

        return buf.toString();
      },
    );
  }
}
