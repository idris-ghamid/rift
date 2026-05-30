import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class BloomFilterDemoPage extends StatelessWidget {
  const BloomFilterDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Bloom Filter',
      description: 'Bloom filter for fast key existence checking',
      codeExample:
          "final filter = BloomFilter(expectedItems: 10000);\nfilter.add('key');\nfilter.mightContain('key'); // true\nfilter.mightContain('other'); // false or false-positive",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Bloom Filter Demo ===\n');

        final filter = BloomFilter(expectedItems: 100, falsePositiveRate: 0.01);
        buf.writeln('Created: 100 items, 1% FPR');
        buf.writeln('  Bit size: ${filter.bitSize}');
        buf.writeln('  Hash functions: ${filter.numHashes}\n');

        // Add keys
        final keys = [
          'user:1',
          'user:2',
          'user:3',
          'session:abc',
          'session:xyz'
        ];
        for (final key in keys) {
          filter.add(key);
        }
        buf.writeln('Added $keys\n');

        // Check existing keys (should return true)
        buf.writeln('--- Check Existing Keys ---');
        for (final key in keys) {
          buf.writeln('  mightContain("$key"): ${filter.mightContain(key)}');
        }

        // Check non-existing keys
        buf.writeln('\n--- Check Non-Existing Keys ---');
        final notExists = ['user:999', 'session:missing', 'cache:old'];
        for (final key in notExists) {
          final result = filter.mightContain(key);
          buf.writeln(
              '  mightContain("$key"): $result ${result ? "(false positive!)" : "(correctly negative)"}');
        }

        // Stats
        buf.writeln('\n--- Stats ---');
        buf.writeln('  Count: ${filter.count}');
        buf.writeln(
            '  Fill ratio: ${(filter.fillRatio * 100).toStringAsFixed(1)}%');
        buf.writeln(
            '  Expected FPR: ${(filter.expectedFalsePositiveRate * 100).toStringAsFixed(2)}%');

        // Merge
        buf.writeln('\n--- Merge Two Filters ---');
        final filter2 =
            BloomFilter(expectedItems: 100, falsePositiveRate: 0.01);
        filter2.add('extra:1');
        filter2.add('extra:2');
        final merged = filter.merge(filter2);
        buf.writeln('  Merged count: ${merged.count}');
        buf.writeln(
            '  mightContain("extra:1"): ${merged.mightContain("extra:1")}');
        buf.writeln(
            '  mightContain("user:1"): ${merged.mightContain("user:1")}');

        // Serialization
        buf.writeln('\n--- Serialization ---');
        final bytes = filter.toBytes();
        buf.writeln('  Serialized: ${bytes.length} bytes');
        final restored = BloomFilter.fromBytes(bytes);
        buf.writeln('  Restored count: ${restored.count}');
        buf.writeln(
            '  mightContain("user:1"): ${restored.mightContain("user:1")}');

        return buf.toString();
      },
    );
  }
}
