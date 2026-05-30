import 'package:flutter/material.dart';
import '../widgets/demo_page.dart';

class BinaryStorageDemoPage extends StatelessWidget {
  const BinaryStorageDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Binary Storage',
      description: 'Binary storage for large objects with metadata',
      codeExample:
          "final storage = RiftBinaryStorage(basePath: dir);\nawait storage.store('img1', bytes, mimeType: 'image/png');\nfinal data = await storage.retrieve('img1');",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Binary Storage Demo ===\n');

        // BinaryStorage requires file I/O so we demonstrate the API
        buf.writeln(
            'Binary storage handles large objects (images, PDFs, audio)\n');

        buf.writeln('--- API Overview ---');
        buf.writeln('  final storage = RiftBinaryStorage(');
        buf.writeln('    basePath: "/app/binary",');
        buf.writeln('    maxInMemorySize: 10 * 1024 * 1024, // 10MB cache');
        buf.writeln('  );');

        buf.writeln('\n--- Store Binary Data ---');
        buf.writeln('  await storage.store(');
        buf.writeln('    "photo1",');
        buf.writeln('    imageBytes,');
        buf.writeln('    mimeType: "image/png",');
        buf.writeln('    metadata: {"album": "vacation"},');
        buf.writeln('    encrypt: true,');
        buf.writeln('  );');

        buf.writeln('\n--- Retrieve ---');
        buf.writeln('  final data = await storage.retrieve("photo1");');
        buf.writeln('  final meta = storage.getMetadata("photo1");');

        buf.writeln('\n--- Metadata ---');
        buf.writeln('  BinaryMetadata {');
        buf.writeln('    key, mimeType, size, storedAt,');
        buf.writeln('    metadata (user-provided), isEncrypted, hash');
        buf.writeln('  }');

        buf.writeln('\n--- Features ---');
        buf.writeln('  ✅ SHA-256 content hash for integrity');
        buf.writeln('  ✅ Optional XOR encryption');
        buf.writeln('  ✅ LRU in-memory cache with size limit');
        buf.writeln('  ✅ Lazy loading from disk');
        buf.writeln('  ✅ Custom metadata per entry');
        buf.writeln('  ✅ Separate .bin and .meta files');

        buf.writeln('\n--- Other Operations ---');
        buf.writeln('  storage.keys        → list all keys');
        buf.writeln('  storage.totalSize   → total bytes stored');
        buf.writeln('  storage.delete(key) → remove entry');
        buf.writeln('  storage.clearCache()→ clear memory cache');

        return buf.toString();
      },
    );
  }
}
