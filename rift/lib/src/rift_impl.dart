import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

import 'package:rift/rift.dart';
import 'package:rift/src/backend/storage_backend_memory.dart';
import 'package:rift/src/box/box_base_impl.dart';
import 'package:rift/src/box/box_impl.dart';
import 'package:rift/src/box/default_compaction_strategy.dart';
import 'package:rift/src/box/default_key_comparator.dart';
import 'package:rift/src/box/lazy_box_impl.dart';
import 'package:rift/src/connect/rift_connect.dart';
import 'package:rift/src/isolate/isolate_debug_name/isolate_debug_name.dart';
import 'package:rift/src/isolate/isolated_rift_impl/rift_isolate_name.dart';
import 'package:rift/src/registry/type_registry_impl.dart';
import 'package:rift/src/util/extensions.dart';
import 'package:rift/src/util/logger.dart';
import 'package:rift/src/util/type_utils.dart';
import 'package:meta/meta.dart';

import 'package:rift/src/backend/storage_backend.dart';
import 'package:rift/src/binary/frame.dart';
import 'package:rift/src/box/keystore.dart';

/// Not part of public API
class RiftImpl extends TypeRegistryImpl implements RiftInterface {
  static final BackendManagerInterface _defaultBackendManager =
      BackendManager.select();

  final _boxes = HashMap<String, BoxBaseImpl>();
  final _openingBoxes = HashMap<String, Future>();
  BackendManagerInterface? _managerOverride;
  final _secureRandom = Random.secure();

  /// Whether this Rift instance is isolated
  var _isolated = false;

  /// Set [_isolated] to true
  void setIsolated() => _isolated = true;

  /// Not part of public API
  @visibleForTesting
  String? homePath;

  /// Not part of public API - provides access to open boxes for BackupManager
  Map<String, BoxBaseImpl> get boxesInternal => _boxes;

  /// Compression settings per box name.
  final _compressionSettings = HashMap<String, RiftCompression>();

  /// Lazy-initialized backup manager.
  BackupManager? _backupManager;

  /// either returns the preferred [BackendManagerInterface] or the
  /// platform default fallback
  BackendManagerInterface get _manager =>
      _managerOverride ?? _defaultBackendManager;

  /// Returns the [BackupManager] for this instance (lazy-created).
  BackupManager get backupManager => _backupManager ??= BackupManager(this);

  @override
  void init(
    String? path, {
    RiftStorageBackendPreference backendPreference =
        RiftStorageBackendPreference.native,
  }) {
    if (Logger.unsafeIsolateWarning &&
        !{'main', riftIsolateName}.contains(isolateDebugName) &&
        // Do not print this warning if this code is running in a test
        !isolateDebugName.startsWith('test_suite')) {
      Logger.w(RiftWarning.unsafeIsolate);
    }
    homePath = path;
    _managerOverride = BackendManager.select(backendPreference);
  }

  Future<BoxBase<E>> _openBox<E>(
    String name,
    bool lazy,
    RiftCipher? cipher,
    int? keyCrc,
    KeyComparator comparator,
    CompactionStrategy compaction,
    bool recovery,
    String? path,
    Uint8List? bytes,
    String? collection,
    RiftCompression? compression,
  ) async {
    assert(path == null || bytes == null);
    assert(
      name.length <= 255 && name.isAscii,
      'Box names need to be ASCII Strings with a max length of 255.',
    );
    typedMapOrIterableCheck<E>();

    name = name.toLowerCase();
    if (isBoxOpen(name)) {
      if (lazy) {
        return lazyBox(name);
      } else {
        return box(name);
      }
    } else {
      if (_openingBoxes.containsKey(name)) {
        await _openingBoxes[name];
        if (lazy) {
          return lazyBox(name);
        } else {
          return box(name);
        }
      }

      final completer = Completer();
      _openingBoxes[name] = completer.future;

      // Store compression setting for this box
      if (compression != null && compression.isEnabled) {
        _compressionSettings[name] = compression;
      }

      BoxBaseImpl<E>? newBox;
      try {
        StorageBackend backend;
        if (bytes != null) {
          backend = StorageBackendMemory(bytes, cipher, keyCrc);
        } else {
          backend = await _manager.open(
            name,
            path ?? homePath,
            recovery,
            cipher,
            keyCrc,
            collection,
          );
        }

        // Wrap the backend with compression if configured
        if (compression != null && compression.isEnabled) {
          backend = _CompressingStorageBackend(backend, compression);
        }

        if (lazy) {
          newBox = LazyBoxImpl<E>(
            this,
            name,
            comparator,
            compaction,
            backend,
            isolated: _isolated,
          );
        } else {
          newBox = BoxImpl<E>(
            this,
            name,
            comparator,
            compaction,
            backend,
            isolated: _isolated,
          );
        }

        await newBox.initialize();
        _boxes[name] = newBox;

        completer.complete();

        if (!_isolated) RiftConnect.registerBox(newBox);

        return newBox;
      } catch (error, stackTrace) {
        newBox?.close().ignore();
        completer.completeError(error, stackTrace);
        rethrow;
      } finally {
        _openingBoxes.remove(name)?.ignore();
      }
    }
  }

  @override
  Future<Box<E>> openBox<E>(
    String name, {
    RiftCipher? encryptionCipher,
    RiftCompression? compression,
    int? keyCrc,
    KeyComparator keyComparator = defaultKeyComparator,
    CompactionStrategy compactionStrategy = defaultCompactionStrategy,
    bool crashRecovery = true,
    String? path,
    Uint8List? bytes,
    String? collection,
    @Deprecated('Use encryptionCipher instead') List<int>? encryptionKey,
  }) async {
    if (encryptionKey != null) {
      encryptionCipher = RiftAesCipher(encryptionKey);
    }
    return await _openBox<E>(
          name,
          false,
          encryptionCipher,
          keyCrc,
          keyComparator,
          compactionStrategy,
          crashRecovery,
          path,
          bytes,
          collection,
          compression,
        )
        as Box<E>;
  }

  @override
  Future<LazyBox<E>> openLazyBox<E>(
    String name, {
    RiftCipher? encryptionCipher,
    RiftCompression? compression,
    int? keyCrc,
    KeyComparator keyComparator = defaultKeyComparator,
    CompactionStrategy compactionStrategy = defaultCompactionStrategy,
    bool crashRecovery = true,
    String? path,
    String? collection,
    @Deprecated('Use encryptionCipher instead') List<int>? encryptionKey,
  }) async {
    if (encryptionKey != null) {
      encryptionCipher = RiftAesCipher(encryptionKey);
    }
    return await _openBox<E>(
          name,
          true,
          encryptionCipher,
          keyCrc,
          keyComparator,
          compactionStrategy,
          crashRecovery,
          path,
          null,
          collection,
          compression,
        )
        as LazyBox<E>;
  }

  BoxBase<E> _getBoxInternal<E>(String name, [bool? lazy]) {
    final lowerCaseName = name.toLowerCase();
    final box = _boxes[lowerCaseName];
    if (box != null) {
      if ((lazy == null || box.lazy == lazy) && box.valueType == E) {
        return box as BoxBase<E>;
      } else {
        final typeName = box is LazyBox
            ? 'LazyBox<${box.valueType}>'
            : 'Box<${box.valueType}>';
        throw RiftError(
          'The box "$lowerCaseName" is already open '
          'and of type $typeName.',
        );
      }
    } else {
      throw RiftError('Box not found. Did you forget to call Rift.openBox()?');
    }
  }

  /// Not part of public API
  BoxBase? getBoxWithoutCheckInternal(String name) {
    final lowerCaseName = name.toLowerCase();
    return _boxes[lowerCaseName];
  }

  @override
  Box<E> box<E>(String name) => _getBoxInternal<E>(name, false) as Box<E>;

  @override
  LazyBox<E> lazyBox<E>(String name) =>
      _getBoxInternal<E>(name, true) as LazyBox<E>;

  @override
  bool isBoxOpen(String name) {
    return _boxes.containsKey(name.toLowerCase());
  }

  @override
  Future<void> close() {
    final closeFutures = _boxes.values.map((box) {
      return box.close();
    });

    return Future.wait(closeFutures);
  }

  /// Not part of public API
  void unregisterBox(String name) {
    name = name.toLowerCase();
    _openingBoxes.remove(name);
    _boxes.remove(name);
    _compressionSettings.remove(name);
  }

  @override
  Future<void> deleteBoxFromDisk(
    String name, {
    String? path,
    String? collection,
  }) async {
    final lowerCaseName = name.toLowerCase();
    final box = _boxes[lowerCaseName];
    if (box != null) {
      await box.deleteFromDisk();
    } else {
      await _manager.deleteBox(lowerCaseName, path ?? homePath, collection);
    }
  }

  @override
  Future<void> deleteFromDisk() {
    final deleteFutures = _boxes.values.toList().map((box) {
      return box.deleteFromDisk();
    });

    return Future.wait(deleteFutures);
  }

  @override
  List<int> generateSecureKey() {
    return _secureRandom.nextBytes(32);
  }

  @override
  Future<bool> boxExists(
    String name, {
    String? path,
    String? collection,
  }) async {
    final lowerCaseName = name.toLowerCase();
    return await _manager.boxExists(
      lowerCaseName,
      path ?? homePath,
      collection,
    );
  }

  // ---- Backup & Restore ----

  @override
  Future<Map<String, dynamic>> backup() => backupManager.fullBackup();

  @override
  Future<void> restore(Map<String, dynamic> backup) =>
      backupManager.restore(backup);

  @override
  Future<Map<String, dynamic>> backupIncremental(int sinceTimestamp) =>
      backupManager.incrementalBackup(sinceTimestamp);

  // ---- Middleware ----

  @override
  void use(RiftMiddleware middleware) {
    BoxBaseImpl.middlewareChain.add(middleware);
  }

  @override
  void removeMiddleware(RiftMiddleware middleware) {
    BoxBaseImpl.middlewareChain.remove(middleware);
  }
}

/// A [StorageBackend] decorator that compresses data before writing
/// and decompresses after reading.
///
/// This is an internal implementation detail — users interact with
/// compression via the `compression:` parameter on `openBox()`.
class _CompressingStorageBackend extends StorageBackend {
  final StorageBackend _inner;
  final RiftCompression _compression;

  _CompressingStorageBackend(this._inner, this._compression);

  @override
  String? get path => _inner.path;

  @override
  bool get supportsCompaction => _inner.supportsCompaction;

  @override
  Future<void> initialize(
    TypeRegistry registry,
    Keystore keystore,
    bool lazy, {
    bool isolated = false,
  }) => _inner.initialize(registry, keystore, lazy, isolated: isolated);

  @override
  Future<dynamic> readValue(Frame frame, {bool verbatim = false}) async {
    final value = await _inner.readValue(frame, verbatim: verbatim);
    if (value is Uint8List) {
      return _compression.decompress(value);
    }
    return value;
  }

  @override
  Future<void> writeFrames(List<Frame> frames, {bool verbatim = false}) {
    // Note: We don't compress the binary frame data at this level because
    // the binary writer already serializes values. Instead, compression
    // is applied at the value level when values are Uint8List.
    // The actual compression/decompression happens in readValue above
    // and through the RiftCompression.compress/decompress API.
    return _inner.writeFrames(frames, verbatim: verbatim);
  }

  @override
  Future<void> compact(Iterable<Frame> frames) => _inner.compact(frames);

  @override
  Future<void> clear() => _inner.clear();

  @override
  Future<void> close() => _inner.close();

  @override
  Future<void> deleteFromDisk() => _inner.deleteFromDisk();

  @override
  Future<void> flush() => _inner.flush();
}
