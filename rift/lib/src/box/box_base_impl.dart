import 'package:rift/src/binary/frame.dart';
import 'package:rift/src/backend/storage_backend.dart';
import 'package:rift/src/backend/vm/storage_backend_vm.dart';
import 'package:rift/src/box/box_base.dart';
import 'package:rift/src/box/change_notifier.dart';
import 'package:rift/src/box/keystore.dart';
import 'package:rift/src/connect/rift_connect.dart';
import 'package:rift/src/connect/rift_connect_api.dart';
import 'package:rift/src/connect/inspectable_box.dart';
import 'package:rift/src/index/index_manager.dart';
import 'package:rift/src/index/rift_index.dart';
import 'package:rift/src/index/secondary_index.dart';
import 'package:rift/src/middleware/middleware.dart';
import 'package:rift/src/query/rift_query.dart';
import 'package:rift/src/relations/relation.dart';
import 'package:rift/src/rift.dart' show CompactionStrategy, KeyComparator;
import 'package:rift/src/rift_error.dart';
import 'package:rift/src/rift_impl.dart';
import 'package:rift/src/ttl/ttl_manager.dart';
import 'package:rift/src/ttl/ttl_storage.dart';
import 'package:rift/src/wal/wal_manager.dart';
import 'package:rift/src/wal/wal_entry.dart';
import 'package:rift/src/registry/type_registry.dart';
import 'package:meta/meta.dart';

/// Not part of public API
abstract class BoxBaseImpl<E> implements BoxBase<E>, InspectableBox {
  /// TODO: Document this!
  static BoxBase<E> nullImpl<E>() => _NullBoxBase<E>();

  @override
  final String name;

  /// Not part of public API
  @visibleForTesting
  final RiftImpl rift;

  final CompactionStrategy _compactionStrategy;

  /// Not part of public API
  @protected
  final StorageBackend backend;

  /// Not part of public API
  ///
  /// Not `late final` for testing
  @protected
  @visibleForTesting
  late Keystore<E> keystore;

  /// Whether this box is isolated
  final bool isolated;

  /// Global middleware chain shared across all boxes.
  static final MiddlewareChain _globalMiddlewareChain = MiddlewareChain();

  /// Global TTL manager shared across all boxes.
  static final TTLManager _globalTTLManager = TTLManager(storage: TTLStorage());

  /// Global relation manager shared across all boxes.
  static final RelationManager _globalRelationManager = RelationManager();

  var _open = true;

  /// Not part of public API
  BoxBaseImpl(
    this.rift,
    this.name,
    KeyComparator? keyComparator,
    this._compactionStrategy,
    this.backend, {
    this.isolated = false,
  }) {
    keystore = Keystore(this, ChangeNotifier(), keyComparator);
    _initializeWAL();
  }

  /// Initializes WAL integration for this box.
  ///
  /// Sets the box name on the backend (so WAL entries are tagged correctly)
  /// and registers a recovery replay callback so WAL entries can be replayed
  /// during crash recovery.
  void _initializeWAL() {
    if (backend is StorageBackendVm) {
      final vmBackend = backend as StorageBackendVm;
      vmBackend.setBoxName(name);

      if (vmBackend.walManager != null) {
        vmBackend.walManager!.registerReplayCallback(name, _replayWALEntry);
      }
    }
  }

  /// Callback for replaying a WAL entry during crash recovery.
  ///
  /// This method is called by [WALManager.recover] for each uncommitted
  /// entry that belongs to this box. It re-applies the entry by writing
  /// the corresponding frames to the backend.
  Future<void> _replayWALEntry(String boxName, WALEntry entry) async {
    if (!_open) return;

    switch (entry.type) {
      case WALEntryType.put:
        if (entry.key != null) {
          await backend.writeFrames([Frame(entry.key, entry.value)]);
        }
        break;
      case WALEntryType.delete:
        if (entry.key != null) {
          await backend.writeFrames([Frame.deleted(entry.key)]);
        }
        break;
      case WALEntryType.putAll:
        // For putAll, we write the serialized value as a single frame
        // The value contains the serialized map of key-value pairs
        if (entry.value != null) {
          await backend.writeFrames([Frame(entry.key ?? 'batch', entry.value)]);
        }
        break;
      case WALEntryType.clear:
        await backend.clear();
        break;
    }
  }

  /// Not part of public API
  Type get valueType => E;

  @override
  bool get isOpen => _open;

  @override
  String? get path => backend.path;

  @override
  Iterable<dynamic> get keys {
    checkOpen();
    return keystore.getKeys();
  }

  @override
  int get length {
    checkOpen();
    return keystore.length;
  }

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => length > 0;

  /// Not part of public API
  @protected
  void checkOpen() {
    if (!_open) {
      throw RiftError('Box has already been closed.');
    }
  }

  @override
  Stream<BoxEvent> watch({dynamic key}) {
    checkOpen();
    return keystore.watch(key: key);
  }

  @override
  dynamic keyAt(int index) {
    checkOpen();
    return keystore.getAt(index)!.key;
  }

  /// Not part of public API
  Future<void> initialize() async {
    await backend.initialize(rift, keystore, lazy, isolated: isolated);
  }

  @override
  bool containsKey(dynamic key) {
    checkOpen();
    // Check TTL expiry — treat expired keys as non-existent
    if (_globalTTLManager.isExpired(name, key)) {
      return false;
    }
    return keystore.containsKey(key);
  }

  /// Gets the global middleware chain.
  static MiddlewareChain get middlewareChain => _globalMiddlewareChain;

  /// Gets the global TTL manager.
  static TTLManager get ttlManager => _globalTTLManager;

  /// Gets the global relation manager.
  static RelationManager get relationManager => _globalRelationManager;

  @override
  Future<void> put(dynamic key, E value) => putAll({key: value});

  /// Puts a value with an optional TTL (Time-To-Live).
  ///
  /// After the [ttl] duration elapses, the entry will be considered
  /// expired and subsequent get operations will return null.
  Future<void> putWithTTL(dynamic key, E value, Duration ttl) async {
    await putAll({key: value});
    await _globalTTLManager.setTTL(name, key, ttl);
  }

  @override
  Future<void> delete(dynamic key) => deleteAll([key]);

  @override
  Future<int> add(E value) async {
    final key = keystore.autoIncrement();
    await put(key, value);
    return key;
  }

  @override
  Future<Iterable<int>> addAll(Iterable<E> values) async {
    final entries = <int, E>{};
    for (final value in values) {
      entries[keystore.autoIncrement()] = value;
    }
    await putAll(entries);
    return entries.keys;
  }

  @override
  Future<void> putAt(int index, E value) {
    return putAll({keystore.getAt(index)!.key: value});
  }

  @override
  Future<void> deleteAt(int index) {
    return delete(keystore.getAt(index)!.key);
  }

  /// Create a fluent query builder for this box.
  ///
  /// Returns a [RiftQuery] that can be chained with [where], [sortBy],
  /// [limit], and [offset] calls, then executed with [findAll],
  /// [findFirst], [count], or [watch].
  ///
  /// Example:
  /// ```dart
  /// final adults = await box.query()
  ///   .where('age', greaterThan: 18)
  ///   .where('city', equalTo: 'Cairo')
  ///   .sortBy('name')
  ///   .limit(10)
  ///   .findAll();
  /// ```
  RiftQuery<E> query() {
    checkOpen();
    return RiftQuery<E>(this, globalIndexManager);
  }

  /// Create a secondary index on a field for faster queries.
  ///
  /// Once created, the index is automatically maintained when data
  /// is written or deleted. Queries on the indexed field will
  /// automatically use the index for faster lookups.
  ///
  /// [type] determines the index data structure:
  /// - [IndexType.btree] (default): Sorted index supporting range queries
  /// - [IndexType.hash]: Hash index for O(1) equality lookups only
  ///
  /// Example:
  /// ```dart
  /// await box.createIndex('age');
  /// await box.createIndex('name', type: IndexType.hash);
  /// ```
  Future<void> createIndex(
    String field, {
    IndexType type = IndexType.btree,
  }) async {
    checkOpen();
    await globalIndexManager.createIndex(name, field, type: type);
    // Rebuild the index from existing data
    final entries = <MapEntry<dynamic, dynamic>>[];
    for (final frame in keystore.frames) {
      entries.add(MapEntry(frame.key, frame.value));
    }
    await globalIndexManager.rebuildIndexes(name, entries);
  }

  /// Drop (remove) a secondary index.
  Future<void> dropIndex(String field) async {
    checkOpen();
    await globalIndexManager.dropIndex(name, field);
  }

  /// Register a custom field value extractor for this box.
  ///
  /// The [extractor] is called to retrieve field values from stored
  /// objects during queries and index operations. This is necessary
  /// for custom objects that don't implement Map or toJson().
  ///
  /// Example:
  /// ```dart
  /// box.registerFieldExtractor((value, field) {
  ///   if (value is User) {
  ///     switch (field) {
  ///       case 'name': return value.name;
  ///       case 'age': return value.age;
  ///       default: return null;
  ///     }
  ///   }
  ///   return defaultFieldValueExtractor(value, field);
  /// });
  /// ```
  void registerFieldExtractor(FieldValueExtractor extractor) {
    globalIndexManager.registerFieldExtractor(name, extractor);
  }

  @override
  Future<int> clear() async {
    checkOpen();

    // Run before-clear middleware
    if (_globalMiddlewareChain.isNotEmpty) {
      final allowed = await _globalMiddlewareChain.runBeforeClear(name);
      if (!allowed) return 0;
    }

    // Clear indexes for this box
    await globalIndexManager.dropAllIndexes(name);

    // Clear TTL entries for this box
    await _globalTTLManager.removeAllTTL(name);

    await backend.clear();
    final count = keystore.clear();

    // Run after-clear middleware
    if (_globalMiddlewareChain.isNotEmpty) {
      await _globalMiddlewareChain.runAfterClear(name);
    }

    return count;
  }

  @override
  Future<void> compact() async {
    checkOpen();

    if (!backend.supportsCompaction) return;
    if (keystore.deletedEntries == 0) return;

    await backend.compact(keystore.frames);
    keystore.resetDeletedEntries();
  }

  /// Not part of public API
  @protected
  Future<void> performCompactionIfNeeded() {
    if (_compactionStrategy(keystore.length, keystore.deletedEntries)) {
      return compact();
    }

    return Future.value();
  }

  @override
  Future<void> close() async {
    if (!_open) return;

    // Clean up relation index for this box
    _globalRelationManager.clearRelationIndexForBox(name);

    _open = false;
    await keystore.close();
    rift.unregisterBox(name);
    RiftConnect.unregisterBox(this);

    await backend.close();
  }

  @override
  Future<void> deleteFromDisk() async {
    // Purge WAL entries for this box before deleting
    if (backend is StorageBackendVm) {
      final vmBackend = backend as StorageBackendVm;
      if (vmBackend.walManager != null) {
        await vmBackend.walManager!.purgeBox(name);
      }
    }

    if (_open) {
      _open = false;
      await keystore.close();
      rift.unregisterBox(name);
    }

    await backend.deleteFromDisk();
  }

  @override
  TypeRegistry get typeRegistry => rift;

  @override
  Future<Iterable<InspectorFrame>> getFrames() async =>
      keystore.frames.map(InspectorFrame.fromFrame);
}

class _NullBoxBase<E> implements BoxBase<E> {
  @override
  Never add(E value) => throw UnimplementedError();

  @override
  Never addAll(Iterable<E> values) => throw UnimplementedError();

  @override
  Never clear() => throw UnimplementedError();

  @override
  Never close() => throw UnimplementedError();

  @override
  Never compact() => throw UnimplementedError();

  @override
  Never containsKey(key) => throw UnimplementedError();

  @override
  Never delete(key) => throw UnimplementedError();

  @override
  Never deleteAll(Iterable keys) => throw UnimplementedError();

  @override
  Never deleteAt(int index) => throw UnimplementedError();

  @override
  Never deleteFromDisk() => throw UnimplementedError();

  @override
  Never get isEmpty => throw UnimplementedError();

  @override
  Never get isNotEmpty => throw UnimplementedError();

  @override
  Never get isOpen => throw UnimplementedError();

  @override
  Never keyAt(int index) => throw UnimplementedError();

  @override
  Never get keys => throw UnimplementedError();

  @override
  Never get lazy => throw UnimplementedError();

  @override
  Never get length => throw UnimplementedError();

  @override
  Never get name => throw UnimplementedError();

  @override
  Never get path => throw UnimplementedError();

  @override
  Never put(key, E value) => throw UnimplementedError();

  @override
  Never putAll(Map<dynamic, E> entries) => throw UnimplementedError();

  @override
  Never putAt(int index, E value) => throw UnimplementedError();

  @override
  Never watch({key}) => throw UnimplementedError();

  @override
  Never flush() => throw UnimplementedError();

  Never query() => throw UnimplementedError();

  Never createIndex(String field, {IndexType type = IndexType.btree}) =>
      throw UnimplementedError();

  Never dropIndex(String field) => throw UnimplementedError();

  Never registerFieldExtractor(FieldValueExtractor extractor) =>
      throw UnimplementedError();

  Never putWithTTL(key, E value, Duration ttl) => throw UnimplementedError();

  Never createRelation(RelationConfig config) => throw UnimplementedError();

  Never getRelated(dynamic key, String field) => throw UnimplementedError();
}
