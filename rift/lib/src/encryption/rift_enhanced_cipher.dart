import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:rift/src/crypto/aes_cbc_pkcs7.dart';
import 'package:rift/src/crypto/crc32.dart';
import 'package:rift/src/crypto/rift_cipher.dart';
import 'package:rift/src/util/extensions.dart';

/// Enhanced encryption cipher with modern security features.
///
/// Provides:
/// - **PBKDF2 key derivation** (100,000 iterations by default) to derive
///   a strong 256-bit key from a password, making brute-force attacks
///   computationally expensive.
/// - **HMAC-SHA256 tamper detection** — every encrypted blob carries an
///   authentication tag so corrupted or tampered data is rejected before
///   decryption.
/// - **Per-entry IV** (initialization vector) for semantic security —
///   identical plaintexts produce different ciphertexts.
/// - **Salt** stored alongside the ciphertext so the same password can
///   produce different derived keys across boxes/sessions.
///
/// Usage:
/// ```dart
/// final cipher = RiftEnhancedCipher(password: 'my-secret-password');
/// await rift.openBox('secrets', encryptionCipher: cipher);
///
/// // Field-level encryption
/// await rift.openBox('users', fieldEncryption: {
///   'ssn': RiftEnhancedCipher(password: 'stronger-password'),
///   'creditCard': RiftEnhancedCipher(password: 'another-password'),
/// });
/// ```
///
/// Wire format (encrypted output):
/// ```
/// [1 byte: version] [16 bytes: salt] [16 bytes: IV]
/// [N bytes: AES-CBC ciphertext + PKCS7 padding]
/// [32 bytes: HMAC-SHA256 over everything above]
/// ```
class RiftEnhancedCipher extends RiftCipher {
  /// The password from which the encryption key is derived via PBKDF2.
  final String password;

  /// Number of PBKDF2 iterations. Higher = more secure but slower key derivation.
  /// Default is 100,000 which is the current OWASP recommendation.
  final int iterations;

  /// Cipher format version byte.
  static const int _version = 0x01;

  /// Salt length in bytes.
  static const int _saltLength = 16;

  /// IV length in bytes (AES block size).
  static const int _ivLength = 16;

  /// HMAC-SHA256 output length in bytes.
  static const int _hmacLength = 32;

  /// AES key length in bytes (256-bit).
  static const int _keyLength = 32;

  static final _secureRandom = Random.secure();

  late final int _keyCrc;

  /// Creates an enhanced cipher that derives a 256-bit AES key from
  /// [password] using PBKDF2 with [iterations] rounds.
  RiftEnhancedCipher({required this.password, this.iterations = 100000}) {
    // Compute a stable CRC of the password for key identity checks.
    // This mirrors how RiftAesCipher uses keyCrc to detect wrong-key access.
    final pwBytes = Uint8List.fromList(password.codeUnits);
    _keyCrc = Crc32.compute(sha256.convert(pwBytes).bytes as Uint8List);
  }

  @override
  int calculateKeyCrc() => _keyCrc;

  @override
  int maxEncryptedSize(Uint8List inp) {
    // version(1) + salt(16) + iv(16) + ciphertext(inp.len padded to 16) + hmac(32)
    final paddedLen = ((inp.length + 16) ~/ 16) * 16;
    return 1 + _saltLength + _ivLength + paddedLen + _hmacLength;
  }

  @override
  int encrypt(
    Uint8List inp,
    int inpOff,
    int inpLength,
    Uint8List out,
    int outOff,
  ) {
    // 1. Generate random salt and IV
    final salt = _secureRandom.nextBytes(_saltLength);
    final iv = _secureRandom.nextBytes(_ivLength);

    // 2. Derive key from password + salt using PBKDF2
    final key = _deriveKey(password, salt, iterations, _keyLength);

    // 3. Encrypt with AES-256-CBC
    final cipher = AesCbcPkcs7(key);
    final plainText = Uint8List.sublistView(inp, inpOff, inpOff + inpLength);
    final cipherText = Uint8List(inpLength + 16); // max padded size
    final cipherLen = cipher.encrypt(
      iv,
      plainText,
      0,
      inpLength,
      cipherText,
      0,
    );

    // 4. Build output: version | salt | iv | ciphertext
    var pos = outOff;
    out[pos++] = _version;
    out.setRange(pos, pos + _saltLength, salt);
    pos += _saltLength;
    out.setRange(pos, pos + _ivLength, iv);
    pos += _ivLength;
    out.setRange(pos, pos + cipherLen, cipherText);
    pos += cipherLen;

    // 5. Compute HMAC-SHA256 over everything so far
    final authData = Uint8List.sublistView(out, outOff, pos);
    final hmac = _computeHmac(key, authData);

    // 6. Append HMAC
    out.setRange(pos, pos + _hmacLength, hmac.bytes);
    pos += _hmacLength;

    return pos - outOff;
  }

  @override
  int decrypt(
    Uint8List inp,
    int inpOff,
    int inpLength,
    Uint8List out,
    int outOff,
  ) {
    var pos = inpOff;

    // 1. Read version
    final version = inp[pos++];
    if (version != _version) {
      throw StateError('RiftEnhancedCipher: unsupported version $version');
    }

    // 2. Read salt
    final salt = Uint8List(_saltLength);
    salt.setRange(0, _saltLength, inp, pos);
    pos += _saltLength;

    // 3. Read IV
    final iv = Uint8List(_ivLength);
    iv.setRange(0, _ivLength, inp, pos);
    pos += _ivLength;

    // 4. Derive key from password + salt
    final key = _deriveKey(password, salt, iterations, _keyLength);

    // 5. Verify HMAC before decryption (encrypt-then-MAC)
    final authDataLen = inpLength - _hmacLength;
    final authData = Uint8List.sublistView(inp, inpOff, inpOff + authDataLen);
    final storedHmac = Uint8List.sublistView(
      inp,
      inpOff + authDataLen,
      inpOff + inpLength,
    );
    final computedHmac = _computeHmac(key, authData);

    // Constant-time comparison to prevent timing attacks
    if (!_constantTimeEquals(storedHmac, computedHmac.bytes)) {
      throw StateError(
        'RiftEnhancedCipher: HMAC verification failed — '
        'data may be corrupted or tampered with',
      );
    }

    // 6. Decrypt ciphertext
    final cipherTextLen = authDataLen - 1 - _saltLength - _ivLength;
    final cipher = AesCbcPkcs7(key);
    final decryptedLen = cipher.decrypt(
      iv,
      inp,
      inpOff + 1 + _saltLength + _ivLength,
      cipherTextLen,
      out,
      outOff,
    );

    return decryptedLen;
  }

  /// Derives a cryptographic key from [password] using PBKDF2-HMAC-SHA256.
  ///
  /// This is a pure-Dart implementation that uses the `crypto` package's
  /// HMAC-SHA256 primitive. It follows RFC 2898.
  static Uint8List _deriveKey(
    String password,
    Uint8List salt,
    int iterations,
    int keyLength,
  ) {
    final pwBytes = Uint8List.fromList(utf8.encode(password));
    final blocksNeeded = (keyLength + 31) ~/ 32; // SHA-256 outputs 32 bytes
    final derivedKey = Uint8List(blocksNeeded * 32);

    for (var blockIndex = 1; blockIndex <= blocksNeeded; blockIndex++) {
      // U1 = HMAC(password, salt || INT_32_BE(blockIndex))
      final saltWithIndex = Uint8List(salt.length + 4);
      saltWithIndex.setRange(0, salt.length, salt);
      saltWithIndex[salt.length] = (blockIndex >> 24) & 0xFF;
      saltWithIndex[salt.length + 1] = (blockIndex >> 16) & 0xFF;
      saltWithIndex[salt.length + 2] = (blockIndex >> 8) & 0xFF;
      saltWithIndex[salt.length + 3] = blockIndex & 0xFF;

      final hmac = Hmac(sha256, pwBytes);
      var u = hmac.convert(saltWithIndex);
      var result = Uint8List.fromList(u.bytes);

      // U2 ... Uc
      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u.bytes);
        for (var j = 0; j < 32; j++) {
          result[j] ^= u.bytes[j];
        }
      }

      derivedKey.setRange(
        (blockIndex - 1) * 32,
        (blockIndex - 1) * 32 + 32,
        result,
      );
    }

    return Uint8List.sublistView(derivedKey, 0, keyLength);
  }

  /// Compute HMAC-SHA256 of [data] using [key].
  static Digest _computeHmac(Uint8List key, Uint8List data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(data);
  }

  /// Constant-time byte array comparison to prevent timing attacks.
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
