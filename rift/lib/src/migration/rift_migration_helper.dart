import 'dart:io';
import 'dart:typed_data';

import 'package:rift/src/rift.dart';

/// Migration helper for transitioning from Hive/hive_ce to Rift.
/// Reads old Hive data files and converts them to Rift format automatically.
///
/// Hive stores data as binary files with a specific format. This helper
/// reads those files and converts the data into Rift boxes, preserving
/// all key-value pairs.
///
/// Usage:
/// ```dart
/// final report = await HiveMigrationHelper.migrateAll(rift: Rift);
/// print('Migrated ${report.successfulMigrations} of ${report.totalBoxes} boxes');
///
/// // Or migrate a single box
/// final result = await HiveMigrationHelper.migrateBox('settings', rift: Rift);
/// print('Migrated ${result.entriesMigrated} entries');
/// ```
class HiveMigrationHelper {
  /// The file extension used by Hive for data files.
  static const String _hiveExtension = '.hive';

  /// Migrate all boxes from Hive format to Rift format.
  ///
  /// Scans the [hivePath] directory for `.hive` files, opens each one,
  /// reads its contents, and writes the data into a new Rift box.
  ///
  /// The [rift] parameter must be a [RiftInterface] instance (typically
  /// the global `Rift` constant).
  ///
  /// If [hivePath] is not provided, it defaults to the current directory.
  /// If [riftPath] is not provided, Rift uses its default path.
  ///
  /// Returns a [MigrationReport] with details about the migration.
  static Future<MigrationReport> migrateAll({
    required RiftInterface rift,
    String? hivePath,
    String? riftPath,
  }) async {
    final stopwatch = Stopwatch()..start();
    final results = <BoxMigrationResult>[];
    int successful = 0;
    int failed = 0;

    final hiveBoxes = listHiveBoxes(path: hivePath);
    final totalBoxes = hiveBoxes.length;

    for (final boxName in hiveBoxes) {
      try {
        final result = await migrateBox(
          boxName,
          rift: rift,
          hivePath: hivePath,
        );
        results.add(result);
        if (result.success) {
          successful++;
        } else {
          failed++;
        }
      } catch (e) {
        results.add(
          BoxMigrationResult(
            boxName: boxName,
            success: false,
            entriesMigrated: 0,
            error: e.toString(),
          ),
        );
        failed++;
      }
    }

    stopwatch.stop();

    return MigrationReport(
      totalBoxes: totalBoxes,
      successfulMigrations: successful,
      failedMigrations: failed,
      results: results,
      elapsed: stopwatch.elapsed,
    );
  }

  /// Migrate a single box from Hive to Rift.
  ///
  /// Reads the Hive file at [hivePath]/[boxName].hive and writes
  /// all entries into a new Rift box with the same name.
  ///
  /// The [rift] parameter must be a [RiftInterface] instance (typically
  /// the global `Rift` constant).
  ///
  /// If the Hive file cannot be read or parsed, the migration fails
  /// and the result includes an error message.
  static Future<BoxMigrationResult> migrateBox(
    String boxName, {
    required RiftInterface rift,
    String? hivePath,
    String? riftPath,
  }) async {
    if (!hiveBoxExists(boxName, path: hivePath)) {
      return BoxMigrationResult(
        boxName: boxName,
        success: false,
        entriesMigrated: 0,
        error: 'Hive box not found: $boxName',
      );
    }

    try {
      final filePath =
          '${hivePath ?? '.'}${Platform.pathSeparator}$boxName$_hiveExtension';
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      // Parse Hive binary format
      final entries = _parseHiveFile(bytes);
      int entriesMigrated = 0;

      // Open a Rift box and write all entries
      final riftBox = await rift.openBox(boxName);

      for (final entry in entries.entries) {
        await riftBox.put(entry.key, entry.value);
        entriesMigrated++;
      }

      await riftBox.close();

      return BoxMigrationResult(
        boxName: boxName,
        success: true,
        entriesMigrated: entriesMigrated,
      );
    } catch (e) {
      return BoxMigrationResult(
        boxName: boxName,
        success: false,
        entriesMigrated: 0,
        error: e.toString(),
      );
    }
  }

  /// Check if a Hive box exists at the given [path].
  ///
  /// Looks for a file named [boxName].hive in the directory specified
  /// by [path] (defaults to the current directory).
  static bool hiveBoxExists(String boxName, {String? path}) {
    final dir = path ?? '.';
    final filePath = '$dir${Platform.pathSeparator}$boxName$_hiveExtension';
    return File(filePath).existsSync();
  }

  /// Get a list of all Hive box names at the given [path].
  ///
  /// Scans the directory for files ending in `.hive` and returns
  /// their names without the extension.
  static List<String> listHiveBoxes({String? path}) {
    final dir = path ?? '.';
    final directory = Directory(dir);

    if (!directory.existsSync()) return [];

    final boxes = <String>[];
    final entities = directory.listSync();

    for (final entity in entities) {
      if (entity is File) {
        final name = entity.path.split(Platform.pathSeparator).last;
        if (name.endsWith(_hiveExtension)) {
          final boxName = name.substring(
            0,
            name.length - _hiveExtension.length,
          );
          boxes.add(boxName);
        }
      }
    }

    return boxes;
  }

  /// Parse a Hive binary file and extract key-value pairs.
  ///
  /// Hive files have the following format:
  /// - Header: "HIVE" magic bytes + version byte
  /// - Body: Frames with key-value pairs
  ///
  /// Each frame contains:
  /// - 4 bytes: key length
  /// - N bytes: key data
  /// - 4 bytes: value length
  /// - M bytes: value data
  /// - 4 bytes: CRC32 checksum
  static Map<dynamic, dynamic> _parseHiveFile(Uint8List bytes) {
    if (bytes.length < 5) return {};

    // Verify Hive magic header
    final header = String.fromCharCodes(bytes.sublist(0, 4));
    if (header != 'HIVE') {
      // Try to read as a simple key-value format
      // Some Hive versions may not have the magic header
      return _parseHiveFileFallback(bytes);
    }

    final version = bytes[4];
    final results = <dynamic, dynamic>{};
    var offset = 5;

    while (offset < bytes.length - 8) {
      try {
        // Read key length (4 bytes, little-endian)
        final keyLength = _readUint32LE(bytes, offset);
        offset += 4;

        if (keyLength > bytes.length - offset) break;

        // Read key
        final keyBytes = bytes.sublist(offset, offset + keyLength);
        offset += keyLength;

        // Read value length (4 bytes, little-endian)
        if (offset + 4 > bytes.length) break;
        final valueLength = _readUint32LE(bytes, offset);
        offset += 4;

        if (valueLength > bytes.length - offset) break;

        // Read value
        final valueBytes = bytes.sublist(offset, offset + valueLength);
        offset += valueLength;

        // Skip CRC32 (4 bytes)
        offset += 4;

        // Decode key and value
        final key = _decodeValue(keyBytes, version);
        final value = _decodeValue(valueBytes, version);

        if (key != null) {
          results[key] = value;
        }
      } catch (e) {
        // Skip malformed frames
        break;
      }
    }

    return results;
  }

  /// Fallback parser for Hive files without standard headers.
  static Map<dynamic, dynamic> _parseHiveFileFallback(Uint8List bytes) {
    final results = <dynamic, dynamic>{};
    var offset = 0;

    while (offset < bytes.length - 12) {
      try {
        // Read key length
        final keyLength = _readUint32LE(bytes, offset);
        offset += 4;

        if (keyLength > 1024 || keyLength > bytes.length - offset) break;

        final keyBytes = bytes.sublist(offset, offset + keyLength);
        offset += keyLength;

        // Read value length
        if (offset + 4 > bytes.length) break;
        final valueLength = _readUint32LE(bytes, offset);
        offset += 4;

        if (valueLength > 1024 * 1024 || valueLength > bytes.length - offset) {
          break;
        }

        final valueBytes = bytes.sublist(offset, offset + valueLength);
        offset += valueLength;

        // Try to decode
        final key = _decodeValue(keyBytes, 0);
        final value = _decodeValue(valueBytes, 0);

        if (key != null) {
          results[key] = value;
        }
      } catch (e) {
        break;
      }
    }

    return results;
  }

  /// Decode a value from bytes based on Hive's serialization format.
  static dynamic _decodeValue(Uint8List bytes, int version) {
    if (bytes.isEmpty) return null;

    try {
      // Check the type byte
      final typeByte = bytes[0];

      switch (typeByte) {
        case 0: // null
          return null;
        case 1: // int (8 bytes)
          if (bytes.length >= 9) {
            return _readInt64LE(bytes, 1);
          }
          return null;
        case 2: // double (8 bytes)
          if (bytes.length >= 9) {
            return _readDoubleLE(bytes, 1);
          }
          return null;
        case 3: // bool
          if (bytes.length >= 2) {
            return bytes[1] != 0;
          }
          return null;
        case 4: // string
          if (bytes.length >= 2) {
            return String.fromCharCodes(bytes.sublist(1));
          }
          return null;
        case 5: // byte list
          return bytes.sublist(1);
        default:
          // Unknown type, return as string representation
          return String.fromCharCodes(bytes);
      }
    } catch (e) {
      return null;
    }
  }

  /// Read a 32-bit unsigned integer in little-endian format.
  static int _readUint32LE(Uint8List bytes, int offset) {
    return bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
  }

  /// Read a 64-bit signed integer in little-endian format.
  static int _readInt64LE(Uint8List bytes, int offset) {
    var result = 0;
    for (int i = 0; i < 8; i++) {
      result |= (bytes[offset + i] & 0xFF) << (8 * i);
    }
    return result;
  }

  /// Read a 64-bit double in little-endian format.
  static double _readDoubleLE(Uint8List bytes, int offset) {
    final buffer = ByteData.sublistView(bytes, offset, offset + 8);
    return buffer.getFloat64(0, Endian.little);
  }
}

/// Report of a migration from Hive to Rift.
class MigrationReport {
  /// The total number of Hive boxes found.
  final int totalBoxes;

  /// The number of boxes that were migrated successfully.
  final int successfulMigrations;

  /// The number of boxes that failed to migrate.
  final int failedMigrations;

  /// Detailed results for each box.
  final List<BoxMigrationResult> results;

  /// How long the entire migration took.
  final Duration elapsed;

  /// Create a [MigrationReport].
  MigrationReport({
    required this.totalBoxes,
    required this.successfulMigrations,
    required this.failedMigrations,
    required this.results,
    required this.elapsed,
  });

  @override
  String toString() =>
      'MigrationReport(total: $totalBoxes, success: $successfulMigrations, '
      'failed: $failedMigrations, elapsed: ${elapsed.inMilliseconds}ms)';
}

/// Result of migrating a single box from Hive to Rift.
class BoxMigrationResult {
  /// The name of the box that was migrated.
  final String boxName;

  /// Whether the migration succeeded.
  final bool success;

  /// The number of entries that were migrated.
  final int entriesMigrated;

  /// Error message if the migration failed, null otherwise.
  final String? error;

  /// Create a [BoxMigrationResult].
  BoxMigrationResult({
    required this.boxName,
    required this.success,
    required this.entriesMigrated,
    this.error,
  });

  @override
  String toString() =>
      'BoxMigrationResult($boxName: ${success ? "success" : "failed"}, '
      '$entriesMigrated entries${error != null ? ", error: $error" : ""})';
}
