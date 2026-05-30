import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class ReadCacheDemoPage extends StatelessWidget {
  const ReadCacheDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Read Cache',
      description: 'Read cache with LRU and LFU strategies and TTL support',
      codeExample:
          "final cache = ReadCache<String, User>(\n  maxSize: 100,\n  strategy: CacheStrategy.lru,\n  defaultTTL: Duration(minutes: 30),\n);\ncache.put('key', user, ttl: Duration(minutes: 10));\nfinal user = cache.get('key');\nprint('Hit rate: \${cache.stats.hitRate}');",
      runDemo: () async {
        final buf = StringBuffer();
        final strategyName = 'LRU';
        buf.writeln('=== Read Cache Demo ($strategyName) ===\n');

        // Create cache with selected strategy
        final cache = ReadCache<String, String>(
          maxSize: 5,
          strategy: CacheStrategy.lru,
          defaultTTL: const Duration(minutes: 30),
        );
        buf.writeln(
            'Cache: maxSize=5, strategy=$strategyName, defaultTTL=30min\n');

        // Fill cache
        buf.writeln('--- Adding 5 Items ---');
        cache.put('a', 'Apple');
        cache.put('b', 'Banana');
        cache.put('c', 'Cherry');
        cache.put('d', 'Date');
        cache.put('e', 'Elderberry');
        buf.writeln('  Items: ${cache.keys}');
        buf.writeln('  Size: ${cache.size}/5');

        // Access some items to affect ordering/frequency
        buf.writeln('\n--- Access Patterns ---');
        final c = cache.get('c');
        buf.writeln('  get("c") = $c');
        final a = cache.get('a');
        buf.writeln('  get("a") = $a');
        final c2 = cache.get('c');
        buf.writeln('  get("c") again = $c2');
        final a2 = cache.get('a');
        buf.writeln('  get("a") again = $a2');

        buf.writeln('  LRU: "a" and "c" moved to most-recently-used end');
        buf.writeln('  Order: ${cache.keys}');

        // Add 6th item → eviction
        buf.writeln('\n--- Adding 6th Item (Triggers Eviction) ---');
        cache.put('f', 'Fig');
        buf.writeln('  put("f", "Fig")');
        buf.writeln('  Items: ${cache.keys}');
        buf.writeln('  Size: ${cache.size}');

        buf.writeln('  LRU evicted "b" (least recently used)');

        // Hit/miss stats
        buf.writeln('\n--- Cache Statistics ---');
        final stats = cache.stats;
        buf.writeln('  ${cache.stats}');
        buf.writeln('  Hits: ${stats.hits}');
        buf.writeln('  Misses: ${stats.misses}');
        buf.writeln('  Hit rate: ${(stats.hitRate * 100).toStringAsFixed(1)}%');
        buf.writeln(
            '  Utilization: ${(stats.utilization * 100).toStringAsFixed(1)}%');

        // Miss example
        buf.writeln('\n--- Cache Miss ---');
        final missing = cache.get('b');
        buf.writeln('  get("b") = $missing (null = cache miss)');

        final stats2 = cache.stats;
        buf.writeln(
            '  Hit rate after miss: ${(stats2.hitRate * 100).toStringAsFixed(1)}%');

        // TTL support
        buf.writeln('\n--- TTL Support ---');
        cache.put('temp', 'Temporary', ttl: const Duration(seconds: 60));
        buf.writeln('  put("temp", "Temporary", ttl: 60s)');
        final remainingTTL = cache.getRemainingTTL('temp');
        buf.writeln('  Remaining TTL for "temp": ${remainingTTL?.inSeconds}s');
        buf.writeln('  Default TTL: ${cache.defaultTTL?.inMinutes}min');

        // Check containsKey
        buf.writeln('\n--- Contains Key ---');
        buf.writeln('  containsKey("a"): ${cache.containsKey("a")}');
        buf.writeln('  containsKey("z"): ${cache.containsKey("z")}');

        // Remove
        buf.writeln('\n--- Remove Entry ---');
        cache.remove('a');
        buf.writeln('  remove("a")');
        buf.writeln('  Size after remove: ${cache.size}');
        buf.writeln('  Items: ${cache.keys}');

        // Reset stats
        buf.writeln('\n--- Reset Stats ---');
        cache.resetStats();
        buf.writeln('  Stats after reset: ${cache.stats}');

        // Compare LRU vs LFU
        buf.writeln('\n--- LRU vs LFU Comparison ---');
        buf.writeln('  ┌──────────┬─────────────────────────────────────┐');
        buf.writeln('  │ Strategy │ Best For                            │');
        buf.writeln('  ├──────────┼─────────────────────────────────────┤');
        buf.writeln('  │ LRU      │ Recently accessed items likely again │');
        buf.writeln('  │ LFU      │ Some items accessed much more often  │');
        buf.writeln('  └──────────┴─────────────────────────────────────┘');

        buf.writeln('\n✅ Read cache demo complete');

        return buf.toString();
      },
    );
  }
}
