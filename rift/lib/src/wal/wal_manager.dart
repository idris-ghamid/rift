import 'dart:io';
import 'dart:typed_data';

import 'package:rift/src/binary/binary_writer_impl.dart';
import 'package:rift/src/registry/type_registry_impl.dart';
import 'package:rift/src/util/logger.dart';
import 'package:rift/src/wal/wal_entry.dart';
import 'package:rift/src/wal/wal_file.dart';

/// Callback signature for replaying a recovered WAL entry against a box.
///
/// The [boxName] identifies which box the entry belongs to. The [frames]
/// contains the serialized frame data that should be written to the box's
/// backend.
typedef WALReplayCallback =
    Future<void> Function(String boxName, WALEntry entry);

/// Manages the Write-Ahead Log for crash recovery.
///
/// Before any write operation is applied to the main data file, it is first
/// recorded in the WAL. If the app crashes before the write is fully applied,
/// the WAL is replayed on next open to restore consistency.
///
/// Usage:
/// ```dart
/// final wal = WALManager('/path/to/db', enabled: true);
/// await wal.open();
///
/// // Before writing to the data file:
/// await wal.log(entry);
///
/// // After successful checkpoint (compaction):
/// await wal.checkpoint();
///
/// await wal.close();
/// ```
class WALManager {
  /// The base directory path where WAL files are stored.
  final String _basePath;

  /// Whether the WAL is enabled. When disabled, all operations are no-ops.
  final bool enabled;

  WALFile? _walFile;
  int _sequenceNumber = 0;
  bool _isOpen = false;

  /// Whether we are currently in recovery mode. During recovery, WAL
  /// logging is suppressed to prevent infinite loops (replay calls
  /// backend.writeFrames which would otherwise log to WAL again).
  bool _recovering = false;

  /// Whether WAL logging is currently suppressed.
  bool get _suppressLogging => _recovering;

  /// The registry used for serializing values in WAL entries.
  TypeRegistryImpl? _registry;

  /// Callbacks indexed by box name for replaying entries during recovery.
  final Map<String, WALReplayCallback> _replayCallbacks = {};

  /// Creates a new [WALManager].
  ///
  /// [_basePath] is the directory where the WAL file will be stored.
  /// If [enabled] is `false`, all WAL operations become no-ops, which is
  /// useful for in-memory backends or when crash recovery is not needed.
  WALManager(this._basePath, {this.enabled = true});

  /// The file path of the WAL file.
  String get _walPath => '$_basePath${Platform.pathSeparator}rift.wal';

  /// Opens the WAL file for reading and writing.
  ///
  /// If the WAL file already exists (indicating a previous crash), the
  /// existing entries are preserved for later recovery via [recover].
  Future<void> open() async {
    if (!enabled || _isOpen) return;

    try {
      final dir = Directory(_basePath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _walFile = await WALFile.open(_walPath);
      _isOpen = true;
      Logger.i('WAL opened at $_walPath');
    } catch (e) {
      Logger.w('Failed to open WAL file: $e. WAL will be disabled.');
    }
  }

  /// Sets the type registry used for serializing values.
  void setRegistry(TypeRegistryImpl registry) {
    _registry = registry;
  }

  /// Registers a callback for replaying WAL entries for the given [boxName].
  void registerReplayCallback(String boxName, WALReplayCallback callback) {
    _replayCallbacks[boxName] = callback;
  }

  /// Unregisters the replay callback for the given [boxName].
  void unregisterReplayCallback(String boxName) {
    _replayCallbacks.remove(boxName);
  }

  /// Writes a single entry to the WAL.
  ///
  /// The entry is immediately flushed to disk to ensure durability.
  /// If the WAL is not enabled or not open, or if recovery is in progress,
  /// this is a no-op.
  Future<void> log(WALEntry entry) async {
    if (!enabled || !_isOpen || _walFile == null || _suppressLogging) return;

    try {
      await _walFile!.writeEntry(entry);
    } catch (e) {
      Logger.w('Failed to write WAL entry: $e');
    }
  }

  /// Writes multiple entries atomically.
  ///
  /// All entries are written sequentially and flushed to disk as a batch.
  /// If the WAL is not enabled or not open, or if recovery is in progress,
  /// this is a no-op.
  Future<void> logBatch(List<WALEntry> entries) async {
    if (!enabled || !_isOpen || _walFile == null || _suppressLogging) return;

    try {
      await _walFile!.writeEntries(entries);
    } catch (e) {
      Logger.w('Failed to write WAL batch: $e');
    }
  }

  /// Creates a [WALEntry] for a put operation.
  ///
  /// The [value] is serialized using the type registry. If no registry
  /// is available, the value must already be a [Uint8List].
  WALEntry createPutEntry(String boxName, dynamic key, dynamic value) {
    final serializedValue = _serializeValue(value);
    return WALEntry(
      boxName: boxName,
      key: key,
      value: serializedValue,
      type: WALEntryType.put,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      sequenceNumber: _nextSequence(),
    );
  }

  /// Creates a [WALEntry] for a delete operation.
  WALEntry createDeleteEntry(String boxName, dynamic key) {
    return WALEntry(
      boxName: boxName,
      key: key,
      value: null,
      type: WALEntryType.delete,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      sequenceNumber: _nextSequence(),
    );
  }

  /// Creates a [WALEntry] for a putAll operation.
  ///
  /// The [kvPairs] map is serialized into a single byte blob.
  WALEntry createPutAllEntry(String boxName, Map<dynamic, dynamic> kvPairs) {
    final serializedValue = _serializeMap(kvPairs);
    return WALEntry(
      boxName: boxName,
      key: null,
      value: serializedValue,
      type: WALEntryType.putAll,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      sequenceNumber: _nextSequence(),
    );
  }

  /// Creates a [WALEntry] for a clear operation.
  WALEntry createClearEntry(String boxName) {
    return WALEntry(
      boxName: boxName,
      key: null,
      value: null,
      type: WALEntryType.clear,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      sequenceNumber: _nextSequence(),
    );
  }

  /// Replays all uncommitted WAL entries after crash recovery.
  ///
  /// This method reads all entries from the WAL file and invokes the
  /// registered replay callbacks for each entry. After all entries have
  /// been successfully replayed, the WAL is truncated.
  ///
  /// Returns the number of entries that were replayed.
  Future<int> recover() async {
    if (!enabled || !_isOpen || _walFile == null) return 0;

    // Set recovering flag to suppress WAL logging during replay
    _recovering = true;
    try {
      final entries = await _walFile!.readAllEntries();
      if (entries.isEmpty) return 0;

      Logger.i('WAL recovery: found ${entries.length} entries to replay.');

      var replayed = 0;
      for (final entry in entries) {
        final callback = _replayCallbacks[entry.boxName];
        if (callback != null) {
          try {
            await callback(entry.boxName, entry);
            replayed++;
          } catch (e) {
            Logger.w(
              'WAL recovery: failed to replay entry for box '
              '"${entry.boxName}": $e',
            );
          }
        } else {
          Logger.w(
            'WAL recovery: no callback registered for box '
            '"${entry.boxName}", skipping entry.',
          );
        }
      }

      Logger.i('WAL recovery: replayed $replayed entries.');

      // After successful recovery, truncate the WAL
      await _walFile!.truncate();

      return replayed;
    } catch (e) {
      Logger.w('WAL recovery failed: $e');
      return 0;
    } finally {
      _recovering = false;
    }
  }

  /// Flushes WAL entries to the main data file and clears the WAL.
  ///
  /// This is called during compaction or checkpoint operations when the
  /// main data file is known to be consistent. After a checkpoint, the
  /// WAL entries are no longer needed for recovery.
  Future<void> checkpoint() async {
    if (!enabled || !_isOpen || _walFile == null) return;

    try {
      await _walFile!.truncate();
      Logger.i('WAL checkpoint: WAL truncated.');
    } catch (e) {
      Logger.w('WAL checkpoint failed: $e');
    }
  }

  /// Closes the WAL.
  ///
  /// The WAL file is flushed and closed. After calling this method, no
  /// further WAL operations can be performed until [open] is called again.
  Future<void> close() async {
    if (!enabled || !_isOpen || _walFile == null) return;

    try {
      await _walFile!.close();
    } catch (e) {
      Logger.w('Failed to close WAL file: $e');
    }

    _walFile = null;
    _isOpen = false;
  }

  /// Purges WAL entries for a specific box.
  ///
  /// This reads all entries, filters out those belonging to [boxName],
  /// and rewrites the remaining entries. This is useful when a box is
  /// deleted from disk.
  Future<void> purgeBox(String boxName) async {
    if (!enabled || !_isOpen || _walFile == null) return;

    try {
      final entries = await _walFile!.readAllEntries();
      final remaining = entries.where((e) => e.boxName != boxName).toList();

      // Truncate and rewrite
      await _walFile!.truncate();
      if (remaining.isNotEmpty) {
        await _walFile!.writeEntries(remaining);
      }

      Logger.i('WAL: purged entries for box "$boxName".');
    } catch (e) {
      Logger.w('WAL purge failed for box "$boxName": $e');
    }
  }

  /// Checks whether a WAL file exists, indicating a potential need for
  /// recovery.
  Future<bool> hasWALFile() async {
    if (!enabled) return false;
    return await File(_walPath).exists();
  }

  /// Returns the next sequence number and increments the counter.
  int _nextSequence() => _sequenceNumber++;

  /// Serializes a value into bytes using the type registry.
  Uint8List? _serializeValue(dynamic value) {
    if (value == null) return null;
    if (value is Uint8List) return value;

    if (_registry != null) {
      try {
        final writer = BinaryWriterImpl(_registry!);
        writer.write(value);
        return writer.toBytes();
      } catch (e) {
        Logger.w('WAL: failed to serialize value: $e');
        return null;
      }
    }

    // Fallback: if the value is already a byte list, convert it
    if (value is List<int>) {
      return Uint8List.fromList(value);
    }

    Logger.w(
      'WAL: cannot serialize value of type ${value.runtimeType} '
      'without a type registry.',
    );
    return null;
  }

  /// Serializes a map of key-value pairs into bytes.
  Uint8List? _serializeMap(Map<dynamic, dynamic> map) {
    if (_registry != null) {
      try {
        final writer = BinaryWriterImpl(_registry!);
        writer.writeMap(map);
        return writer.toBytes();
      } catch (e) {
        Logger.w('WAL: failed to serialize map: $e');
        return null;
      }
    }

    Logger.w('WAL: cannot serialize map without a type registry.');
    return null;
  }
}
