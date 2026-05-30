/// Adaptive caching that learns access patterns and switches strategies.
///
/// Smart cache that adapts its eviction strategy based on access
/// patterns. Supports LRU, LFU, ARC, and FIFO strategies, and
/// can auto-switch between them based on hit rate.
///
/// Usage:
/// ```dart
/// final cache = AdaptiveCache<String, Map>(maxSize: 100);
///
/// // Use like a regular cache
/// cache.put('key1', {'name': 'Idris'});
/// final value = cache.get('key1');
///
/// // Cache automatically adapts strategy
/// print(cache.currentStrategy); // LRU, LFU, ARC, or FIFO
/// print('Hit rate: ${cache.stats.hitRate}');
///
/// // Preload data
/// await cache.warmUp({'key1': data1, 'key2': data2});
/// ```
library;

import 'dart:collection';

/// Cache eviction strategies for [AdaptiveCache].
///
/// Note: This extends the basic cache strategy concept from the read cache
/// module with additional strategies (ARC, FIFO) for adaptive use cases.
enum AdaptiveCacheStrategy {
  /// Least Recently Used — evicts the least recently accessed item.
  lru,

  /// Least Frequently Used — evicts the least frequently accessed item.
  lfu,

  /// Adaptive Replacement Cache — balances recency and frequency.
  arc,

  /// First In First Out — evicts the oldest item.
  fifo,
}

/// Statistics about cache performance.
class AdaptiveCacheStats {
  /// Total number of cache lookups.
  final int lookups;

  /// Number of cache hits.
  final int hits;

  /// Number of cache misses.
  final int misses;

  /// Number of cache evictions.
  final int evictions;

  /// Current cache size.
  final int size;

  /// Maximum cache size.
  final int maxSize;

  /// The current strategy being used.
  final AdaptiveCacheStrategy strategy;

  /// Creates an [AdaptiveCacheStats].
  const AdaptiveCacheStats({
    required this.lookups,
    required this.hits,
    required this.misses,
    required this.evictions,
    required this.size,
    required this.maxSize,
    required this.strategy,
  });

  /// The hit rate (0.0 to 1.0).
  double get hitRate => lookups > 0 ? hits / lookups : 0;

  /// The miss rate (0.0 to 1.0).
  double get missRate => lookups > 0 ? misses / lookups : 0;

  /// The utilization ratio (0.0 to 1.0).
  double get utilization => maxSize > 0 ? size / maxSize : 0;

  @override
  String toString() =>
      'AdaptiveCacheStats(strategy: $strategy, hitRate: ${hitRate.toStringAsFixed(3)}, '
      'size: $size/$maxSize, evictions: $evictions)';
}

/// A cache entry with access metadata.
class _CacheEntry<V> {
  V value;
  int frequency;
  DateTime lastAccess;
  DateTime insertedAt;

  _CacheEntry(this.value)
    : frequency = 1,
      lastAccess = DateTime.now(),
      insertedAt = DateTime.now();

  void touch() {
    frequency++;
    lastAccess = DateTime.now();
  }
}

/// Smart cache that adapts its strategy based on access patterns.
///
/// [AdaptiveCache] monitors hit rates for different strategies and
/// automatically switches to the best-performing one. It supports
/// LRU, LFU, ARC, and FIFO strategies.
class AdaptiveCache<K, V> {
  /// Maximum number of items in the cache.
  final int maxSize;

  /// The current eviction strategy.
  AdaptiveCacheStrategy _strategy;

  /// Whether auto-switching is enabled.
  final bool autoSwitch;

  /// How often (in number of lookups) to evaluate strategy performance.
  final int evaluationInterval;

  /// The cache storage.
  final LinkedHashMap<K, _CacheEntry<V>> _cache = LinkedHashMap();

  /// Statistics counters.
  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;
  int _lookupsSinceEval = 0;

  /// Hit rates per strategy for comparison.
  final Map<AdaptiveCacheStrategy, List<double>> _strategyHitRates = {
    AdaptiveCacheStrategy.lru: [],
    AdaptiveCacheStrategy.lfu: [],
    AdaptiveCacheStrategy.arc: [],
    AdaptiveCacheStrategy.fifo: [],
  };

  /// Creates an [AdaptiveCache].
  AdaptiveCache({
    required this.maxSize,
    AdaptiveCacheStrategy initialStrategy = AdaptiveCacheStrategy.lru,
    this.autoSwitch = true,
    this.evaluationInterval = 100,
  }) : _strategy = initialStrategy;

  /// The current eviction strategy.
  AdaptiveCacheStrategy get currentStrategy => _strategy;

  /// Current cache size.
  int get size => _cache.length;

  /// Whether the cache is empty.
  bool get isEmpty => _cache.isEmpty;

  /// Whether the cache is not empty.
  bool get isNotEmpty => _cache.isNotEmpty;

  /// Gets the current cache statistics.
  AdaptiveCacheStats get stats => AdaptiveCacheStats(
    lookups: _hits + _misses,
    hits: _hits,
    misses: _misses,
    evictions: _evictions,
    size: _cache.length,
    maxSize: maxSize,
    strategy: _strategy,
  );

  /// Puts a value in the cache.
  ///
  /// If the cache is full, an item is evicted according to the
  /// current strategy. If [key] already exists, its value is
  /// updated and its access metadata is refreshed.
  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache[key]!.value = value;
      _cache[key]!.touch();
      return;
    }

    if (_cache.length >= maxSize) {
      _evict();
    }

    _cache[key] = _CacheEntry(value);
  }

  /// Gets a value from the cache.
  ///
  /// Returns null if the key is not in the cache.
  V? get(K key) {
    _lookupsSinceEval++;
    final entry = _cache[key];

    if (entry != null) {
      _hits++;
      entry.touch();

      // For LRU, move to end (most recently used)
      if (_strategy == AdaptiveCacheStrategy.lru) {
        _cache.remove(key);
        _cache[key] = entry;
      }

      _checkAutoSwitch();
      return entry.value;
    }

    _misses++;
    _checkAutoSwitch();
    return null;
  }

  /// Gets a value, computing it if not present.
  ///
  /// If [key] is not in the cache, [compute] is called to
  /// generate the value, which is then cached.
  V getOrCompute(K key, V Function() compute) {
    final cached = get(key);
    if (cached != null) return cached;

    final value = compute();
    put(key, value);
    return value;
  }

  /// Whether the cache contains [key].
  bool containsKey(K key) => _cache.containsKey(key);

  /// Removes a specific key from the cache.
  V? remove(K key) {
    final entry = _cache.remove(key);
    return entry?.value;
  }

  /// Clears the cache.
  void clear() {
    _cache.clear();
  }

  /// Pre-warms the cache with the given [entries].
  ///
  /// Adds all entries to the cache, evicting as needed.
  void warmUp(Map<K, V> entries) {
    for (final entry in entries.entries) {
      put(entry.key, entry.value);
    }
  }

  /// Asynchronously pre-warms the cache.
  ///
  /// [loader] is a function that returns the entries to warm up.
  Future<void> warmUpAsync(Future<Map<K, V>> Function() loader) async {
    final entries = await loader();
    warmUp(entries);
  }

  /// Prefetches a key by computing it if not already cached.
  Future<void> prefetch(K key, Future<V> Function() loader) async {
    if (containsKey(key)) return;
    final value = await loader();
    put(key, value);
  }

  /// Batch prefetch multiple keys.
  Future<void> prefetchAll(
    Iterable<K> keys,
    Future<V> Function(K key) loader,
  ) async {
    for (final key in keys) {
      await prefetch(key, () => loader(key));
    }
  }

  /// Forces a strategy change.
  void setStrategy(AdaptiveCacheStrategy strategy) {
    _strategy = strategy;
  }

  /// Gets all keys in the cache.
  Iterable<K> get keys => _cache.keys;

  /// Gets all values in the cache.
  Iterable<V> get values => _cache.values.map((e) => e.value);

  void _evict() {
    if (_cache.isEmpty) return;

    K? keyToEvict;

    switch (_strategy) {
      case AdaptiveCacheStrategy.lru:
        // Evict first entry (least recently used in LinkedHashMap)
        keyToEvict = _cache.keys.first;
        break;

      case AdaptiveCacheStrategy.lfu:
        // Evict entry with lowest frequency
        var minFreq = double.infinity;
        for (final entry in _cache.entries) {
          if (entry.value.frequency < minFreq) {
            minFreq = entry.value.frequency.toDouble();
            keyToEvict = entry.key;
          }
        }
        break;

      case AdaptiveCacheStrategy.arc:
        // Simplified ARC: blend of LRU and LFU
        // Score = recency_weight * recency_rank + frequency_weight * frequency_rank
        final entries = _cache.entries.toList();
        entries.sort(
          (a, b) => a.value.lastAccess.compareTo(b.value.lastAccess),
        );
        var minScore = double.infinity;
        for (int i = 0; i < entries.length; i++) {
          final recencyRank = i;
          final freqRank = entries
              .where((e) => e.value.frequency < entries[i].value.frequency)
              .length;
          final score = 0.5 * recencyRank + 0.5 * freqRank;
          if (score < minScore) {
            minScore = score;
            keyToEvict = entries[i].key;
          }
        }
        break;

      case AdaptiveCacheStrategy.fifo:
        // Evict oldest inserted entry
        var oldest = DateTime.now();
        for (final entry in _cache.entries) {
          if (entry.value.insertedAt.isBefore(oldest)) {
            oldest = entry.value.insertedAt;
            keyToEvict = entry.key;
          }
        }
        break;
    }

    if (keyToEvict != null) {
      _cache.remove(keyToEvict);
      _evictions++;
    }
  }

  void _checkAutoSwitch() {
    if (!autoSwitch) return;
    if (_lookupsSinceEval < evaluationInterval) return;

    _lookupsSinceEval = 0;

    final currentHitRate = stats.hitRate;
    _strategyHitRates[_strategy]!.add(currentHitRate);

    // Keep only recent history
    for (final rates in _strategyHitRates.values) {
      if (rates.length > 10) rates.removeAt(0);
    }

    // Find the best strategy
    AdaptiveCacheStrategy? bestStrategy;
    double bestAvgHitRate = currentHitRate;

    for (final entry in _strategyHitRates.entries) {
      if (entry.value.isEmpty) continue;
      final avgRate = entry.value.reduce((a, b) => a + b) / entry.value.length;
      if (avgRate > bestAvgHitRate + 0.05) {
        bestAvgHitRate = avgRate;
        bestStrategy = entry.key;
      }
    }

    if (bestStrategy != null && bestStrategy != _strategy) {
      _strategy = bestStrategy;
    }
  }

  /// Provides tuning recommendations based on current performance.
  String get recommendation {
    final hitRate = stats.hitRate;
    if (hitRate > 0.8) {
      return 'Cache performance is excellent. No changes needed.';
    } else if (hitRate > 0.5) {
      return 'Consider increasing cache size or switching to ${_strategy == AdaptiveCacheStrategy.lru ? 'LFU' : 'LRU'} strategy.';
    } else if (hitRate > 0.2) {
      return 'Low hit rate. Consider increasing maxSize, warming up the cache, or reviewing access patterns.';
    } else {
      return 'Very low hit rate. Cache may not be effective. Consider if caching is appropriate for this use case.';
    }
  }

  /// Disposes the cache.
  void dispose() {
    _cache.clear();
    for (final rates in _strategyHitRates.values) {
      rates.clear();
    }
  }
}
