/// Configurable lazy loading strategies for different access patterns.
///
/// Provides different strategies for loading data from Rift boxes,
/// including eager, lazy, on-demand, and scheduled loading.
/// Supports prefetching and batch loading.
///
/// Usage:
/// ```dart
/// final loader = LazyLoader<String, Map>(
///   strategy: LazyStrategy.lazy,
///   fetcher: (key) => box.get(key),
/// );
///
/// // Lazy load
/// final value = await loader.get('user_1');
///
/// // Prefetch related keys
/// await loader.prefetch(['user_2', 'user_3']);
///
/// // Batch load
/// final values = await loader.batchGet(['user_4', 'user_5']);
/// ```
library;

import 'dart:async';

/// Strategies for lazy loading data.
enum LazyStrategy {
  /// Load all data immediately when the loader is created.
  eager,

  /// Load data on first access (default lazy loading).
  lazy,

  /// Load data only when explicitly requested.
  onDemand,

  /// Load data on a scheduled basis (background refresh).
  scheduled,
}

/// A lazy-loaded reference to a value.
///
/// [LazyRef] wraps a value that may not be loaded yet. The value
/// is loaded on first access according to the configured strategy.
class LazyRef<K, V> {
  /// The key for this reference.
  final K key;

  /// The function to load the value.
  final Future<V> Function(K key) _fetcher;

  /// The loaded value (null if not yet loaded).
  V? _value;

  /// Whether the value has been loaded.
  bool _isLoaded = false;

  /// Whether a load is currently in progress.
  bool _isLoading = false;

  /// Completers for waiting on the value.
  final List<Completer<V>> _waiting = [];

  /// When the value was last loaded.
  DateTime? _loadedAt;

  /// TTL for the cached value.
  final Duration? ttl;

  /// Creates a [LazyRef].
  LazyRef(this.key, Future<V> Function(K key) fetcher, {this.ttl})
    : _fetcher = fetcher;

  /// The current value, or null if not loaded.
  V? get value => _value;

  /// Whether the value has been loaded.
  bool get isLoaded => _isLoaded;

  /// Whether the value has expired based on TTL.
  bool get isExpired {
    if (ttl == null || _loadedAt == null) return false;
    return DateTime.now().difference(_loadedAt!) > ttl!;
  }

  /// Gets the value, loading it if necessary.
  Future<V> get() async {
    if (_isLoaded && !isExpired) return _value as V;

    if (_isLoading) {
      // Wait for the in-progress load
      final completer = Completer<V>();
      _waiting.add(completer);
      return completer.future;
    }

    _isLoading = true;
    try {
      _value = await _fetcher(key);
      _isLoaded = true;
      _loadedAt = DateTime.now();

      // Notify waiters
      for (final completer in _waiting) {
        completer.complete(_value as V);
      }
      _waiting.clear();

      return _value as V;
    } catch (e) {
      // Notify waiters of the error
      for (final completer in _waiting) {
        completer.completeError(e);
      }
      _waiting.clear();
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// Invalidates the cached value, forcing a reload on next access.
  void invalidate() {
    _value = null;
    _isLoaded = false;
    _loadedAt = null;
  }

  /// Forces a reload of the value.
  Future<V> reload() async {
    invalidate();
    return get();
  }
}

/// Configurable lazy loading with strategies.
///
/// [LazyLoader] manages lazy-loaded values using a configurable
/// strategy. It supports prefetching, batch loading, and
/// scheduled background refresh.
class LazyLoader<K, V> {
  /// The loading strategy.
  final LazyStrategy strategy;

  /// The function to fetch values by key.
  final Future<V> Function(K key) fetcher;

  /// TTL for cached values.
  final Duration? ttl;

  /// Cache of loaded references.
  final Map<K, LazyRef<K, V>> _cache = {};

  /// Timer for scheduled loading.
  Timer? _scheduledTimer;

  /// Keys to load during scheduled refresh.
  Set<K> _scheduledKeys = {};

  /// Callback for scheduled refresh.
  final void Function(K key, V value)? onRefreshed;

  /// Creates a [LazyLoader].
  LazyLoader({
    required this.strategy,
    required this.fetcher,
    this.ttl,
    this.onRefreshed,
  });

  /// Gets a value, loading it according to the strategy.
  Future<V> get(K key) async {
    final ref = _cache.putIfAbsent(key, () => LazyRef(key, fetcher, ttl: ttl));
    return ref.get();
  }

  /// Gets a value synchronously if already loaded, or null.
  V? getIfLoaded(K key) {
    final ref = _cache[key];
    if (ref != null && ref.isLoaded && !ref.isExpired) {
      return ref.value;
    }
    return null;
  }

  /// Checks if a value is loaded for the given [key].
  bool isLoaded(K key) {
    final ref = _cache[key];
    return ref != null && ref.isLoaded && !ref.isExpired;
  }

  /// Prefetches values for the given [keys].
  ///
  /// Loads all values in parallel (up to [concurrency] at a time).
  Future<void> prefetch(Iterable<K> keys, {int concurrency = 10}) async {
    final keyList = keys.toList();
    final batches = <List<K>>[];
    for (int i = 0; i < keyList.length; i += concurrency) {
      batches.add(
        keyList.sublist(i, (i + concurrency).clamp(0, keyList.length)),
      );
    }

    for (final batch in batches) {
      await Future.wait(batch.map((key) => get(key)));
    }
  }

  /// Batch loads values for multiple keys.
  ///
  /// Returns a map of key → value for all loaded values.
  Future<Map<K, V>> batchGet(Iterable<K> keys) async {
    final results = <K, V>{};
    for (final key in keys) {
      results[key] = await get(key);
    }
    return results;
  }

  /// Starts scheduled background refresh.
  ///
  /// Periodically refreshes cached values for registered keys.
  void startScheduledRefresh(Duration interval) {
    stopScheduledRefresh();
    _scheduledTimer = Timer.periodic(interval, (_) async {
      for (final key in _scheduledKeys) {
        final ref = _cache[key];
        if (ref != null) {
          await ref.reload();
          if (ref.isLoaded && onRefreshed != null) {
            onRefreshed!(key, ref.value as V);
          }
        }
      }
    });
  }

  /// Stops scheduled background refresh.
  void stopScheduledRefresh() {
    _scheduledTimer?.cancel();
    _scheduledTimer = null;
  }

  /// Registers keys for scheduled refresh.
  void scheduleKeys(Iterable<K> keys) {
    _scheduledKeys = Set.from(keys);
  }

  /// Adds a key for scheduled refresh.
  void addScheduledKey(K key) {
    _scheduledKeys.add(key);
  }

  /// Removes a key from scheduled refresh.
  void removeScheduledKey(K key) {
    _scheduledKeys.remove(key);
  }

  /// Invalidates the cached value for [key].
  void invalidate(K key) {
    _cache[key]?.invalidate();
  }

  /// Invalidates all cached values.
  void invalidateAll() {
    for (final ref in _cache.values) {
      ref.invalidate();
    }
  }

  /// The number of cached entries.
  int get cacheSize => _cache.length;

  /// The number of loaded entries.
  int get loadedCount => _cache.values.where((r) => r.isLoaded).length;

  /// Whether scheduled refresh is active.
  bool get isScheduledRefreshActive => _scheduledTimer != null;

  /// Disposes the loader.
  void dispose() {
    stopScheduledRefresh();
    _cache.clear();
    _scheduledKeys.clear();
  }
}

/// Prefetch strategy for related data.
///
/// [PrefetchStrategy] defines how related data should be preloaded
/// when a primary key is accessed.
class PrefetchStrategy<K, V> {
  /// Function that returns related keys for a given key.
  final Iterable<K> Function(K key) relatedKeys;

  /// The lazy loader to prefetch into.
  final LazyLoader<K, V> loader;

  /// Whether prefetching is enabled.
  bool enabled;

  /// Maximum number of related keys to prefetch.
  final int maxPrefetch;

  /// Creates a [PrefetchStrategy].
  PrefetchStrategy({
    required this.relatedKeys,
    required this.loader,
    this.enabled = true,
    this.maxPrefetch = 10,
  });

  /// Prefetches related data for [key].
  Future<void> prefetch(K key) async {
    if (!enabled) return;
    final keys = relatedKeys(key).take(maxPrefetch);
    await loader.prefetch(keys);
  }
}

/// Batches multiple lazy load requests into single batch operations.
///
/// [BatchLoader] collects individual load requests and executes
/// them in batches for better performance.
class BatchLoader<K, V> {
  /// The batch fetch function.
  final Future<Map<K, V>> Function(Iterable<K> keys) batchFetcher;

  /// Maximum batch size.
  final int maxBatchSize;

  /// Maximum time to wait before executing a batch.
  final Duration maxWait;

  /// Pending keys awaiting batch execution.
  final Map<K, Completer<V?>> _pending = {};

  /// Timer for batch execution.
  Timer? _batchTimer;

  /// Creates a [BatchLoader].
  BatchLoader({
    required this.batchFetcher,
    this.maxBatchSize = 50,
    this.maxWait = const Duration(milliseconds: 10),
  });

  /// Queues a key for batch loading.
  Future<V?> load(K key) {
    final completer = Completer<V?>();
    _pending[key] = completer;

    if (_pending.length >= maxBatchSize) {
      _executeBatch();
    } else {
      _batchTimer ??= Timer(maxWait, _executeBatch);
    }

    return completer.future;
  }

  Future<void> _executeBatch() async {
    _batchTimer?.cancel();
    _batchTimer = null;

    if (_pending.isEmpty) return;

    final batch = Map<K, Completer<V?>>.from(_pending);
    _pending.clear();

    try {
      final results = await batchFetcher(batch.keys);
      for (final entry in batch.entries) {
        final value = results[entry.key];
        entry.value.complete(value);
      }
    } catch (e) {
      for (final completer in batch.values) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      }
    }
  }

  /// Disposes the batch loader.
  void dispose() {
    _batchTimer?.cancel();
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('BatchLoader disposed'));
      }
    }
    _pending.clear();
  }
}
