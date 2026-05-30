import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class MaskingDemoPage extends StatelessWidget {
  const MaskingDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Data Masking',
      description: 'Mask sensitive data with different strategies',
      codeExample:
          "final masker = DataMasker();\nmasker.creditCard('4111111111111234'); // ****1234\nmasker.email('idris@gmail.com');   // i***@gmail.com",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Data Masking Demo ===\n');

        final masker = DataMasker();

        // Credit Card
        buf.writeln('--- Credit Card ---');
        const cc = '4111111111111234';
        buf.writeln('  Input:  $cc');
        buf.writeln('  Masked: ${masker.creditCard(cc)}');

        // Email
        buf.writeln('\n--- Email ---');
        const email = 'idris@gmail.com';
        buf.writeln('  Input:  $email');
        buf.writeln('  Masked: ${masker.email(email)}');

        // Phone
        buf.writeln('\n--- Phone ---');
        const phone = '+1-555-123-4567';
        buf.writeln('  Input:  $phone');
        buf.writeln('  Masked: ${masker.phone(phone)}');

        // SSN
        buf.writeln('\n--- SSN ---');
        const ssn = '123-45-6789';
        buf.writeln('  Input:  $ssn');
        buf.writeln('  Masked: ${masker.ssn(ssn)}');

        // Name
        buf.writeln('\n--- Name ---');
        const name = 'Idris Ghamid';
        buf.writeln('  Input:  $name');
        buf.writeln('  Masked: ${masker.name(name)}');

        // Masking Strategies
        buf.writeln('\n--- Masking Strategies ---');
        const sample = 'SensitiveData';
        for (final strategy in MaskingStrategy.values) {
          final rule = MaskingRule(
            strategy: strategy,
            revealStart: 2,
            revealEnd: 2,
          );
          buf.writeln('  ${strategy.name.padRight(8)}: ${rule.apply(sample)}');
        }

        // Custom rule
        buf.writeln('\n--- Custom Rule ---');
        masker.registerRule(
            'productCode',
            MaskingRule(
              strategy: MaskingStrategy.partial,
              revealStart: 2,
              revealEnd: 2,
            ));
        buf.writeln(
            '  "PRD-12345" → ${masker.applyRule('productCode', 'PRD-12345')}');

        // Auto-mask map
        buf.writeln('\n--- Auto-mask Map ---');
        final data = {
          'creditCard': '4111111111111234',
          'email': 'user@example.com',
          'phone': '+1-555-123-4567',
          'ssn': '123-45-6789',
          'password': 's3cr3t!',
          'name': 'Idris',
        };
        final masked = masker.maskMap(data);
        for (final entry in masked.entries) {
          buf.writeln('  ${entry.key}: ${entry.value}');
        }

        buf.writeln('\n  Registered rules: ${masker.ruleNames.toList()}');

        return buf.toString();
      },
    );
  }
}
