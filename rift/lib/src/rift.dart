import 'dart:typed_data';

import 'package:rift/rift.dart';
import 'package:rift/src/box/default_compaction_strategy.dart';
import 'package:rift/src/box/default_key_comparator.dart';
import 'package:meta/meta.dart';

/// The main API interface of Rift. Available through the `Rift` constant.
abstract class RiftInterface implements TypeRegistry {
  /// Initialize Rift by giving it a home directory.
  ///
  /// (Not necessary in the browser)
  void init(
    String? path, {
    RiftStorageBackendPreference backendPreference =
        RiftStorageBackendPreference.native,
  });

  /// Opens a box.
  ///
  /// If the box is already open, the instance is returned and all provided
  /// parameters are being ignored.
  Future<Box<E>> openBox<E>(
    String name, {
    RiftCipher? encryptionCipher,
    RiftCompression? compression,
    KeyComparator keyComparator = defaultKeyComparator,
    CompactionStrategy compactionStrategy = defaultCompactionStrategy,
    bool crashRecovery = true,
    String? path,
    Uint8List? bytes,
    String? collection,
    @Deprecated('Use encryptionCipher instead') List<int>? encryptionKey,
  });

  /// Opens a lazy box.
  ///
  /// If the box is already open, the instance is returned and all provided
  /// parameters are being ignored.
  Future<LazyBox<E>> openLazyBox<E>(
    String name, {
    RiftCipher? encryptionCipher,
    RiftCompression? compression,
    KeyComparator keyComparator = defaultKeyComparator,
    CompactionStrategy compactionStrategy = defaultCompactionStrategy,
    bool crashRecovery = true,
    String? path,
    String? collection,
    @Deprecated('Use encryptionCipher instead') List<int>? encryptionKey,
  });

  /// Returns a previously opened box.
  Box<E> box<E>(String name);

  /// Returns a previously opened lazy box.
  LazyBox<E> lazyBox<E>(String name);

  /// Checks if a specific box is currently open.
  bool isBoxOpen(String name);

  /// Closes all open boxes.
  Future<void> close();

  /// Removes the file which contains the box and closes the box.
  ///
  /// In the browser, the IndexedDB database is being removed.
  Future<void> deleteBoxFromDisk(String name, {String? path});

  /// Deletes all currently open boxes from disk.
  ///
  /// The home directory will not be deleted.
  Future<void> deleteFromDisk();

  /// Generates a secure encryption key using the fortuna random algorithm.
  List<int> generateSecureKey();

  /// Checks if a box exists
  Future<bool> boxExists(String name, {String? path});

  /// Creates a full backup of all open boxes.
  ///
  /// Returns a JSON-serializable map that can be written to disk or
  /// transmitted over the network.
  ///
  /// ```dart
  /// final backup = await Rift.backup();
  /// await File('backup.riftbak').writeAsString(jsonEncode(backup));
  /// ```
  Future<Map<String, dynamic>> backup();

  /// Restores all open boxes from a previously created backup.
  ///
  /// This clears existing data in each box and replaces it with the
  /// backup contents. Boxes in the backup that are not currently open
  /// are skipped.
  ///
  /// ```dart
  /// final backup = jsonDecode(await File('backup.riftbak').readAsString());
  /// await Rift.restore(backup);
  /// ```
  Future<void> restore(Map<String, dynamic> backup);

  /// Creates an incremental backup (only changes since [sinceTimestamp]).
  ///
  /// [sinceTimestamp] is in milliseconds since epoch.
  Future<Map<String, dynamic>> backupIncremental(int sinceTimestamp);

  /// Adds a middleware to the global middleware chain.
  ///
  /// Middleware are called before and after every put, delete, and clear
  /// operation on all boxes. They are executed in the order they are added.
  ///
  /// ```dart
  /// Rift.use(LoggingMiddleware());
  /// Rift.use(ValidationMiddleware(schemas: [...]));
  /// ```
  void use(RiftMiddleware middleware);

  /// Removes a middleware from the global middleware chain.
  void removeMiddleware(RiftMiddleware middleware);

  /// Clears all registered adapters.
  ///
  /// To register an adapter use [registerAdapter].
  ///
  /// NOTE: [resetAdapters] also clears the default adapters registered
  /// by Rift.
  ///
  /// WARNING: This method is only intended to be used for integration and unit tests
  /// and SHOULD not be used in production code.
  @visibleForTesting
  void resetAdapters();
}

///
typedef KeyComparator = int Function(dynamic key1, dynamic key2);

/// A function which decides when to compact a box.
typedef CompactionStrategy = bool Function(int entries, int deletedEntries);
