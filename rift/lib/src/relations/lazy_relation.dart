import 'package:rift/src/relations/relation.dart';
import 'package:rift/src/relations/relation_index.dart';

/// A lazy-loaded relation that only fetches data when accessed.
///
/// Uses a proxy/adapter pattern to defer loading of related data
/// until it is explicitly requested. This avoids unnecessary reads
/// from the target box when the relation data is never accessed.
///
/// The [LazyRelation] acts as a proxy that wraps the lookup logic.
/// It holds a reference to the [RelationIndex] for efficient lookups
/// and caches results after the first load.
///
/// Usage:
/// ```dart
/// final lazyRelation = relationManager.getLazyRelation('users', 'posts');
/// if (lazyRelation != null) {
///   // Data is only fetched when load() is called
///   final posts = await lazyRelation.load('user1');
///   print(posts); // [post1, post2, ...]
///
///   // Subsequent calls use the cached result
///   final postsAgain = await lazyRelation.load('user1');
///
///   // Invalidate cache when data changes
///   lazyRelation.invalidate('user1');
/// }
/// ```
class LazyRelation {
  /// The source box name.
  final String boxName;

  /// The relation configuration.
  final RelationConfig config;

  /// The relation index for lookups.
  final RelationIndex _relationIndex;

  /// Cache of loaded results: sourceKey → list of related keys/values.
  final Map<dynamic, List<dynamic>> _cache = {};

  /// Set of keys that have been loaded (for cache invalidation tracking).
  final Set<dynamic> _loadedKeys = {};

  /// Creates a new lazy relation.
  LazyRelation({
    required this.boxName,
    required this.config,
    required RelationIndex relationIndex,
  }) : _relationIndex = relationIndex;

  /// Loads the related data for the given source key.
  ///
  /// On the first call for a given [sourceKey], the data is fetched
  /// from the relation index. Subsequent calls return the cached result
  /// unless the cache has been invalidated.
  ///
  /// Returns a list of related entries (keys or values depending on
  /// the relation type and index state).
  Future<List<dynamic>> load(dynamic sourceKey) async {
    if (_loadedKeys.contains(sourceKey)) {
      return _cache[sourceKey] ?? [];
    }

    final related = _relationIndex.lookupRelated(
      boxName,
      sourceKey,
      config.field,
    );

    _cache[sourceKey] = related;
    _loadedKeys.add(sourceKey);

    return related;
  }

  /// Invalidates the cached result for the given source key.
  ///
  /// The next call to [load] will fetch fresh data from the relation index.
  void invalidate(dynamic sourceKey) {
    _cache.remove(sourceKey);
    _loadedKeys.remove(sourceKey);
  }

  /// Invalidates all cached results.
  ///
  /// Use this when a bulk operation may have changed multiple relations.
  void invalidateAll() {
    _cache.clear();
    _loadedKeys.clear();
  }

  /// Checks whether data has been loaded for the given source key.
  bool isLoaded(dynamic sourceKey) => _loadedKeys.contains(sourceKey);

  /// Gets the cached result for the given source key without loading.
  ///
  /// Returns null if the data has not been loaded yet.
  List<dynamic>? getCached(dynamic sourceKey) {
    if (!_loadedKeys.contains(sourceKey)) return null;
    return _cache[sourceKey];
  }

  /// Pre-loads the related data for the given source key.
  ///
  /// This is useful for batch pre-fetching of related data before
  /// it is actually needed, while still using the lazy-loading pattern.
  Future<void> preload(dynamic sourceKey) async {
    await load(sourceKey);
  }

  /// Pre-loads related data for multiple source keys.
  Future<void> preloadAll(Iterable<dynamic> sourceKeys) async {
    for (final key in sourceKeys) {
      await load(key);
    }
  }
}

/// A lazy relation adapter that wraps a [LazyRelation] and provides
/// a [noSuchMethod]-based proxy pattern for accessing related data.
///
/// This allows you to access related data as if it were a property
/// on the source object:
///
/// ```dart
/// // Instead of:
/// final posts = await relationManager.getRelated('user1', 'posts');
///
/// // You can use the adapter:
/// final adapter = LazyRelationAdapter('users', 'user1', lazyRelation);
/// final posts = await adapter.load();
/// ```
class LazyRelationAdapter {
  /// The source box name.
  final String boxName;

  /// The source key.
  final dynamic sourceKey;

  /// The lazy relation to adapt.
  final LazyRelation lazyRelation;

  /// Whether data has been loaded.
  bool _hasLoaded = false;

  /// The loaded data.
  List<dynamic> _data = [];

  /// Creates a new lazy relation adapter.
  LazyRelationAdapter({
    required this.boxName,
    required this.sourceKey,
    required this.lazyRelation,
  });

  /// Loads the related data if not already loaded.
  ///
  /// Returns the loaded data.
  Future<List<dynamic>> load() async {
    if (!_hasLoaded) {
      _data = await lazyRelation.load(sourceKey);
      _hasLoaded = true;
    }
    return _data;
  }

  /// Gets the related data, loading it first if necessary.
  ///
  /// This is the primary accessor method. It ensures the data is
  /// loaded before returning it.
  Future<List<dynamic>> get data async => load();

  /// Whether the data has been loaded into memory.
  bool get isLoaded => _hasLoaded;

  /// Invalidates the cached data, forcing a reload on next access.
  void invalidate() {
    _hasLoaded = false;
    _data = [];
    lazyRelation.invalidate(sourceKey);
  }

  /// Returns the first related entry, or null if none exist.
  Future<dynamic> get first async {
    final loaded = await load();
    return loaded.isNotEmpty ? loaded.first : null;
  }

  /// Returns the number of related entries.
  Future<int> get length async => (await load()).length;

  /// Checks if there are any related entries.
  Future<bool> get isEmpty async => (await load()).isEmpty;

  /// Checks if there are any related entries.
  Future<bool> get isNotEmpty async => (await load()).isNotEmpty;
}
