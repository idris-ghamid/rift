import 'package:rift/src/box/box_base.dart';
import 'package:rift/src/box/lazy_box.dart';
import 'package:rift/src/cache/lru_cache.dart';

/// A [LazyBox] wrapper that adds an LRU caching layer.
///
/// Combines the memory efficiency of [LazyBox] (values are not kept in
/// memory) with the speed of eagerly-loaded boxes for frequently accessed
/// items. Hot items are kept in an LRU cache, avoiding repeated disk reads.
///
/// Usage:
/// ```dart
/// final lazyBox = await Rift.openLazyBox('largeData');
/// final cachedBox = CachedLazyBox(lazyBox, cacheSize: 200);
/// final value1 = await cachedBox.get('key1');
/// final value2 = await cachedBox.get('key1'); // Served from cache
/// print('Hit rate: ${(cachedBox.cacheHitRate * 100).toStringAsFixed(1)}%');
/// ```
class CachedLazyBox<E> implements LazyBox<E> {
  final LazyBox<E> _delegate;
  final LRUCache<String, E> _cache;

  /// Creates a new [CachedLazyBox] wrapping the delegate with the
  /// specified [cacheSize] (default: 100 entries).
  CachedLazyBox(this._delegate, {int cacheSize = 100})
    : _cache = LRUCache<String, E>(maxSize: cacheSize);

  /// The underlying LRU cache instance (for advanced usage).
  LRUCache<String, E> get cache => _cache;

  @override
  String get name => _delegate.name;

  @override
  bool get isOpen => _delegate.isOpen;

  @override
  String? get path => _delegate.path;

  @override
  bool get lazy => true;

  @override
  Iterable<dynamic> get keys => _delegate.keys;

  @override
  int get length => _delegate.length;

  @override
  bool get isEmpty => _delegate.isEmpty;

  @override
  bool get isNotEmpty => _delegate.isNotEmpty;

  /// The current number of entries in the cache.
  int get cacheSize => _cache.size;

  /// The cache hit rate as a value between 0.0 and 1.0.
  double get cacheHitRate => _cache.hitRate;

  /// The number of cache hits.
  int get cacheHits => _cache.hits;

  /// The number of cache misses.
  int get cacheMisses => _cache.misses;

  @override
  Future<E?> get(dynamic key, {E? defaultValue}) async {
    final stringKey = key.toString();

    final cached = _cache.get(stringKey);
    if (cached != null) return cached;

    final value = await _delegate.get(key, defaultValue: defaultValue);
    if (value != null) _cache.put(stringKey, value);
    return value;
  }

  @override
  Future<E?> getAt(int index) async {
    final key = _delegate.keyAt(index);
    return await get(key);
  }

  @override
  dynamic keyAt(int index) => _delegate.keyAt(index);

  @override
  Stream<BoxEvent> watch({dynamic key}) => _delegate.watch(key: key);

  @override
  bool containsKey(dynamic key) => _delegate.containsKey(key);

  @override
  Future<void> put(dynamic key, E value) async {
    await _delegate.put(key, value);
    _cache.put(key.toString(), value);
  }

  @override
  Future<void> putAt(int index, E value) async {
    await _delegate.putAt(index, value);
    final key = _delegate.keyAt(index);
    _cache.put(key.toString(), value);
  }

  @override
  Future<void> putAll(Map<dynamic, E> entries) async {
    await _delegate.putAll(entries);
    for (final entry in entries.entries) {
      _cache.put(entry.key.toString(), entry.value);
    }
  }

  @override
  Future<int> add(E value) async {
    final key = await _delegate.add(value);
    _cache.put(key.toString(), value);
    return key;
  }

  @override
  Future<Iterable<int>> addAll(Iterable<E> values) async {
    final keys = await _delegate.addAll(values);
    final keyList = keys.toList();
    final valueList = values.toList();
    for (int i = 0; i < keyList.length && i < valueList.length; i++) {
      _cache.put(keyList[i].toString(), valueList[i]);
    }
    return keys;
  }

  @override
  Future<void> delete(dynamic key) async {
    await _delegate.delete(key);
    _cache.remove(key.toString());
  }

  @override
  Future<void> deleteAt(int index) async {
    final key = _delegate.keyAt(index);
    await _delegate.deleteAt(index);
    _cache.remove(key.toString());
  }

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) async {
    await _delegate.deleteAll(keys);
    for (final key in keys) {
      _cache.remove(key.toString());
    }
  }

  @override
  Future<void> compact() => _delegate.compact();

  @override
  Future<int> clear() async {
    final count = await _delegate.clear();
    _cache.clear();
    return count;
  }

  @override
  Future<void> close() async {
    _cache.clear();
    await _delegate.close();
  }

  @override
  Future<void> deleteFromDisk() async {
    _cache.clear();
    await _delegate.deleteFromDisk();
  }

  @override
  Future<void> flush() => _delegate.flush();

  /// Invalidates a specific key from the cache without affecting the box.
  void invalidateCacheKey(dynamic key) {
    _cache.remove(key.toString());
  }

  /// Invalidates the entire cache without affecting the box.
  void invalidateCache() {
    _cache.clear();
  }

  /// Preloads specific keys into the cache.
  Future<void> preload(Iterable<dynamic> keys) async {
    for (final key in keys) {
      if (!_cache.containsKey(key.toString())) {
        final value = await _delegate.get(key);
        if (value != null) _cache.put(key.toString(), value);
      }
    }
  }

  /// Returns cache statistics for monitoring.
  Map<String, dynamic> getCacheStats() => _cache.getStats();
}
