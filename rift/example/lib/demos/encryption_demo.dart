import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class EncryptionDemoPage extends StatelessWidget {
  const EncryptionDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Encryption',
      description:
          'Enhanced encryption with PBKDF2 key derivation and AES-256-CBC',
      codeExample:
          "final cipher = RiftEnhancedCipher(password: 'secret');\nawait Rift.openBox('secrets',\n    encryptionCipher: cipher);",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Enhanced Encryption Demo ===\n');

        final cipher = RiftEnhancedCipher(
          password: 'my-secret-password',
          iterations: 1000,
        );

        buf.writeln('Cipher: RiftEnhancedCipher');
        buf.writeln('  Password: "my-secret-password"');
        buf.writeln('  PBKDF2 iterations: 1000');
        buf.writeln('  Key CRC: ${cipher.calculateKeyCrc()}\n');

        final plaintext = Uint8List.fromList(
            'Hello, Rift! This is sensitive data.'.codeUnits);
        buf.writeln('--- Encryption ---');
        buf.writeln('  Plaintext: ${String.fromCharCodes(plaintext)}');
        buf.writeln('  Plaintext bytes: ${plaintext.length}');

        final maxLen = cipher.maxEncryptedSize(plaintext);
        final encrypted = Uint8List(maxLen);
        final encLen =
            cipher.encrypt(plaintext, 0, plaintext.length, encrypted, 0);
        buf.writeln('  Encrypted length: $encLen bytes');
        buf.writeln('  Format: [version][salt][IV][ciphertext][HMAC]');

        buf.writeln('\n--- Decryption ---');
        final decrypted = Uint8List(plaintext.length + 16);
        final decLen = cipher.decrypt(encrypted, 0, encLen, decrypted, 0);
        final result = String.fromCharCodes(decrypted.sublist(0, decLen));
        buf.writeln('  Decrypted: $result');
        buf.writeln('  Match: ${result == String.fromCharCodes(plaintext)}');

        buf.writeln('\n--- Encrypted Box ---');
        final encBox = await Rift.openBox<Map>(
          'encrypted_demo',
          encryptionCipher: RiftEnhancedCipher(password: 'box-password'),
        );
        await encBox.clear();
        await encBox.put('secret', {'data': 'Classified info', 'level': 5});
        buf.writeln('  Stored: ${encBox.get('secret')}');
        buf.writeln('  Data is encrypted at rest with AES-256-CBC + HMAC');

        buf.writeln('\n--- Tamper Detection ---');
        buf.writeln('  HMAC-SHA256 verifies data integrity');
        buf.writeln('  Constant-time comparison prevents timing attacks');
        buf.writeln('  Tampered data will throw StateError on decrypt');

        await encBox.close();
        return buf.toString();
      },
    );
  }
}
