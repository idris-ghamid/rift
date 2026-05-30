import 'dart:collection';

/// Read cache layer for Rift storage backend.
/// Supports LRU and LFU eviction strategies with optional TTL.
///
/// The [ReadCache] provides a high-performance caching layer that sits
/// between the application and the storage backend. It supports two
/// eviction strategies:
///
/// - **LRU (Least Recently Used)**: Evicts the entry that hasn't been
///   accessed for the longest time. Good for general-purpose caching
///   where recently accessed items are likely to be accessed again.
///
/// - **LFU (Least Frequently Used)**: Evicts the entry with the lowest
///   access frequency. Good for workloads where some items are accessed
///   much more frequently than others.
///
/// Both strategies support optional TTL (time-to-live) for entries.
///
/// Usage:
/// ```dart
/// final cache = ReadCache<String, User>(maxSize: 100, strategy: CacheStrategy.lru);
/// cache.put('user_1', user1, ttl: Duration(minutes: 30));
/// final user = cache.get('user_1');
/// print('Hit rate: ${(cache.hitRate * 100).toStringAsFixed(1)}%');
/// ```

/// The cache eviction strategy.
enum CacheStrategy {
  /// Evict the least recently accessed entry.
  lru,

  /// Evict the least frequently accessed entry.
  lfu,
}

/// Read cache with LRU and LFU eviction strategies and optional TTL.
class ReadCache<K, V> {
  /// Maximum number of entries the cache can hold.
  final int maxSize;

  /// The eviction strategy to use when the cache is full.
  final CacheStrategy strategy;

  final LinkedHashMap<K, _CacheEntry<V>> _lruCache = LinkedHashMap();
  final Map<K, _LFUEntry<V>> _lfuCache = {};
  final Map<K, DateTime> _expiry = {};
  Duration? _defaultTTL;

  int _hits = 0;
  int _misses = 0;

  /// Create a [ReadCache] with the given [maxSize] and [strategy].
  ///
  /// Optionally specify a [defaultTTL] that applies to all entries
  /// that don't provide their own TTL.
  ReadCache({
    required this.maxSize,
    this.strategy = CacheStrategy.lru,
    Duration? defaultTTL,
  }) : _defaultTTL = defaultTTL;

  /// Get the value associated with [key], or null if not found or expired.
  V? get(K key) {
    _evictExpired();
    if (strategy == CacheStrategy.lru) return _lruGet(key);
    return _lfuGet(key);
  }

  /// Put a value in the cache at [key].
  ///
  /// If an entry already exists for [key], it is updated.
  /// If the cache is at capacity, the appropriate entry is evicted
  /// based on the [strategy].
  ///
  /// Optionally specify a [ttl] (time-to-live) for this entry.
  /// If not provided, the cache's [defaultTTL] is used (if set).
  void put(K key, V value, {Duration? ttl}) {
    _evictExpired();
    if (strategy == CacheStrategy.lru) {
      _lruPut(key, value);
    } else {
      _lfuPut(key, value);
    }

    // Handle TTL
    final effectiveTTL = ttl ?? _defaultTTL;
    if (effectiveTTL != null) {
      _expiry[key] = DateTime.now().add(effectiveTTL);
    } else {
      _expiry.remove(key);
    }
  }

  /// Remove the entry associated with [key].
  void remove(K key) {
    _lruCache.remove(key);
    _lfuCache.remove(key);
    _expiry.remove(key);
  }

  /// Clear all entries from the cache.
  void clear() {
    _lruCache.clear();
    _lfuCache.clear();
    _expiry.clear();
  }

  /// Check if the cache contains an entry for [key].
  ///
  /// Returns false if the entry exists but is expired.
  bool containsKey(K key) {
    _evictExpired();
    if (strategy == CacheStrategy.lru) return _lruCache.containsKey(key);
    return _lfuCache.containsKey(key);
  }

  /// The current number of entries in the cache.
  int get size =>
      strategy == CacheStrategy.lru ? _lruCache.length : _lfuCache.length;

  /// The cache hit rate as a value between 0.0 and 1.0.
  double get hitRate => (_hits + _misses) > 0 ? _hits / (_hits + _misses) : 0;

  /// Get the current cache statistics.
  CacheStats get stats => CacheStats(_hits, _misses, size, maxSize);

  /// Update the default TTL for future entries.
  set defaultTTL(Duration? ttl) => _defaultTTL = ttl;

  /// Get the current default TTL.
  Duration? get defaultTTL => _defaultTTL;

  // --- LRU Implementation ---

  V? _lruGet(K key) {
    final entry = _lruCache[key];
    if (entry == null) {
      _misses++;
      return null;
    }

    // Check if expired
    if (_isExpired(key)) {
      _lruCache.remove(key);
      _expiry.remove(key);
      _misses++;
      return null;
    }

    // Move to end for LRU (most recently used at the end)
    _lruCache.remove(key);
    _lruCache[key] = _CacheEntry(entry.value, DateTime.now());
    _hits++;
    return entry.value;
  }

  void _lruPut(K key, V value) {
    if (_lruCache.containsKey(key)) {
      // Update existing entry - remove and re-add to move to end
      _lruCache.remove(key);
      _lruCache[key] = _CacheEntry(value, DateTime.now());
    } else {
      // Evict least recently used if over capacity
      if (_lruCache.length >= maxSize) {
        final lruKey = _lruCache.keys.first;
        _lruCache.remove(lruKey);
        _expiry.remove(lruKey);
      }
      _lruCache[key] = _CacheEntry(value, DateTime.now());
    }
  }

  // --- LFU Implementation ---

  V? _lfuGet(K key) {
    final entry = _lfuCache[key];
    if (entry == null) {
      _misses++;
      return null;
    }

    // Check if expired
    if (_isExpired(key)) {
      _lfuCache.remove(key);
      _expiry.remove(key);
      _misses++;
      return null;
    }

    // Increment frequency
    entry.frequency++;
    _hits++;
    return entry.value;
  }

  void _lfuPut(K key, V value) {
    if (_lfuCache.containsKey(key)) {
      // Update existing entry
      final existing = _lfuCache[key]!;
      _lfuCache[key] = _LFUEntry(value, existing.frequency + 1, DateTime.now());
    } else {
      // Evict least frequently used if over capacity
      if (_lfuCache.length >= maxSize) {
        K? lfuKey;
        int minFreq = double.maxFinite.toInt();
        DateTime oldestTime = DateTime.now();

        for (final e in _lfuCache.entries) {
          if (e.value.frequency < minFreq ||
              (e.value.frequency == minFreq &&
                  e.value.insertedAt.isBefore(oldestTime))) {
            minFreq = e.value.frequency;
            oldestTime = e.value.insertedAt;
            lfuKey = e.key;
          }
        }

        if (lfuKey != null) {
          _lfuCache.remove(lfuKey);
          _expiry.remove(lfuKey);
        }
      }
      _lfuCache[key] = _LFUEntry(value, 1, DateTime.now());
    }
  }

  // --- Expiry ---

  bool _isExpired(K key) {
    final expiry = _expiry[key];
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry);
  }

  void _evictExpired() {
    final now = DateTime.now();
    final expiredKeys = <K>[];
    for (final entry in _expiry.entries) {
      if (now.isAfter(entry.value)) {
        expiredKeys.add(entry.key);
      }
    }
    for (final key in expiredKeys) {
      _lruCache.remove(key);
      _lfuCache.remove(key);
      _expiry.remove(key);
    }
  }

  /// Get all keys currently in the cache (non-expired).
  List<K> get keys {
    _evictExpired();
    if (strategy == CacheStrategy.lru) return _lruCache.keys.toList();
    return _lfuCache.keys.toList();
  }

  /// Get all values currently in the cache (non-expired).
  List<V> get values {
    _evictExpired();
    if (strategy == CacheStrategy.lru) {
      return _lruCache.values.map((e) => e.value).toList();
    }
    return _lfuCache.values.map((e) => e.value).toList();
  }

  /// Reset hit/miss counters while preserving cached entries.
  void resetStats() {
    _hits = 0;
    _misses = 0;
  }

  /// Get the remaining TTL for a key, or null if no TTL or doesn't exist.
  Duration? getRemainingTTL(K key) {
    final expiry = _expiry[key];
    if (expiry == null) return null;
    final remaining = expiry.difference(DateTime.now());
    if (remaining.isNegative) return Duration.zero;
    return remaining;
  }
}

/// Statistics about cache performance and utilization.
class CacheStats {
  /// The number of cache hits.
  final int hits;

  /// The number of cache misses.
  final int misses;

  /// The current number of entries in the cache.
  final int currentSize;

  /// The maximum number of entries the cache can hold.
  final int maxSize;

  /// The cache hit rate as a value between 0.0 and 1.0.
  double get hitRate => (hits + misses) > 0 ? hits / (hits + misses) : 0;

  /// The cache utilization as a value between 0.0 and 1.0.
  double get utilization => maxSize > 0 ? currentSize / maxSize : 0;

  /// Create a [CacheStats] instance.
  CacheStats(this.hits, this.misses, this.currentSize, this.maxSize);

  @override
  String toString() =>
      'CacheStats(hits: $hits, misses: $misses, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%, '
      'size: $currentSize/$maxSize, utilization: ${(utilization * 100).toStringAsFixed(1)}%)';
}

class _CacheEntry<V> {
  final V value;
  final DateTime insertedAt;

  _CacheEntry(this.value, this.insertedAt);
}

class _LFUEntry<V> {
  final V value;
  int frequency;
  final DateTime insertedAt;

  _LFUEntry(this.value, this.frequency, this.insertedAt);
}
