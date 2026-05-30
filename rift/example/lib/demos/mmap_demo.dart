import 'package:flutter/material.dart';
import '../widgets/demo_page.dart';

class MmapDemoPage extends StatelessWidget {
  const MmapDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Memory-Mapped I/O',
      description: 'Memory-mapped file I/O for fast random access',
      codeExample:
          "// mmap maps file directly into memory\n// Rift uses mmap internally on VM platforms\n// Direct byte access without read()/write() overhead",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Memory-Mapped I/O (mmap) ===\n');

        buf.writeln('Memory-mapped file I/O maps a file directly into the');
        buf.writeln('process address space, enabling fast random access');
        buf.writeln('without explicit read/write system calls.\n');

        buf.writeln('--- How mmap Works ---\n');

        buf.writeln('Traditional I/O:');
        buf.writeln('  read() → kernel buffer → copy to user buffer → process');
        buf.writeln('  write() → user buffer → copy to kernel buffer → disk');
        buf.writeln('');

        buf.writeln('Memory-mapped I/O:');
        buf.writeln('  mmap() → file appears as memory → direct access');
        buf.writeln('  No copy between kernel and user space!');
        buf.writeln('');

        buf.writeln('┌────────────────────────────────┐');
        buf.writeln('│    Process Address Space        │');
        buf.writeln('│  ┌──────────────────────────┐  │');
        buf.writeln('│  │  Mapped Region (mmap)    │  │');
        buf.writeln('│  │  [page][page][page]...   │  │');
        buf.writeln('│  └──────┬───────────────────┘  │');
        buf.writeln('└─────────┼──────────────────────┘');
        buf.writeln('            │ (page faults handled by OS)');
        buf.writeln('  ┌─────────▼──────────────────────┐');
        buf.writeln('  │     File on Disk                │');
        buf.writeln('  │  [block][block][block]...       │');
        buf.writeln('  └────────────────────────────────┘');
        buf.writeln('');

        buf.writeln('--- Benefits for Database ---\n');

        buf.writeln('  ✅ Zero-copy reads — no buffer copying overhead');
        buf.writeln('  ✅ Fast random access — O(1) offset lookup');
        buf.writeln('  ✅ OS-managed paging — automatic page cache');
        buf.writeln('  ✅ Lazy loading — pages loaded on demand');
        buf.writeln('  ✅ Shared access — multiple processes can map same file');
        buf.writeln('  ✅ Large file support — handles files > RAM size');
        buf.writeln('');

        buf.writeln('--- Rift mmap Usage (VM Only) ---\n');

        buf.writeln('Memory-mapped I/O is available only on Dart VM');
        buf.writeln('(Android, iOS, macOS, Linux, Windows).');
        buf.writeln('Not available on web (JavaScript).\n');

        buf.writeln('Code example:');
        buf.writeln('');
        buf.writeln('  import \'dart:io\';');
        buf.writeln('  import \'package:rift/rift.dart\';');
        buf.writeln('');
        buf.writeln('  // Rift uses mmap internally for VM backends');
        buf.writeln('  // The StorageBackendVm reads frames using');
        buf.writeln('  // memory-mapped file I/O for performance.');
        buf.writeln('');
        buf.writeln('  // Manual mmap example (conceptual):');
        buf.writeln('  final file = File(\'/path/to/box.rift\');');
        buf.writeln('  final randomAccessFile = await file.open();');
        buf.writeln('  final length = await randomAccessFile.length();');
        buf.writeln('');
        buf.writeln('  // Read specific offset — OS uses page cache');
        buf.writeln('  await randomAccessFile.setPosition(1024);');
        buf.writeln('  final bytes = await randomAccessFile.read(256);');
        buf.writeln('');
        buf.writeln('  // Or use mmap package for direct memory mapping:');
        buf.writeln('  // final mapped = MmapFile(file.path, length);');
        buf.writeln('  // final byte = mapped[offset]; // Direct access!');
        buf.writeln('');

        buf.writeln('--- Performance Comparison ---\n');

        buf.writeln('  Operation     | Traditional I/O  | mmap');
        buf.writeln('  ─────────────────────────────────────────');
        buf.writeln('  Sequential    | read() + copy    | page walk');
        buf.writeln('  Random access | seek() + read()  | offset lookup');
        buf.writeln('  Write         | write() + copy   | memory write');
        buf.writeln('  Large files   | buffer overhead  | on-demand pages');
        buf.writeln('');

        buf.writeln('--- When to Use mmap ---\n');

        buf.writeln('  ✅ Large database files with random access patterns');
        buf.writeln('  ✅ Read-heavy workloads (pages cached by OS)');
        buf.writeln('  ✅ Multiple reader processes (shared mapping)');
        buf.writeln('  ✅ Low-latency lookups by key offset');
        buf.writeln('');

        buf.writeln('--- When NOT to Use mmap ---\n');

        buf.writeln('  ⚠️ Write-heavy workloads (page flush overhead)');
        buf.writeln('  ⚠️ Very small files (mmap setup cost > benefit)');
        buf.writeln('  ⚠️ Web platform (no mmap support in JavaScript)');
        buf.writeln('  ⚠️ 32-bit systems (address space limitations)');

        buf.writeln('\n--- Platform Support ---');
        buf.writeln('  ✅ Android   (Dart VM)');
        buf.writeln('  ✅ iOS       (Dart VM)');
        buf.writeln('  ✅ macOS     (Dart VM)');
        buf.writeln('  ✅ Linux     (Dart VM)');
        buf.writeln('  ✅ Windows   (Dart VM)');
        buf.writeln('  ❌ Web       (IndexedDB instead)');

        return buf.toString();
      },
    );
  }
}
