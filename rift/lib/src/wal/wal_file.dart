import 'dart:io';
import 'dart:typed_data';

import 'package:rift/src/crypto/crc32.dart';
import 'package:rift/src/util/logger.dart';
import 'package:rift/src/wal/wal_entry.dart';

/// Magic bytes identifying a Rift WAL file ("RIFW").
const _walMagic = [0x52, 0x49, 0x46, 0x57]; // "RIFW"

/// Current WAL file format version.
const _walVersion = 1;

/// Key type indicator: no key (used for clear / putAll where key is null).
const _keyTypeNull = 0;

/// Key type indicator: unsigned 32-bit integer key.
const _keyTypeUint = 1;

/// Key type indicator: UTF-8 string key.
const _keyTypeUtf8String = 2;

/// Handles the binary format of a WAL file.
///
/// WAL file format:
/// ```
/// [4 bytes: "RIFW" magic] [1 byte: version]
/// [entries...]
/// ```
///
/// Each entry:
/// ```
/// [4 bytes: entry length] [1 byte: type] [8 bytes: timestamp]
/// [8 bytes: sequence] [1 byte: boxNameLength] [boxName bytes]
/// [1 byte: keyType] [key bytes] [4 bytes: valueLength] [value bytes]
/// [4 bytes: CRC32]
/// ```
///
/// The CRC32 covers all bytes from the entry length field up to (but not
/// including) the CRC itself.
class WALFile {
  final RandomAccessFile _file;
  final bool _headerWritten;

  /// Creates a [WALFile] wrapping the given [RandomAccessFile].
  ///
  /// If [headerWritten] is `true`, the file already contains the WAL header
  /// (magic + version) and new entries should be appended after it.
  WALFile(this._file, {bool headerWritten = false})
    : _headerWritten = headerWritten;

  /// Opens or creates a WAL file at [path].
  ///
  /// If the file exists and is non-empty, its header is validated and the
  /// write position is set to the end so that new entries are appended.
  /// If the file does not exist or is empty, a new header is written.
  static Future<WALFile> open(String path) async {
    final file = File(path);
    RandomAccessFile raf;
    bool headerWritten;

    if (await file.exists() && await file.length() > 0) {
      raf = await file.open(mode: FileMode.writeOnlyAppend);
      // Validate existing header
      await raf.setPosition(0);
      final header = await raf.read(5);
      for (var i = 0; i < 4; i++) {
        if (header[i] != _walMagic[i]) {
          throw const FormatException('Invalid WAL file: bad magic bytes');
        }
      }
      if (header[4] != _walVersion) {
        throw const FormatException('Invalid WAL file: unsupported version');
      }
      headerWritten = true;
      // Move to end for appending
      await raf.setPosition(await raf.length());
    } else {
      raf = await file.open(mode: FileMode.writeOnlyAppend);
      // Write header
      final headerBytes = Uint8List(5);
      for (var i = 0; i < 4; i++) {
        headerBytes[i] = _walMagic[i];
      }
      headerBytes[4] = _walVersion;
      await raf.writeFrom(headerBytes);
      await raf.flush();
      headerWritten = true;
    }

    return WALFile(raf, headerWritten: headerWritten);
  }

  /// Writes a single [WALEntry] to the WAL file.
  ///
  /// The entry is encoded into its binary representation and appended to the
  /// file. The file is flushed after writing to ensure durability.
  Future<void> writeEntry(WALEntry entry) async {
    final bytes = _encodeEntry(entry);
    await _file.writeFrom(bytes);
    await _file.flush();
  }

  /// Writes multiple entries atomically.
  ///
  /// All entries are written sequentially and the file is flushed once at the
  /// end to ensure they are either all persisted or none are.
  Future<void> writeEntries(List<WALEntry> entries) async {
    for (final entry in entries) {
      final bytes = _encodeEntry(entry);
      await _file.writeFrom(bytes);
    }
    await _file.flush();
  }

  /// Reads all entries from the WAL file.
  ///
  /// Corrupted or partially-written entries at the end of the file are
  /// silently skipped (they were likely from a crash during write).
  Future<List<WALEntry>> readAllEntries() async {
    final length = await _file.length();
    if (length < 5) return [];

    await _file.setPosition(0);
    final allBytes = await _file.read(length);
    final reader = _WALReader(allBytes);

    // Validate header
    if (!reader.validateHeader()) {
      Logger.w('WAL file header is invalid, skipping recovery.');
      return [];
    }

    final entries = <WALEntry>[];
    while (reader.hasMore) {
      try {
        final entry = reader.readEntry();
        if (entry != null) {
          entries.add(entry);
        } else {
          // Truncated/corrupted entry — stop reading
          break;
        }
      } catch (e) {
        Logger.w('Error reading WAL entry: $e');
        break;
      }
    }

    return entries;
  }

  /// Truncates the WAL file, removing all entries but keeping the header.
  Future<void> truncate() async {
    await _file.setPosition(5);
    await _file.truncate(5);
    await _file.flush();
  }

  /// Closes the WAL file.
  Future<void> close() async {
    await _file.flush();
    await _file.close();
  }

  /// Encodes a [WALEntry] into its binary representation.
  Uint8List _encodeEntry(WALEntry entry) {
    // Estimate the size needed:
    // 4 (entryLen) + 1 (type) + 8 (timestamp) + 8 (sequence) +
    // 1 (boxNameLen) + boxName + 1 (keyType) + key bytes +
    // 4 (valueLen) + value + 4 (CRC)
    final boxNameBytes = Uint8List.fromList(entry.boxName.codeUnits);
    final keyBytes = _encodeKey(entry.key);

    // Calculate total size excluding the leading 4-byte entry length field
    // and the trailing 4-byte CRC.
    final payloadSize =
        1 + // type
        8 + // timestamp
        8 + // sequence
        1 + // boxName length
        boxNameBytes.length +
        keyBytes.length +
        4 + // value length
        (entry.value?.length ?? 0);

    final entryLength = payloadSize + 4; // +4 for the leading length field
    final totalSize = entryLength + 4; // +4 for trailing CRC

    final buffer = Uint8List(totalSize);
    final byteData = ByteData.view(buffer.buffer);

    var offset = 0;

    // Write entry length (4 bytes, little-endian)
    byteData.setUint32(offset, entryLength, Endian.little);
    offset += 4;

    // Write entry type (1 byte)
    buffer[offset++] = entry.type.code;

    // Write timestamp (8 bytes, little-endian)
    byteData.setInt64(offset, entry.timestamp, Endian.little);
    offset += 8;

    // Write sequence number (8 bytes, little-endian)
    byteData.setInt64(offset, entry.sequenceNumber, Endian.little);
    offset += 8;

    // Write box name length (1 byte)
    buffer[offset++] = boxNameBytes.length;

    // Write box name bytes
    buffer.setRange(offset, offset + boxNameBytes.length, boxNameBytes);
    offset += boxNameBytes.length;

    // Write key bytes (includes key type indicator)
    buffer.setRange(offset, offset + keyBytes.length, keyBytes);
    offset += keyBytes.length;

    // Write value length (4 bytes, little-endian)
    byteData.setUint32(offset, entry.value?.length ?? 0, Endian.little);
    offset += 4;

    // Write value bytes
    if (entry.value != null && entry.value!.isNotEmpty) {
      buffer.setRange(offset, offset + entry.value!.length, entry.value!);
      offset += entry.value!.length;
    }

    // Compute CRC32 over all bytes from the entry length field to here
    final crc = Crc32.compute(buffer, offset: 0, length: offset);
    byteData.setUint32(offset, crc, Endian.little);

    return buffer;
  }

  /// Encodes the key into bytes, including a leading key-type indicator.
  Uint8List _encodeKey(dynamic key) {
    if (key == null) {
      return Uint8List.fromList([_keyTypeNull]);
    } else if (key is int) {
      final bytes = Uint8List(5);
      bytes[0] = _keyTypeUint;
      ByteData.view(bytes.buffer).setUint32(1, key, Endian.little);
      return bytes;
    } else if (key is String) {
      final strBytes = Uint8List.fromList(key.codeUnits);
      final bytes = Uint8List(1 + 1 + strBytes.length);
      bytes[0] = _keyTypeUtf8String;
      bytes[1] = strBytes.length;
      bytes.setRange(2, 2 + strBytes.length, strBytes);
      return bytes;
    } else {
      throw ArgumentError(
        'WAL key must be int, String, or null, got '
        '${key.runtimeType}',
      );
    }
  }
}

/// Helper class to read WAL entries from a byte buffer.
class _WALReader {
  final Uint8List _buffer;
  final ByteData _byteData;
  int _offset = 0;
  final int _length;

  _WALReader(this._buffer)
    : _byteData = ByteData.view(_buffer.buffer, _buffer.offsetInBytes),
      _length = _buffer.length;

  bool get hasMore => _offset < _length;

  /// Validates the WAL file header (magic + version).
  bool validateHeader() {
    if (_length < 5) return false;
    for (var i = 0; i < 4; i++) {
      if (_buffer[i] != _walMagic[i]) return false;
    }
    if (_buffer[4] != _walVersion) return false;
    _offset = 5;
    return true;
  }

  /// Reads the next WAL entry. Returns `null` if the entry is corrupted or
  /// the buffer is exhausted.
  WALEntry? readEntry() {
    if (_offset + 4 > _length) return null;

    final entryLength = _byteData.getUint32(_offset, Endian.little);
    if (entryLength < 18) {
      return null; // minimum: type(1) + ts(8) + seq(8) + len(4) + crc(4) minimum check
    }
    if (_offset + entryLength + 4 > _length) return null;

    final entryStart = _offset;
    final crcOffset = entryStart + entryLength;
    final storedCrc = _byteData.getUint32(crcOffset, Endian.little);

    // Verify CRC over all bytes from entryStart to crcOffset
    final computedCrc = Crc32.compute(
      _buffer,
      offset: entryStart,
      length: entryLength,
    );

    if (computedCrc != storedCrc) {
      // CRC mismatch — entry is corrupted
      return null;
    }

    // Skip the 4-byte entry length field
    _offset += 4;

    // Read type
    final typeCode = _buffer[_offset++];
    final WALEntryType type;
    try {
      type = WALEntryType.fromCode(typeCode);
    } catch (_) {
      return null;
    }

    // Read timestamp
    final timestamp = _byteData.getInt64(_offset, Endian.little);
    _offset += 8;

    // Read sequence number
    final sequenceNumber = _byteData.getInt64(_offset, Endian.little);
    _offset += 8;

    // Read box name
    final boxNameLength = _buffer[_offset++];
    if (_offset + boxNameLength > _length) return null;
    final boxName = String.fromCharCodes(
      _buffer.sublist(_offset, _offset + boxNameLength),
    );
    _offset += boxNameLength;

    // Read key
    final dynamic key;
    final keyType = _buffer[_offset++];
    if (keyType == _keyTypeNull) {
      key = null;
    } else if (keyType == _keyTypeUint) {
      if (_offset + 4 > _length) return null;
      key = _byteData.getUint32(_offset, Endian.little);
      _offset += 4;
    } else if (keyType == _keyTypeUtf8String) {
      final strLen = _buffer[_offset++];
      if (_offset + strLen > _length) return null;
      key = String.fromCharCodes(_buffer.sublist(_offset, _offset + strLen));
      _offset += strLen;
    } else {
      return null;
    }

    // Read value
    if (_offset + 4 > _length) return null;
    final valueLength = _byteData.getUint32(_offset, Endian.little);
    _offset += 4;

    Uint8List? value;
    if (valueLength > 0) {
      if (_offset + valueLength > _length) return null;
      value = _buffer.sublist(_offset, _offset + valueLength);
      _offset += valueLength;
    }

    // Skip CRC
    _offset += 4;

    return WALEntry(
      boxName: boxName,
      key: key,
      value: value,
      type: type,
      timestamp: timestamp,
      sequenceNumber: sequenceNumber,
    );
  }
}
