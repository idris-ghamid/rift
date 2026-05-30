import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class CompressionDemoPage extends StatelessWidget {
  const CompressionDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Compression',
      description: 'LZ4 compression for storage space savings',
      codeExample:
          "await Rift.openBox('data', compression: RiftCompression.lz4);\nfinal compressed = RiftCompression.lz4.compress(data);",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== LZ4 Compression Demo ===\n');

        final compression = RiftCompression.lz4;
        buf.writeln('Algorithm: LZ4');
        buf.writeln('Threshold: ${compression.threshold} bytes\n');

        // Small data (below threshold → not compressed)
        final small = Uint8List.fromList(List.generate(100, (i) => i));
        buf.writeln(
            '--- Small Data (${small.length} bytes, below threshold) ---');
        final compressedSmall = compression.compress(small);
        buf.writeln('  Compressed: ${compressedSmall.length} bytes');
        buf.writeln(
            '  Marker: 0x${compressedSmall[0].toRadixString(16)} (0x00 = uncompressed)');
        final decompressedSmall = compression.decompress(compressedSmall);
        buf.writeln(
            '  Round-trip OK: ${_listsEqual(small, decompressedSmall)}');

        // Large repetitive data (above threshold → compressed)
        final large = Uint8List.fromList(List.generate(2000, (i) => i % 10));
        buf.writeln('\n--- Large Repetitive Data (${large.length} bytes) ---');
        final compressedLarge = compression.compress(large);
        buf.writeln('  Compressed: ${compressedLarge.length} bytes');
        buf.writeln(
            '  Ratio: ${(compressedLarge.length / large.length * 100).toStringAsFixed(1)}%');
        buf.writeln(
            '  Savings: ${(100 - compressedLarge.length / large.length * 100).toStringAsFixed(1)}%');
        buf.writeln(
            '  Marker: 0x${compressedLarge[0].toRadixString(16)} (0x01 = compressed)');
        final decompressedLarge = compression.decompress(compressedLarge);
        buf.writeln(
            '  Round-trip OK: ${_listsEqual(large, decompressedLarge)}');

        // Compressed box
        buf.writeln('\n--- Compressed Box ---');
        final box = await Rift.openBox<String>('compress_demo',
            compression: RiftCompression.lz4);
        await box.clear();
        await box.put('data', 'A' * 1000); // repetitive string
        buf.writeln('  Stored 1000-char repetitive string');
        buf.writeln(
            '  Retrieved: ${box.get('data')?.substring(0, 20)}… (${box.get('data')?.length} chars)');

        // Custom threshold
        buf.writeln('\n--- Custom Threshold ---');
        final custom =
            RiftCompression(algorithm: CompressionAlgorithm.lz4, threshold: 64);
        buf.writeln('  Threshold: ${custom.threshold}');
        buf.writeln('  isEnabled: ${custom.isEnabled}');

        await box.close();
        return buf.toString();
      },
    );
  }

  static bool _listsEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
