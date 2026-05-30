import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class DictCompressDemoPage extends StatelessWidget {
  const DictCompressDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Dictionary Compression',
      description: 'Dictionary-based compression for structured data',
      codeExample:
          "final comp = DictionaryCompressor();\ncomp.learn({'type': 'user', 'name': 'Idris'});\nfinal compressed = comp.compress(data);\nfinal original = comp.decompress(compressed);",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Dictionary Compression Demo ===\n');

        final compressor = DictionaryCompressor();

        // Learn patterns from similar structured data
        buf.writeln('--- Learn Patterns ---');
        compressor.learn({
          'type': 'user',
          'name': 'Idris',
          'city': 'Cairo',
          'role': 'admin'
        });
        compressor.learn({
          'type': 'user',
          'name': 'Ahmed',
          'city': 'Cairo',
          'role': 'editor'
        });
        compressor.learn({
          'type': 'user',
          'name': 'Sara',
          'city': 'Riyadh',
          'role': 'viewer'
        });
        buf.writeln('  Dictionary size: ${compressor.dictionary.size} entries');
        buf.writeln('  Learned from 3 similar records');

        // Show dictionary contents
        buf.writeln('\n--- Dictionary Contents (sample) ---');
        final patterns = compressor.dictionary.patterns.take(15).toList();
        for (final p in patterns) {
          final code = compressor.dictionary.getCode(p);
          buf.writeln('  "$p" → code $code');
        }

        // Compress data
        buf.writeln('\n--- Compress Data ---');
        final data = {
          'type': 'user',
          'name': 'Khalid',
          'city': 'Cairo',
          'role': 'admin'
        };
        buf.writeln('  Original: $data');
        final compressed = compressor.compress(data);
        buf.writeln('  Compressed: $compressed');

        // Decompress
        buf.writeln('\n--- Decompress ---');
        final decompressed = compressor.decompress(compressed);
        buf.writeln('  Decompressed: $decompressed');
        buf.writeln('  Match: ${decompressed.toString() == data.toString()}');

        // Compression ratio
        buf.writeln('\n--- Compression Ratio ---');
        final ratio = compressor.estimateCompressionRatio(data);
        buf.writeln(
            '  Ratio: ${(ratio * 100).toStringAsFixed(1)}% of original');
        buf.writeln('  Savings: ${((1 - ratio) * 100).toStringAsFixed(1)}%');

        // Without dictionary
        buf.writeln('\n--- Without Dictionary ---');
        final freshCompressor = DictionaryCompressor(autoLearn: false);
        final freshRatio = freshCompressor.estimateCompressionRatio(data);
        buf.writeln(
            '  Ratio without dict: ${(freshRatio * 100).toStringAsFixed(1)}%');
        buf.writeln(
            '  Improvement: ${((freshRatio - ratio) * 100).toStringAsFixed(1)}% saved by dictionary');

        // Shared dictionaries
        buf.writeln('\n--- Shared Dictionaries ---');
        final sharedDict = compressor.getSharedDictionary('users_box');
        sharedDict.addPattern('premium');
        sharedDict.addPattern('standard');
        buf.writeln(
            '  Created shared dict for "users_box": ${sharedDict.size} entries');

        // Serialize dictionary
        buf.writeln('\n--- Dictionary Serialization ---');
        final json = compressor.dictionary.toJson();
        buf.writeln('  JSON entries: ${(json['entries'] as List).length}');

        // Merge dictionaries
        buf.writeln('\n--- Merge Dictionaries ---');
        final other = CompressionDictionary(name: 'other');
        other.addPattern('department');
        other.addPattern('salary');
        compressor.dictionary.merge(other);
        buf.writeln('  After merge: ${compressor.dictionary.size} entries');

        return buf.toString();
      },
    );
  }
}
