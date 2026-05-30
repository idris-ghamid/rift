import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class LazyStrategyDemoPage extends StatelessWidget {
  const LazyStrategyDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Lazy Loading Strategies',
      description: 'Eager, lazy, on-demand, and scheduled loading strategies',
      codeExample:
          "final loader = LazyLoader<String, Map>(\n  strategy: LazyStrategy.lazy,\n  fetcher: (key) => box.get(key),\n);\nfinal value = await loader.get('user_1');",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Lazy Loading Strategies Demo ===\n');

        final fetchCounts = <String, int>{};
        Future<Map?> fetcher(String key) async {
          fetchCounts[key] = (fetchCounts[key] ?? 0) + 1;
          await Future.delayed(const Duration(milliseconds: 10));
          return {'key': key, 'data': 'value_for_$key'};
        }

        // Eager strategy
        buf.writeln('--- Eager Strategy ---');
        final eagerLoader = LazyLoader<String, Map?>(
          strategy: LazyStrategy.eager,
          fetcher: fetcher,
        );
        await eagerLoader.get('user_1');
        await eagerLoader.get('user_2');
        buf.writeln('  Fetched user_1, user_2');
        buf.writeln('  user_1 loaded: ${eagerLoader.isLoaded('user_1')}');
        buf.writeln('  user_3 loaded: ${eagerLoader.isLoaded('user_3')}');
        buf.writeln('  Cache size: ${eagerLoader.cacheSize}');

        // Lazy strategy
        buf.writeln('\n--- Lazy Strategy ---');
        final lazyLoader = LazyLoader<String, Map?>(
          strategy: LazyStrategy.lazy,
          fetcher: fetcher,
        );
        buf.writeln('  user_1 loaded: ${lazyLoader.isLoaded('user_1')}');
        final val1 = await lazyLoader.get('user_1');
        buf.writeln('  After get: $val1');
        buf.writeln('  user_1 loaded: ${lazyLoader.isLoaded('user_1')}');
        buf.writeln(
            '  Second get (cached): ${lazyLoader.getIfLoaded('user_1')}');

        // On-demand strategy
        buf.writeln('\n--- On-Demand Strategy ---');
        final onDemandLoader = LazyLoader<String, Map?>(
          strategy: LazyStrategy.onDemand,
          fetcher: fetcher,
        );
        final val2 = await onDemandLoader.get('user_5');
        buf.writeln('  Fetched on demand: $val2');
        buf.writeln('  Loaded count: ${onDemandLoader.loadedCount}');

        // Prefetch
        buf.writeln('\n--- Prefetch ---');
        await lazyLoader.prefetch(['user_3', 'user_4', 'user_5']);
        buf.writeln('  Prefetched 3 keys');
        buf.writeln('  Cache size: ${lazyLoader.cacheSize}');
        buf.writeln('  Loaded count: ${lazyLoader.loadedCount}');

        // Batch get
        buf.writeln('\n--- Batch Get ---');
        final batch = await lazyLoader.batchGet(['user_1', 'user_3']);
        buf.writeln('  Batch result keys: ${batch.keys.toList()}');

        // TTL and expiry
        buf.writeln('\n--- TTL and Expiry ---');
        final ttlLoader = LazyLoader<String, Map?>(
          strategy: LazyStrategy.lazy,
          fetcher: fetcher,
          ttl: const Duration(milliseconds: 50),
        );
        await ttlLoader.get('temp_key');
        buf.writeln('  temp_key loaded: ${ttlLoader.isLoaded('temp_key')}');
        await Future.delayed(const Duration(milliseconds: 60));
        buf.writeln(
            '  After 60ms: expired=${ttlLoader.isLoaded('temp_key') == false}');
        await ttlLoader.get('temp_key'); // will re-fetch
        buf.writeln('  Re-fetched: ${ttlLoader.isLoaded('temp_key')}');

        // BatchLoader
        buf.writeln('\n--- BatchLoader ---');
        final batchLoader = BatchLoader<String, Map?>(
          batchFetcher: (keys) async {
            final results = <String, Map?>{};
            for (final key in keys) {
              results[key] = {'key': key, 'batched': true};
            }
            return results;
          },
          maxBatchSize: 10,
          maxWait: const Duration(milliseconds: 5),
        );
        final b1 = batchLoader.load('item_a');
        final b2 = batchLoader.load('item_b');
        final b3 = batchLoader.load('item_c');
        await Future.delayed(const Duration(milliseconds: 20));
        buf.writeln(
            '  Batch loaded: a=${(await b1)?['key']}, b=${(await b2)?['key']}, c=${(await b3)?['key']}');

        // PrefetchStrategy
        buf.writeln('\n--- PrefetchStrategy ---');
        final prefetch = PrefetchStrategy<String, Map?>(
          relatedKeys: (key) => ['related_${key}_1', 'related_${key}_2'],
          loader: lazyLoader,
          enabled: true,
          maxPrefetch: 5,
        );
        await prefetch.prefetch('user_1');
        buf.writeln('  Prefetched related keys for user_1');
        buf.writeln('  Cache size: ${lazyLoader.cacheSize}');

        // Total fetches
        buf.writeln('\n--- Total Fetch Counts ---');
        for (final entry in fetchCounts.entries) {
          buf.writeln('  ${entry.key}: ${entry.value} fetch(es)');
        }

        eagerLoader.dispose();
        lazyLoader.dispose();
        onDemandLoader.dispose();
        ttlLoader.dispose();
        batchLoader.dispose();

        return buf.toString();
      },
    );
  }
}
