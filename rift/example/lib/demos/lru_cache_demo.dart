import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class LruCacheDemoPage extends StatelessWidget {
  const LruCacheDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'LRU Cache',
      description: 'LRU cache with hit rate stats and eviction',
      codeExample:
          "final cache = LRUCache<String, String>(maxSize: 100);\ncache.put('key', 'value', ttl: Duration(minutes: 30));\nfinal v = cache.get('key');\nprint('Hit rate: \${cache.hitRate}');",
      runDemo: () async {
        final cache = LRUCache<String, String>(maxSize: 5);
        final buf = StringBuffer();
        buf.writeln('=== LRU Cache Demo ===\n');
        buf.writeln('Cache maxSize: 5\n');

        // Fill cache
        buf.writeln('--- Adding 5 items ---');
        cache.put('a', 'Apple');
        cache.put('b', 'Banana');
        cache.put('c', 'Cherry');
        cache.put('d', 'Date');
        cache.put('e', 'Elderberry');
        buf.writeln('  Items: ${cache.keys}');
        buf.writeln('  Size: ${cache.size}, isFull: ${cache.isFull}');

        // Add 6th item → eviction
        buf.writeln('\n--- Adding 6th item (triggers eviction) ---');
        cache.put('f', 'Fig');
        buf.writeln('  Items: ${cache.keys}');
        buf.writeln('  Evictions: ${cache.evictions}');

        // Access patterns
        buf.writeln('\n--- Access "c" (moves to MRU) ---');
        final c = cache.get('c');
        buf.writeln('  Got: $c');
        buf.writeln('  Order: ${cache.keys}');

        // Add another → evicts next LRU
        buf.writeln('\n--- Adding "g" ---');
        cache.put('g', 'Grape');
        buf.writeln('  Items: ${cache.keys}');
        buf.writeln('  Evictions: ${cache.evictions}');

        // Hit/miss stats
        buf.writeln('\n--- Cache Stats ---');
        buf.writeln('  Hits: ${cache.hits}');
        buf.writeln('  Misses: ${cache.misses}');
        buf.writeln('  Hit rate: ${(cache.hitRate * 100).toStringAsFixed(1)}%');

        // Miss
        buf.writeln('\n--- Access "a" (should be evicted → miss) ---');
        final a = cache.get('a');
        buf.writeln('  Got: $a (null = cache miss)');
        buf.writeln('  Hit rate: ${(cache.hitRate * 100).toStringAsFixed(1)}%');

        // TTL
        buf.writeln('\n--- TTL Support ---');
        cache.put('temp', 'Temporary', ttl: const Duration(seconds: 30));
        buf.writeln('  Added "temp" with 30s TTL');
        buf.writeln('  Remaining TTL: ${cache.getRemainingTTL("temp")}');

        // Peek
        buf.writeln('\n--- Peek (no LRU update) ---');
        final peeked = cache.peek('c');
        buf.writeln('  Peek "c": $peeked');
        buf.writeln('  Order unchanged: ${cache.keys}');

        buf.writeln('\n--- Full Stats ---');
        buf.writeln('  ${cache.getStats()}');

        return buf.toString();
      },
    );
  }
}
