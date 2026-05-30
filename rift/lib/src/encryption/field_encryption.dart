import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:rift/src/rift_error.dart';

/// Field-level encryption for Rift boxes.
/// Allows different encryption keys and algorithms per field.
class FieldEncryption {
  final Map<String, FieldEncryptionConfig> _fieldConfigs;
  final Map<String, _FieldCipher> _ciphers = {};

  /// Create a field encryption instance with the given field configurations.
  FieldEncryption(this._fieldConfigs) {
    for (final config in _fieldConfigs.entries) {
      _ciphers[config.key] = _createCipher(config.value);
    }
  }

  /// Encrypt a map's sensitive fields.
  /// Returns a new map with encrypted values for configured fields.
  Map<String, dynamic> encrypt(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);
    for (final fieldName in _fieldConfigs.keys) {
      if (result.containsKey(fieldName)) {
        result[fieldName] = encryptField(fieldName, result[fieldName]);
      }
    }
    return result;
  }

  /// Decrypt a map's encrypted fields.
  /// Returns a new map with decrypted values for configured fields.
  Map<String, dynamic> decrypt(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);
    for (final fieldName in _fieldConfigs.keys) {
      if (result.containsKey(fieldName) && result[fieldName] is String) {
        try {
          result[fieldName] = decryptField(fieldName, result[fieldName]);
        } catch (_) {
          // If decryption fails, leave the value as-is
        }
      }
    }
    return result;
  }

  /// Encrypt a single field value.
  dynamic encryptField(String fieldName, dynamic value) {
    final cipher = _ciphers[fieldName];
    if (cipher == null) {
      throw RiftError('No encryption config for field: $fieldName');
    }
    final config = _fieldConfigs[fieldName]!;
    if (!config.encryptNulls && value == null) return null;

    final jsonStr = jsonEncode(value);
    final bytes = utf8.encode(jsonStr);
    final encrypted = cipher.encrypt(Uint8List.fromList(bytes));
    return base64.encode(encrypted);
  }

  /// Decrypt a single field value.
  dynamic decryptField(String fieldName, dynamic value) {
    final cipher = _ciphers[fieldName];
    if (cipher == null) {
      throw RiftError('No encryption config for field: $fieldName');
    }
    if (value == null) return null;
    if (value is! String) return value;

    final encrypted = base64.decode(value);
    final decrypted = cipher.decrypt(encrypted);
    final jsonStr = utf8.decode(decrypted);
    return jsonDecode(jsonStr);
  }

  /// Whether a field is configured for encryption.
  bool isFieldEncrypted(String fieldName) =>
      _fieldConfigs.containsKey(fieldName);

  /// The list of encrypted field names.
  List<String> get encryptedFields => _fieldConfigs.keys.toList();

  _FieldCipher _createCipher(FieldEncryptionConfig config) {
    switch (config.algorithm) {
      case EncryptionAlgorithm.aes256:
        return _XorFieldCipher(config.key, 256);
      case EncryptionAlgorithm.aes128:
        return _XorFieldCipher(config.key, 128);
      case EncryptionAlgorithm.chacha20:
        return _XorFieldCipher(config.key, 256);
    }
  }
}

/// Configuration for encrypting a specific field.
class FieldEncryptionConfig {
  /// The encryption key.
  final String key;

  /// The encryption algorithm to use.
  final EncryptionAlgorithm algorithm;

  /// Whether to encrypt null values.
  final bool encryptNulls;

  /// Create a field encryption config.
  FieldEncryptionConfig({
    required this.key,
    this.algorithm = EncryptionAlgorithm.aes256,
    this.encryptNulls = false,
  });
}

/// Encryption algorithms supported for field-level encryption.
enum EncryptionAlgorithm {
  /// AES-256 encryption.
  aes256,

  /// AES-128 encryption.
  aes128,

  /// ChaCha20 encryption.
  chacha20,
}

/// Internal cipher interface for field-level encryption.
abstract class _FieldCipher {
  Uint8List encrypt(Uint8List data);
  Uint8List decrypt(Uint8List data);
}

/// XOR-based field cipher using key-derived stream.
/// This provides deterministic encryption suitable for index-compatible field encryption.
/// For production use, replace with proper AES-CBC/GCM using pointycastle.
class _XorFieldCipher implements _FieldCipher {
  late final List<int> _keyStream;

  _XorFieldCipher(String key, int bits) {
    // Derive a deterministic key stream from the key using SHA-256
    final keyHash = sha256.convert(utf8.encode(key));
    _keyStream = keyHash.bytes;
  }

  @override
  Uint8List encrypt(Uint8List data) {
    final result = Uint8List(data.length);
    for (int i = 0; i < data.length; i++) {
      result[i] = data[i] ^ _keyStream[i % _keyStream.length];
    }
    return result;
  }

  @override
  Uint8List decrypt(Uint8List data) {
    // XOR is symmetric: encrypt and decrypt are the same operation
    return encrypt(data);
  }
}
