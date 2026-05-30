import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class FieldEncryptionDemoPage extends StatelessWidget {
  const FieldEncryptionDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Field Encryption',
      description: 'Per-field encryption with different keys and algorithms',
      codeExample:
          "final enc = FieldEncryption({\n  'ssn': FieldEncryptionConfig(key: 'secret', algorithm: EncryptionAlgorithm.aes256),\n});\nfinal encrypted = enc.encrypt(data);",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Field-Level Encryption Demo ===\n');

        // Create field encryption
        final fieldEnc = FieldEncryption({
          'ssn': FieldEncryptionConfig(
              key: 'ssn-secret-key', algorithm: EncryptionAlgorithm.aes256),
          'creditCard': FieldEncryptionConfig(
              key: 'cc-secret-key', algorithm: EncryptionAlgorithm.chacha20),
          'email': FieldEncryptionConfig(
              key: 'email-key', algorithm: EncryptionAlgorithm.aes128),
        });

        buf.writeln('Encrypted fields: ${fieldEnc.encryptedFields}');
        buf.writeln('  ssn → AES-256');
        buf.writeln('  creditCard → ChaCha20');
        buf.writeln('  email → AES-128\n');

        // Original data
        final original = {
          'name': 'Alice Johnson',
          'ssn': '123-45-6789',
          'creditCard': '4111-1111-1111-1111',
          'email': 'alice@example.com',
          'age': 30,
        };
        buf.writeln('--- Original Data ---');
        buf.writeln('  $original');

        // Encrypt
        buf.writeln('\n--- Encrypted Data ---');
        final encrypted = fieldEnc.encrypt(Map<String, dynamic>.from(original));
        for (final e in encrypted.entries) {
          final val = e.value;
          if (val is String && val.length > 30) {
            buf.writeln('  ${e.key}: ${val.substring(0, 30)}… (encrypted)');
          } else {
            buf.writeln('  ${e.key}: $val');
          }
        }

        // Decrypt
        buf.writeln('\n--- Decrypted Data ---');
        final decrypted = fieldEnc.decrypt(encrypted);
        for (final e in decrypted.entries) {
          buf.writeln('  ${e.key}: ${e.value}');
        }

        // Verify
        buf.writeln('\n--- Verification ---');
        buf.writeln('  SSN match: ${decrypted['ssn'] == original['ssn']}');
        buf.writeln(
            '  CC match: ${decrypted['creditCard'] == original['creditCard']}');
        buf.writeln(
            '  Email match: ${decrypted['email'] == original['email']}');
        buf.writeln(
            '  Name unchanged: ${decrypted['name'] == original['name']}');
        buf.writeln('  Age unchanged: ${decrypted['age'] == original['age']}');

        // Single field operations
        buf.writeln('\n--- Single Field Operations ---');
        final encSSN = fieldEnc.encryptField('ssn', '999-99-9999');
        buf.writeln('  Encrypted SSN: ${encSSN.toString().substring(0, 30)}…');
        final decSSN = fieldEnc.decryptField('ssn', encSSN);
        buf.writeln('  Decrypted SSN: $decSSN');

        // Check
        buf.writeln('\n--- Field Check ---');
        buf.writeln(
            '  isFieldEncrypted("ssn"): ${fieldEnc.isFieldEncrypted("ssn")}');
        buf.writeln(
            '  isFieldEncrypted("name"): ${fieldEnc.isFieldEncrypted("name")}');

        return buf.toString();
      },
    );
  }
}
