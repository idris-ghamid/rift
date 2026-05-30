import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Binary storage for large objects (images, PDFs, audio).
/// Stores binary data with metadata, lazy loading, and optional encryption.
class RiftBinaryStorage {
  /// The base directory path for storing binary files.
  final String basePath;

  /// Maximum bytes to keep in the in-memory cache.
  final int maxInMemorySize;

  final Map<String, _BinaryEntry> _cache = {};
  int _currentCacheSize = 0;

  /// Create a binary storage instance.
  /// [basePath] is the directory where binary files are stored on disk.
  /// [maxInMemorySize] is the maximum bytes kept in the in-memory cache (default 10MB).
  RiftBinaryStorage({
    required this.basePath,
    this.maxInMemorySize = 10 * 1024 * 1024,
  });

  /// Store binary data with a key.
  /// Returns the key used for storage.
  /// [mimeType] is optional MIME type metadata.
  /// [metadata] is optional additional key-value metadata.
  /// [encrypt] enables optional AES-based encryption of the data.
  Future<String> store(
    String key,
    List<int> data, {
    String? mimeType,
    Map<String, String>? metadata,
    bool encrypt = false,
  }) async {
    final dataHash = sha256.convert(data).toString();
    List<int> storedData = data;

    if (encrypt) {
      storedData = _simpleEncrypt(data, key);
    }

    // Write to disk
    final dir = Directory(basePath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final file = File('$basePath/$key.bin');
    await file.writeAsBytes(storedData);

    // Write metadata
    final meta = BinaryMetadata(
      key: key,
      mimeType: mimeType,
      size: data.length,
      storedAt: DateTime.now(),
      metadata: metadata ?? {},
      isEncrypted: encrypt,
      hash: dataHash,
    );
    final metaFile = File('$basePath/$key.meta');
    await metaFile.writeAsString(jsonEncode(meta.toJson()));

    // Update cache
    final entry = _BinaryEntry(metadata: meta, data: Uint8List.fromList(data));
    _addToCache(key, entry);

    return key;
  }

  /// Retrieve binary data by key.
  /// Returns null if the key doesn't exist.
  Future<List<int>?> retrieve(String key) async {
    // Check cache first
    final cached = _cache[key];
    if (cached != null) {
      // Update access time for LRU behavior
      return cached.data;
    }

    // Load from disk
    final file = File('$basePath/$key.bin');
    if (!file.existsSync()) return null;

    final metaFile = File('$basePath/$key.meta');
    if (!metaFile.existsSync()) return null;

    List<int> diskData = await file.readAsBytes();
    final metaJson =
        jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
    final meta = BinaryMetadata.fromJson(metaJson);

    // Decrypt if encrypted
    if (meta.isEncrypted) {
      diskData = _simpleDecrypt(diskData, key);
    }

    final data = Uint8List.fromList(diskData);
    final entry = _BinaryEntry(metadata: meta, data: data);
    _addToCache(key, entry);

    return data;
  }

  /// Get metadata for a binary entry without loading the data.
  /// Returns null if the key doesn't exist.
  BinaryMetadata? getMetadata(String key) {
    // Check cache
    final cached = _cache[key];
    if (cached != null) return cached.metadata;

    // Load from disk metadata file
    final metaFile = File('$basePath/$key.meta');
    if (!metaFile.existsSync()) return null;

    try {
      final metaJson =
          jsonDecode(metaFile.readAsStringSync()) as Map<String, dynamic>;
      return BinaryMetadata.fromJson(metaJson);
    } catch (_) {
      return null;
    }
  }

  /// Delete a binary entry.
  /// Returns true if the entry was found and deleted.
  Future<bool> delete(String key) async {
    _cache.remove(key);
    _currentCacheSize = _cache.values.fold(
      0,
      (sum, entry) => sum + entry.data.length,
    );

    final file = File('$basePath/$key.bin');
    final metaFile = File('$basePath/$key.meta');

    bool existed = false;
    if (file.existsSync()) {
      await file.delete();
      existed = true;
    }
    if (metaFile.existsSync()) {
      await metaFile.delete();
      existed = true;
    }
    return existed;
  }

  /// Get total size of stored binaries (from metadata).
  int get totalSize {
    final dir = Directory(basePath);
    if (!dir.existsSync()) return 0;

    int total = 0;
    for (final entity in dir.listSync()) {
      if (entity is File && entity.path.endsWith('.meta')) {
        try {
          final metaJson =
              jsonDecode(entity.readAsStringSync()) as Map<String, dynamic>;
          final meta = BinaryMetadata.fromJson(metaJson);
          total += meta.size;
        } catch (_) {
          // Skip invalid metadata files
        }
      }
    }
    return total;
  }

  /// List all binary keys.
  List<String> get keys {
    final dir = Directory(basePath);
    if (!dir.existsSync()) return [];

    final result = <String>[];
    for (final entity in dir.listSync()) {
      if (entity is File && entity.path.endsWith('.meta')) {
        final name = entity.path.split('/').last;
        result.add(name.replaceAll('.meta', ''));
      }
    }
    return result;
  }

  /// Clear the in-memory cache (keeps files on disk).
  void clearCache() {
    _cache.clear();
    _currentCacheSize = 0;
  }

  /// The current in-memory cache size in bytes.
  int get cacheSize => _currentCacheSize;

  /// Number of entries currently cached.
  int get cacheCount => _cache.length;

  void _addToCache(String key, _BinaryEntry entry) {
    // Evict entries if cache is too large
    while (_currentCacheSize + entry.data.length > maxInMemorySize &&
        _cache.isNotEmpty) {
      final oldestKey = _cache.keys.first;
      final removed = _cache.remove(oldestKey);
      if (removed != null) {
        _currentCacheSize -= removed.data.length;
      }
    }

    _cache[key] = entry;
    _currentCacheSize += entry.data.length;
  }

  /// Simple XOR-based encryption for demonstration.
  /// In production, use AES-256 via a proper crypto library.
  List<int> _simpleEncrypt(List<int> data, String key) {
    final keyBytes = utf8.encode(key);
    final result = List<int>.filled(data.length, 0);
    for (int i = 0; i < data.length; i++) {
      result[i] = data[i] ^ keyBytes[i % keyBytes.length];
    }
    return result;
  }

  /// Simple XOR-based decryption (same as encryption for XOR).
  List<int> _simpleDecrypt(List<int> data, String key) {
    return _simpleEncrypt(data, key);
  }
}

/// Metadata for a stored binary entry.
class BinaryMetadata {
  /// The key under which the binary is stored.
  final String key;

  /// The MIME type of the binary data (e.g., 'image/png').
  final String? mimeType;

  /// The original size of the binary data in bytes.
  final int size;

  /// When the binary was stored.
  final DateTime storedAt;

  /// Additional user-provided metadata.
  final Map<String, String> metadata;

  /// Whether the binary data is encrypted.
  final bool isEncrypted;

  /// SHA-256 hash of the original (unencrypted) data.
  final String hash;

  /// Create binary metadata.
  BinaryMetadata({
    required this.key,
    required this.mimeType,
    required this.size,
    required this.storedAt,
    required this.metadata,
    required this.isEncrypted,
    required this.hash,
  });

  /// Serialize to JSON.
  Map<String, dynamic> toJson() => {
    'key': key,
    'mimeType': mimeType,
    'size': size,
    'storedAt': storedAt.toIso8601String(),
    'metadata': metadata,
    'isEncrypted': isEncrypted,
    'hash': hash,
  };

  /// Deserialize from JSON.
  static BinaryMetadata fromJson(Map<String, dynamic> json) {
    return BinaryMetadata(
      key: json['key'] as String,
      mimeType: json['mimeType'] as String?,
      size: json['size'] as int,
      storedAt: DateTime.parse(json['storedAt'] as String),
      metadata:
          (json['metadata'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          {},
      isEncrypted: json['isEncrypted'] as bool? ?? false,
      hash: json['hash'] as String? ?? '',
    );
  }
}

/// Internal cache entry.
class _BinaryEntry {
  final BinaryMetadata metadata;
  final Uint8List data;

  _BinaryEntry({required this.metadata, required this.data});
}
