import 'dart:async';
import 'dart:io';

import 'package:rift/rift.dart';
import 'package:rift/src/backend/storage_backend.dart';
import 'package:rift/src/backend/vm/storage_backend_vm.dart';
import 'package:rift/src/util/logger.dart';
import 'package:rift/src/wal/wal_manager.dart';
import 'package:meta/meta.dart';

/// Not part of public API
class BackendManager implements BackendManagerInterface {
  final _delimiter = Platform.isWindows ? '\\' : '/';

  /// Whether WAL-based crash safety is enabled.
  final bool walEnabled;

  /// Cached WAL managers keyed by their base directory path.
  /// Multiple boxes in the same directory share a single WAL manager
  /// and therefore a single WAL file.
  final Map<String, WALManager> _walManagers = {};

  /// TODO: Document this!
  static BackendManager select([
    RiftStorageBackendPreference? backendPreference,
    bool walEnabled = true,
  ]) => BackendManager(walEnabled: walEnabled);

  /// Creates a new [BackendManager].
  ///
  /// If [walEnabled] is `true` (the default), a [WALManager] is created
  /// for each database directory and passed to the [StorageBackendVm]
  /// instances it creates. Set to `false` to disable WAL logging.
  BackendManager({this.walEnabled = true});

  @override
  Future<StorageBackend> open(
    String name,
    String? path,
    bool crashRecovery,
    RiftCipher? cipher,
    int? keyCrc,
    String? collection,
  ) async {
    if (path == null) {
      throw RiftError(
        'You need to initialize Rift or '
        'provide a path to store the box.',
      );
    }

    if (path.endsWith(_delimiter)) path = path.substring(0, path.length - 1);

    if (collection != null) {
      path = path + collection;
    }

    final dir = Directory(path);

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final file = await findRiftFileAndCleanUp(name, path);
    final lockFile = File('$path$_delimiter$name.lock');

    // Get or create a WAL manager for this directory
    final walManager = walEnabled ? await _getOrCreateWALManager(path) : null;

    final backend = StorageBackendVm(
      file,
      lockFile,
      crashRecovery,
      cipher,
      keyCrc,
      walManager: walManager,
    );
    await backend.open();
    return backend;
  }

  /// Not part of public API
  @visibleForTesting
  Future<File> findRiftFileAndCleanUp(String name, String path) async {
    final riftFile = File('$path$_delimiter$name.hive');
    final compactedFile = File('$path$_delimiter$name.hivec');

    if (await riftFile.exists()) {
      if (await compactedFile.exists()) {
        await compactedFile.delete();
      }
      return riftFile;
    } else if (await compactedFile.exists()) {
      Logger.i('Restoring compacted file.');
      return await compactedFile.rename(riftFile.path);
    } else {
      await riftFile.create();
      return riftFile;
    }
  }

  @override
  Future<void> deleteBox(String name, String? path, String? collection) async {
    ArgumentError.checkNotNull(path, 'path');

    if (path!.endsWith(_delimiter)) path = path.substring(0, path.length - 1);

    if (collection != null) {
      path = path + collection;
    }

    await _deleteFileIfExists(File('$path$_delimiter$name.hive'));
    await _deleteFileIfExists(File('$path$_delimiter$name.hivec'));
    await _deleteFileIfExists(File('$path$_delimiter$name.lock'));
  }

  Future<void> _deleteFileIfExists(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Gets or creates a [WALManager] for the given [directory].
  ///
  /// WAL managers are cached by directory path so that multiple boxes in
  /// the same directory share a single WAL file. The WAL manager is opened
  /// before being returned.
  Future<WALManager> _getOrCreateWALManager(String directory) async {
    if (!_walManagers.containsKey(directory)) {
      final manager = WALManager(directory, enabled: walEnabled);
      await manager.open();
      _walManagers[directory] = manager;
    }
    return _walManagers[directory]!;
  }

  /// Closes all cached WAL managers.
  ///
  /// Call this when shutting down the application to ensure all WAL files
  /// are properly closed.
  Future<void> closeAllWALManagers() async {
    for (final manager in _walManagers.values) {
      await manager.close();
    }
    _walManagers.clear();
  }

  @override
  Future<bool> boxExists(String name, String? path, String? collection) async {
    ArgumentError.checkNotNull(path, 'path');

    if (path!.endsWith(_delimiter)) path = path.substring(0, path.length - 1);

    if (collection != null) {
      path = path + collection;
    }

    return await File('$path$_delimiter$name.hive').exists() ||
        await File('$path$_delimiter$name.hivec').exists() ||
        await File('$path$_delimiter$name.lock').exists();
  }
}
