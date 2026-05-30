import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class AdaptiveCacheDemoPage extends StatelessWidget {
  const AdaptiveCacheDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Adaptive Caching',
      description: 'Adaptive cache that switches strategies based on hit rate',
      codeExample:
          "final cache = AdaptiveCache<String, Map>(maxSize: 100);\ncache.put('key', data);\nfinal val = cache.get('key');\nprint(cache.stats.hitRate);",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Adaptive Caching Demo ===\n');

        final cache = AdaptiveCache<String, Map>(
          maxSize: 5,
          initialStrategy: AdaptiveCacheStrategy.lru,
          autoSwitch: true,
          evaluationInterval: 10,
        );

        buf.writeln('Cache: maxSize=5, initialStrategy=LRU, autoSwitch=true');

        // Warm up
        buf.writeln('\n--- Warm Up ---');
        cache.warmUp({
          'user_1': {'name': 'Alice'},
          'user_2': {'name': 'Bob'},
          'user_3': {'name': 'Charlie'},
          'user_4': {'name': 'Diana'},
          'user_5': {'name': 'Eve'},
        });
        buf.writeln('  Cache size: ${cache.size}');

        // Access pattern — LRU
        buf.writeln('\n--- Access Pattern (LRU) ---');
        cache.get('user_1');
        cache.get('user_2');
        buf.writeln('  Accessed user_1, user_2');
        final stats1 = cache.stats;
        buf.writeln('  Stats: $stats1');

        // Add beyond capacity → eviction
        buf.writeln('\n--- Eviction (add user_6) ---');
        cache.put('user_6', {'name': 'Frank'});
        buf.writeln('  Cache size: ${cache.size}');
        buf.writeln('  user_3 in cache: ${cache.containsKey('user_3')}');

        // Try different strategies
        buf.writeln('\n--- Strategy Switch: LFU ---');
        cache.setStrategy(AdaptiveCacheStrategy.lfu);
        // Access user_1 many times to increase frequency
        for (int i = 0; i < 5; i++) cache.get('user_1');
        cache.put('user_7', {'name': 'Grace'});
        buf.writeln('  Added user_7 (LFU evicts least frequent)');
        buf.writeln('  user_1 in cache: ${cache.containsKey('user_1')}');

        // ARC strategy
        buf.writeln('\n--- Strategy Switch: ARC ---');
        cache.setStrategy(AdaptiveCacheStrategy.arc);
        cache.put('user_8', {'name': 'Hank'});
        buf.writeln('  Added user_8 (ARC balances recency + frequency)');

        // FIFO strategy
        buf.writeln('\n--- Strategy Switch: FIFO ---');
        cache.setStrategy(AdaptiveCacheStrategy.fifo);
        cache.put('user_9', {'name': 'Ivy'});
        buf.writeln('  Added user_9 (FIFO evicts oldest inserted)');

        // Hit rates
        buf.writeln('\n--- Hit Rate ---');
        final stats = cache.stats;
        buf.writeln('  Lookups: ${stats.lookups}');
        buf.writeln('  Hits: ${stats.hits}');
        buf.writeln('  Misses: ${stats.misses}');
        buf.writeln('  Hit rate: ${(stats.hitRate * 100).toStringAsFixed(1)}%');
        buf.writeln('  Evictions: ${stats.evictions}');
        buf.writeln('  Current strategy: ${stats.strategy.name}');

        // Recommendation
        buf.writeln('\n--- Recommendation ---');
        buf.writeln('  ${cache.recommendation}');

        // getOrCompute
        buf.writeln('\n--- getOrCompute ---');
        final computed = cache.getOrCompute(
            'user_10', () => {'name': 'Computed', 'lazy': true});
        buf.writeln('  Computed: $computed');
        buf.writeln('  Cache size: ${cache.size}');

        cache.dispose();
        return buf.toString();
      },
    );
  }
}
