import 'dart:collection';

/// A cache entry that wraps a value with optional TTL (time-to-live).
class _CacheEntry<V> {
  V value;
  final int? expiresAt;
  DateTime lastAccessed;

  _CacheEntry(this.value, {this.expiresAt}) : lastAccessed = DateTime.now();

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().millisecondsSinceEpoch >= expiresAt!;
  }
}

/// LRU (Least Recently Used) cache for Rift lazy loading.
///
/// Keeps frequently accessed items in memory while evicting least recently
/// used ones when the cache is full. Supports optional TTL for entries.
///
/// Usage:
/// ```dart
/// final cache = LRUCache<String, User>(maxSize: 100);
/// cache.put('user_1', user1);
/// cache.put('user_2', user2, ttl: Duration(minutes: 30));
/// final user = cache.get('user_1');
/// print('Hit rate: ${(cache.hitRate * 100).toStringAsFixed(1)}%');
/// cache.evictExpired();
/// ```
class LRUCache<K, V> {
  /// Maximum number of entries the cache can hold.
  final int maxSize;

  final LinkedHashMap<K, _CacheEntry<V>> _cache = LinkedHashMap();
  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;

  /// Creates a new LRU cache with the given [maxSize].
  LRUCache({required this.maxSize}) {
    if (maxSize < 1) {
      throw ArgumentError('maxSize must be at least 1, got $maxSize');
    }
  }

  /// Retrieves the value associated with [key], or null if not found.
  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) {
      _misses++;
      return null;
    }

    if (entry.isExpired) {
      _cache.remove(key);
      _misses++;
      return null;
    }

    // Move to most recently used position
    _cache.remove(key);
    entry.lastAccessed = DateTime.now();
    _cache[key] = entry;
    _hits++;
    return entry.value;
  }

  /// Adds or updates an entry in the cache.
  ///
  /// If the cache is at capacity and the key is not already present,
  /// the least recently used entry is evicted first.
  void put(K key, V value, {Duration? ttl}) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first);
      _evictions++;
    }

    final expiresAt = ttl != null
        ? DateTime.now().millisecondsSinceEpoch + ttl.inMilliseconds
        : null;

    _cache[key] = _CacheEntry(value, expiresAt: expiresAt);
  }

  /// Removes the entry associated with [key] from the cache.
  bool remove(K key) => _cache.remove(key) != null;

  /// Clears all entries from the cache.
  void clear() => _cache.clear();

  /// The current number of entries in the cache.
  int get size => _cache.length;

  /// Whether the cache is empty.
  bool get isEmpty => _cache.isEmpty;

  /// Whether the cache is at capacity.
  bool get isFull => _cache.length >= maxSize;

  /// The cache hit rate as a value between 0.0 and 1.0.
  double get hitRate {
    final total = _hits + _misses;
    return total > 0 ? _hits / total : 0.0;
  }

  /// The total number of cache hits.
  int get hits => _hits;

  /// The total number of cache misses.
  int get misses => _misses;

  /// The total number of entries evicted due to capacity.
  int get evictions => _evictions;

  /// Whether the cache contains an entry for [key].
  bool containsKey(K key) => _cache.containsKey(key);

  /// All keys in LRU order (least recently used first).
  List<K> get keys => _cache.keys.toList();

  /// All values in LRU order (least recently used first).
  List<V> get values => _cache.values.map((e) => e.value).toList();

  /// Removes all expired entries from the cache.
  int evictExpired() {
    final expiredKeys = <K>[];
    for (final entry in _cache.entries) {
      if (entry.value.isExpired) expiredKeys.add(entry.key);
    }
    for (final key in expiredKeys) {
      _cache.remove(key);
    }
    return expiredKeys.length;
  }

  /// Updates the value of an existing entry without changing LRU order.
  bool updateIfPresent(K key, V value) {
    final entry = _cache[key];
    if (entry == null) return false;
    entry.value = value;
    return true;
  }

  /// Gets the value for [key] without affecting LRU order or statistics.
  V? peek(K key) {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) return null;
    return entry.value;
  }

  /// Gets the remaining TTL for an entry, or null if no TTL or doesn't exist.
  Duration? getRemainingTTL(K key) {
    final entry = _cache[key];
    if (entry == null || entry.expiresAt == null) return null;
    final remaining = entry.expiresAt! - DateTime.now().millisecondsSinceEpoch;
    if (remaining <= 0) return Duration.zero;
    return Duration(milliseconds: remaining);
  }

  /// Returns a summary of cache statistics for monitoring.
  Map<String, dynamic> getStats() {
    return {
      'size': size,
      'maxSize': maxSize,
      'hits': _hits,
      'misses': _misses,
      'hitRate': hitRate,
      'evictions': _evictions,
      'utilization': size / maxSize,
    };
  }

  /// Resets hit/miss/eviction counters while preserving cached entries.
  void resetStats() {
    _hits = 0;
    _misses = 0;
    _evictions = 0;
  }
}
