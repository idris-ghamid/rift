import 'dart:typed_data';

/// RIFT file header structure for database files.
///
/// The header is written when a new database file is created and verified
/// when opening an existing file. Legacy files (without a header) are
/// detected and the header is added on next compaction.
///
/// Layout:
/// ```
/// [4 bytes: "RIFT" magic bytes] [1 byte: format version] [4 bytes: flags] [8 bytes: creation timestamp]
/// ```
class FileHeader {
  /// Magic bytes identifying a RIFT database file: "RIFT" = 0x52494654
  static const int magicByte0 = 0x52; // 'R'
  static const int magicByte1 = 0x49; // 'I'
  static const int magicByte2 = 0x46; // 'F'
  static const int magicByte3 = 0x54; // 'T'

  /// Total header size in bytes: 4 (magic) + 1 (version) + 4 (flags) + 8 (timestamp) = 17
  static const int headerSize = 17;

  /// Current format version
  static const int currentVersion = 1;

  /// Flag indicating the file uses varint-encoded integers
  static const int flagVarintInts = 1;

  /// The format version of this header
  final int version;

  /// Bitmask of feature flags
  final int flags;

  /// Creation timestamp in milliseconds since epoch
  final int creationTimestamp;

  /// Whether this file was detected as a legacy file (no header)
  final bool isLegacy;

  /// Create a new file header with the current version and specified flags.
  FileHeader({
    this.version = currentVersion,
    this.flags = flagVarintInts,
    int? creationTimestamp,
    this.isLegacy = false,
  }) : creationTimestamp =
           creationTimestamp ?? DateTime.now().millisecondsSinceEpoch;

  /// Create a FileHeader representing a legacy file (no header present).
  const FileHeader.legacy()
    : version = 0,
      flags = 0,
      creationTimestamp = 0,
      isLegacy = true;

  /// Whether the varint integer encoding flag is set
  bool get usesVarintInts => (flags & flagVarintInts) != 0;

  /// Encode this header to bytes.
  Uint8List toBytes() {
    final bytes = Uint8List(headerSize);
    final byteData = ByteData.view(bytes.buffer);

    // Magic bytes: "RIFT"
    bytes[0] = magicByte0;
    bytes[1] = magicByte1;
    bytes[2] = magicByte2;
    bytes[3] = magicByte3;

    // Version (1 byte)
    bytes[4] = version;

    // Flags (4 bytes, little-endian)
    byteData.setUint32(5, flags, Endian.little);

    // Creation timestamp (8 bytes, little-endian)
    byteData.setInt64(9, creationTimestamp, Endian.little);

    return bytes;
  }

  /// Try to parse a FileHeader from the beginning of a byte buffer.
  ///
  /// Returns `null` if the buffer doesn't contain a valid RIFT header
  /// (i.e., it's a legacy file or the buffer is too small).
  static FileHeader? fromBytes(Uint8List bytes) {
    if (bytes.length < headerSize) {
      return null;
    }

    // Check magic bytes
    if (bytes[0] != magicByte0 ||
        bytes[1] != magicByte1 ||
        bytes[2] != magicByte2 ||
        bytes[3] != magicByte3) {
      return null;
    }

    final byteData = ByteData.view(
      bytes.buffer,
      bytes.offsetInBytes,
      bytes.length,
    );

    final version = bytes[4];
    final flags = byteData.getUint32(5, Endian.little);
    final creationTimestamp = byteData.getInt64(9, Endian.little);

    return FileHeader(
      version: version,
      flags: flags,
      creationTimestamp: creationTimestamp,
      isLegacy: false,
    );
  }

  /// Check if a byte buffer starts with the RIFT magic bytes.
  static bool hasRiftMagic(Uint8List bytes) {
    if (bytes.length < 4) return false;
    return bytes[0] == magicByte0 &&
        bytes[1] == magicByte1 &&
        bytes[2] == magicByte2 &&
        bytes[3] == magicByte3;
  }

  @override
  String toString() {
    if (isLegacy) {
      return 'FileHeader(legacy file, no header)';
    }
    return 'FileHeader(version: $version, flags: $flags, '
        'creationTimestamp: $creationTimestamp, '
        'usesVarintInts: $usesVarintInts)';
  }

  @override
  bool operator ==(Object other) {
    if (other is! FileHeader) return false;
    if (isLegacy && other.isLegacy) return true;
    return version == other.version &&
        flags == other.flags &&
        creationTimestamp == other.creationTimestamp &&
        isLegacy == other.isLegacy;
  }

  @override
  int get hashCode => Object.hash(version, flags, creationTimestamp, isLegacy);
}
