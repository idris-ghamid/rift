import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class SanitizationDemoPage extends StatelessWidget {
  const SanitizationDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Data Sanitization',
      description: 'Data sanitization and XSS prevention',
      codeExample:
          "final sanitizer = DataSanitizer();\nsanitizer.addRule(SanitizationRule.stripHtml);\nsanitizer.addRule(SanitizationRule.preventXss);\nfinal result = sanitizer.sanitizeMap(data);",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Data Sanitization Demo ===\n');

        final sanitizer = DataSanitizer();
        sanitizer.addRule(SanitizationRule.trim);
        sanitizer.addRule(SanitizationRule.stripHtml);
        sanitizer.addRule(SanitizationRule.preventXss);
        sanitizer.addRule(SanitizationRule.normalizeWhitespace);

        // XSS prevention
        buf.writeln('--- XSS Prevention ---');
        final xssInput = '  <script>alert("xss")</script>Hello  ';
        final xssResult = sanitizer.sanitizeMap({'content': xssInput});
        buf.writeln('  Input: "$xssInput"');
        buf.writeln('  Output: "${xssResult.data['content']}"');
        buf.writeln('  Was modified: ${xssResult.wasModified}');
        buf.writeln('  Applied rules: ${xssResult.appliedRules}');

        // HTML stripping
        buf.writeln('\n--- HTML Stripping ---');
        final htmlInput = '<b>Bold</b> and <i>italic</i> text';
        final htmlResult = sanitizer.sanitizeMap({'html': htmlInput});
        buf.writeln('  Input: "$htmlInput"');
        buf.writeln('  Output: "${htmlResult.data['html']}"');

        // Full sanitization pipeline
        buf.writeln('\n--- Full Pipeline ---');
        final dirtyData = {
          'name': '  <b>Idris</b>  ',
          'bio': 'Hello   World  <script>evil()</script>',
          'email': '  idris@example.com  ',
          'comment': '<a href="bad">click</a>  here   ',
        };
        final cleanResult = sanitizer.sanitizeMap(dirtyData);
        buf.writeln('  Dirty: $dirtyData');
        buf.writeln('  Clean: ${cleanResult.data}');
        buf.writeln('  Rules applied per field:');
        for (final entry in cleanResult.appliedRules.entries) {
          buf.writeln(
              '    ${entry.key}: ${entry.value.map((r) => r.name).toList()}');
        }

        // Individual rules
        buf.writeln('\n--- Individual Rules ---');
        buf.writeln(
            '  maxLength(5): "${SanitizationRule.maxLength(5).apply('abcdefgh')}"');
        buf.writeln(
            '  alphanumericOnly: "${SanitizationRule.alphanumericOnly.apply('Hello World! 123')}"');
        buf.writeln(
            '  toLowerCase: "${SanitizationRule.toLowerCase.apply('HELLO World')}"');
        buf.writeln(
            '  toUpperCase: "${SanitizationRule.toUpperCase.apply('hello world')}"');

        // Field-specific rules
        buf.writeln('\n--- Field-specific Rules ---');
        final fieldSanitizer = DataSanitizer();
        fieldSanitizer.addRule(SanitizationRule.trim);
        fieldSanitizer.addRule(SanitizationRule.forField(
            'username', SanitizationRule.alphanumericOnly));
        fieldSanitizer.addRule(
            SanitizationRule.forField('bio', SanitizationRule.maxLength(50)));
        final fieldResult = fieldSanitizer.sanitizeMap({
          'username': '  Idris G!  ',
          'bio': '  A very long biography that should be truncated  ',
          'name': '  Idris  ',
        });
        buf.writeln('  Result: ${fieldResult.data}');
        buf.writeln('  Rules: ${fieldResult.appliedRules}');

        buf.writeln('\n  Sanitizer rule count: ${sanitizer.ruleCount}');

        return buf.toString();
      },
    );
  }
}
