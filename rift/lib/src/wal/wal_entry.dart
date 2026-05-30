import 'dart:typed_data';

/// The type of operation recorded in a WAL entry.
enum WALEntryType {
  /// A single key-value put operation.
  put(0),

  /// A single key delete operation.
  delete(1),

  /// A batch put of multiple key-value pairs.
  putAll(2),

  /// A clear operation that removes all entries from a box.
  clear(3);

  const WALEntryType(this.code);

  /// The binary code used to identify this entry type in the WAL file.
  final int code;

  /// Returns the [WALEntryType] corresponding to the given [code].
  ///
  /// Throws [RangeError] if the code does not map to a valid entry type.
  static WALEntryType fromCode(int code) {
    switch (code) {
      case 0:
        return WALEntryType.put;
      case 1:
        return WALEntryType.delete;
      case 2:
        return WALEntryType.putAll;
      case 3:
        return WALEntryType.clear;
      default:
        throw RangeError('Unknown WALEntryType code: $code');
    }
  }
}

/// A single entry in the Write-Ahead Log.
///
/// Each entry records a mutation (put, delete, putAll, or clear) that was
/// intended to be applied to a box. If the application crashes before the
/// mutation is durably written to the main data file, the WAL entry can be
/// replayed during recovery to restore consistency.
class WALEntry {
  /// The name of the box this entry belongs to.
  final String boxName;

  /// The key affected by this entry.
  ///
  /// For [WALEntryType.clear], this is `null`.
  /// For [WALEntryType.putAll], this is `null` (keys are encoded in [value]).
  final dynamic key;

  /// The value associated with this entry.
  ///
  /// - For [WALEntryType.put]: the serialized value bytes.
  /// - For [WALEntryType.delete]: `null`.
  /// - For [WALEntryType.putAll]: the serialized map of key-value pairs.
  /// - For [WALEntryType.clear]: `null`.
  final Uint8List? value;

  /// The type of operation this entry represents.
  final WALEntryType type;

  /// The timestamp when this entry was created, in milliseconds since epoch.
  final int timestamp;

  /// A monotonically increasing sequence number that establishes the order
  /// of WAL entries across the entire database.
  final int sequenceNumber;

  /// Creates a new WAL entry.
  WALEntry({
    required this.boxName,
    this.key,
    this.value,
    required this.type,
    required this.timestamp,
    required this.sequenceNumber,
  });

  @override
  String toString() {
    return 'WALEntry(boxName: $boxName, key: $key, type: $type, '
        'timestamp: $timestamp, sequence: $sequenceNumber, '
        'valueLength: ${value?.length ?? 0})';
  }
}
